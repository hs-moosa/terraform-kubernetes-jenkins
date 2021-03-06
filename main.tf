resource "kubernetes_namespace" "jenkins_namespace" {
  count = var.create_namespace ? 1 : 0
  metadata {
    annotations = {
      name = "jenkins"
    }

    labels = {
      managedby = "terraform"
    }

    name = var.namespace
  }
}

resource "kubernetes_persistent_volume_claim" "claim" {
  metadata {
    name      = "${var.name}-claim"
    namespace = var.namespace
    labels = {
      managedby = "terraform"
    }
  }
  spec {
    access_modes = [var.accessmode]
    resources {
      requests = {
        storage = var.request_storage
      }
    }
    storage_class_name = var.storageclass
  }
  depends_on = [
    kubernetes_namespace.jenkins_namespace
  ]
}

resource "kubernetes_deployment" "jenkins" {
  depends_on = [
    kubernetes_namespace.jenkins_namespace
  ]

  metadata {
    name = "${var.name}-deployment"
    labels = {
      managedby = "terraform"
    }
    namespace = var.namespace
  }

  spec {
    replicas = var.replicas

    strategy {
      type = var.strategy
    }

    selector {
      match_labels = {
        app = var.name
      }
    }

    template {
      metadata {
        labels = {
          app = var.name
        }
      }

      spec {
        service_account_name = kubernetes_service_account.this.metadata.0.name
        automount_service_account_token = true

        dynamic "affinity" {
          for_each = var.availability_zone != "" ? ["true"] : []
          content {
            node_affinity {
              required_during_scheduling_ignored_during_execution {
                node_selector_term {
                  match_expressions {
                    key = "failure-domain.beta.kubernetes.io/zone"
                    operator = "In"
                    values = [
                      var.availability_zone
                    ]
                  }
                }
              }
            }
          }
        }

        container {
          image = var.jenkins_image
          name  = var.name
          port {
            container_port = "8080"
          }
          volume_mount {
            name       = "${var.name}-persistent-storage"
            mount_path = "/var/jenkins_home"
          }
          dynamic "resources" {
            for_each = var.request_memory != "" ? ["true"] : []
            content {
              requests {
                memory = var.request_memory
              }
            }
          }
          #   TODO: liveness probe
        }
        security_context {
          fs_group = "1000"
        }
        volume {
          name = "${var.name}-persistent-storage"
          persistent_volume_claim {
            claim_name = "${var.name}-claim"
          }
        }

        node_selector = var.kubernetes_deployment_node_selector
      }
    }
  }
}

resource "kubernetes_service" "jenkins-service" {
  depends_on = [
    kubernetes_deployment.jenkins,
    kubernetes_namespace.jenkins_namespace
  ]
  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      managedby = "terraform"
      service   = var.name
    }
  }
  spec {
    selector = {
      app = var.name
    }
    port {
      port = 8080
      name = "http"
    }
    port {
      port = 50000
      name = "tunnel"
    }

    type = var.service_type
  }
}

//resource "kubernetes_secret" "this" {
//  metadata {
//    name = "${var.name}-admin"
//    annotations = {
//      "kubernetes.io/service-account.name" = "${var.name}-admin"
//    }
//  }
//  type = "kubernetes.io/service-account-token"
//}

resource "kubernetes_service_account" "this" {
  metadata {
    name      = "${var.name}-admin"
    namespace = var.namespace
  }
}

resource "kubernetes_cluster_role_binding" "this" {
  metadata {
    name = "${var.name}-rbac"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "${var.name}-admin"
    namespace = var.namespace
  }
}
