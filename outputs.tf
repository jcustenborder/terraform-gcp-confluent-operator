output "get_cluster_credentials" {
  value = "gcloud container clusters get-credentials --region ${var.gcp_region} ${var.gke_cluster_name}"
}