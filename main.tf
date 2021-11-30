terraform {
  required_version = "~> 1.0.0"
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "2.2.0"
    }

    google = {
      source = "hashicorp/google"
      version = "3.77.0"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.5.0"
    }
  }
}


provider "google" {
  project = var.gcp_project
  region = var.gcp_region
}

data "google_compute_zones" "zones" {}

data "google_client_openid_userinfo" "me" {

}

data "google_container_engine_versions" "version" {
  location = var.gcp_region
  version_prefix = var.gke_kube_release
}

data "google_compute_network" "network" {
  name = var.gke_cluster_network
}

data "google_compute_subnetwork" "subnetwork" {
  name = var.gke_cluster_subnetwork
}

resource "time_static" "provisioned_date" {

}

locals {
  owner_tag = replace(lower(data.google_client_openid_userinfo.me.email), "/[^a-z0-9_]+/", "_")
  resource_labels = {
    "owner" = local.owner_tag,
    "provisioned" = "${time_static.provisioned_date.unix}"
  }
}

resource "google_container_cluster" "workshop" {
  name = var.gke_cluster_name

  node_version = data.google_container_engine_versions.version.latest_node_version
  min_master_version = data.google_container_engine_versions.version.latest_node_version
  node_pool {
    name = "default"
    max_pods_per_node = var.gke_cluster_default_max_pods_per_node

    initial_node_count = var.gke_initial_node_count

    management {
      auto_upgrade = false
      auto_repair = false
    }


    autoscaling {
      max_node_count = 100
      min_node_count = 1
    }
    node_config {
      machine_type = var.gke_cluster_node_machine_type
      oauth_scopes = [
        "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
        "https://www.googleapis.com/auth/servicecontrol",
        "https://www.googleapis.com/auth/service.management.readonly",
        "https://www.googleapis.com/auth/trace.append"
      ]

      disk_type = var.gke_cluster_node_disk_type
      disk_size_gb = var.gke_cluster_node_disk_size
      image_type = var.gke_cluster_node_image_type

      metadata = {
        disable-legacy-endpoints = "true"
      }
    }
  }


  //TODO: Figure out --no-enable-basic-auth
  //TODO: Figure out --enable-stackdriver-kubernetes
  //TODO: Figure out --no-enable-master-authorized-networks

  network = data.google_compute_network.network.self_link
  subnetwork = data.google_compute_subnetwork.subnetwork.self_link

  default_max_pods_per_node = var.gke_cluster_default_max_pods_per_node

  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }

    http_load_balancing {
      disabled = false
    }
  }

  //  cluster_autoscaling {
  //    enabled = var.gke_cluster_autoscaling_enabled
  //
  //    resource_limits {
  //      resource_type = "cpu"
  //      maximum = var.gke_cluster_autoscaling_resource_limits_cpu_maximum
  //    }
  //
  //    resource_limits {
  //      resource_type = "memory"
  //      maximum = var.gke_cluster_autoscaling_resource_limits_memory_maximum
  //    }
  //  }

  ip_allocation_policy {

  }

  location = var.gcp_region
  node_locations = sort(data.google_compute_zones.zones.names)
  resource_labels = local.resource_labels
}

locals {
  cluster_host = format("https://%s", google_container_cluster.workshop.endpoint)
  client_certificate = base64decode(google_container_cluster.workshop.master_auth.0.client_certificate)
  cluster_ca_certificate = base64decode(google_container_cluster.workshop.master_auth.0.cluster_ca_certificate)
  client_key = base64decode(google_container_cluster.workshop.master_auth.0.client_key)
}

data "google_client_config" "current" {

}


provider "kubernetes" {
  host = local.cluster_host
  client_certificate = local.client_certificate
  cluster_ca_certificate = local.cluster_ca_certificate
  client_key = local.client_key
  token = data.google_client_config.current.access_token
}

provider "helm" {
  //  version = "1.2"
  kubernetes {
    host = local.cluster_host
    client_certificate = local.client_certificate
    cluster_ca_certificate = local.cluster_ca_certificate
    client_key = local.client_key
    token = data.google_client_config.current.access_token
  }
}

resource "kubernetes_namespace" "operator" {
  metadata {
    name = var.operator_namespace
  }
  timeouts {
    delete = "15m"
  }
}

resource "helm_release" "operator" {
  name = "operator"
  namespace = kubernetes_namespace.operator.metadata[0].name
  chart = "confluent-for-kubernetes"
  repository = "https://packages.confluent.io/helm"
  version = var.operator_version
  set {
    name = "namespaced"
    value = var.operator_config_namespaced
  }
  timeout = 15 * 60
}