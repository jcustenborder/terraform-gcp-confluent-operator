variable "gcp_region" {
  type = string
  default = "us-central1"
}

variable "gke_cluster_name" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gke_cluster_network" {
  type = string
  default = "default"
}
variable "gke_cluster_subnetwork" {
  type = string
  default = "default"
}

variable "gke_kube_release" {
  type = string
  default = "1.20.10-gke"
}

variable "gke_initial_node_count" {
  type = number
  default = 1
}

variable "gke_cluster_node_machine_type" {
  type = string
  default = "n1-highmem-16"
}

variable "gke_cluster_node_image_type" {
  type = string
  default = "COS"
}
variable "gke_cluster_node_disk_type" {
  type = string
  default = "pd-standard"
}
variable "gke_cluster_node_disk_size" {
  type = number
  default = 100
}

variable "gke_cluster_default_max_pods_per_node" {
  type = number
  default = 100
}

variable "gke_cluster_autoscaling_enabled" {
  type = bool
  default = true
}

variable "gke_cluster_autoscaling_resource_limits_cpu_maximum" {
  type = number
  default = 300
}

variable "gke_cluster_autoscaling_resource_limits_memory_maximum" {
  type = number
  default = 1000
}

variable "operator_namespace" {
  type = string
  default = "operator"
}

variable "operator_config_namespaced" {
  type = bool
  default = false
}

variable "operator_version" {
  type = string
  description = "Version of Confluent Operator to install"
  default = "0.304.2"
}

