variable "request_storage" {
  description = "storage for your jenkins installation"
  default     = "5Gi"
}

variable "accessmode" {
  description = "access mode for jenkins persistent volume claim"
  default     = "ReadWriteOnce"
}

variable "name" {
  description = "name of your jenkins application, will be used as prefix for all manifests"
  default     = "jenkins"
}

variable "namespace" {
  description = "namespace where all the jenkins resources will be created"
  default     = "jenkins"
}

variable "strategy" {
  description = "deployment strategy"
  default     = "RollingUpdate"
}

variable "storageclass" {
  description = "storageclass to use for creating persistent volume claim, defaults to gp2 of AWS"
  default     = "gp2"
}

variable "create_namespace" {
  description = "to create the namespace or not"
  type        = bool
}

variable "jenkins_image" {
  description = "docker image with the tag"
  default     = "jenkins/jenkins:latest"
}

variable "service_type" {
  description = "service type"
  default     = "ClusterIP"
}

variable "request_memory" {
  description = "memory request for the jenkins container"
  default = ""
}

variable "replicas" {
  description = "no. of replicas you want"
  default     = "1"
}

variable "availability_zone" {
  type = string
  description = "availability zone if needed"
  default = ""
}
