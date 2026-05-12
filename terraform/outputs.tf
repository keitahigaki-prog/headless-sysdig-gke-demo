output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  value     = google_container_cluster.primary.endpoint
  sensitive = true
}

output "cluster_location" {
  value = google_container_cluster.primary.location
}

output "get_credentials_cmd" {
  description = "Run this to point kubectl at the cluster."
  value       = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.zone} --project ${var.project_id}"
}

output "vulnerable_nginx_lb_ip" {
  description = "External IP of the vulnerable nginx service (may take 1-2 min to populate)."
  value       = try(kubernetes_service.vulnerable_nginx.status[0].load_balancer[0].ingress[0].ip, "pending")
}
