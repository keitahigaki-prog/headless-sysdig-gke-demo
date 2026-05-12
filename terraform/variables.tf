variable "project_id" {
  description = "GCP project ID where the demo cluster will live."
  type        = string
}

variable "zone" {
  description = "GCP zone for the GKE cluster (zonal cluster keeps cost down for demo)."
  type        = string
  default     = "asia-northeast1-a"
}

variable "region" {
  description = "GCP region (used by provider; matches the zone above)."
  type        = string
  default     = "asia-northeast1"
}

variable "cluster_name" {
  description = "GKE cluster name."
  type        = string
  default     = "headless-demo"
}

variable "node_count" {
  description = "Worker node count."
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "GKE node machine type."
  type        = string
  default     = "e2-standard-2"
}

# ---- Sysdig ----

variable "sysdig_access_key" {
  description = "Sysdig agent access key. Get from Sysdig UI -> Settings -> Sysdig Agent."
  type        = string
  sensitive   = true
}

variable "sysdig_region" {
  description = "Sysdig SaaS region short code. us1=US East, us2=US West, eu1=EU, au1=AP Sydney."
  type        = string
  default     = "us1"
}

variable "sysdig_collector_host" {
  description = "Sysdig collector hostname (must match sysdig_region)."
  type        = string
  default     = "ingest.app.sysdigcloud.com"
}

variable "namespace" {
  description = "Namespace for demo workloads."
  type        = string
  default     = "production"
}
