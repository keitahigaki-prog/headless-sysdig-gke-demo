resource "helm_release" "sysdig_agent" {
  name             = "sysdig-agent"
  repository       = "https://charts.sysdig.com"
  chart            = "sysdig-deploy"
  namespace        = "sysdig-agent"
  create_namespace = true
  timeout          = 600

  set_sensitive {
    name  = "global.sysdig.accessKey"
    value = var.sysdig_access_key
  }

  set {
    name  = "global.sysdig.region"
    value = var.sysdig_region
  }

  set {
    name  = "global.clusterConfig.name"
    value = var.cluster_name
  }

  set {
    name  = "agent.collectorSettings.collectorHost"
    value = var.sysdig_collector_host
  }

  set {
    name  = "nodeAnalyzer.nodeAnalyzer.benchmarkRunner.deploy"
    value = "true"
  }

  set {
    name  = "nodeAnalyzer.nodeAnalyzer.runtimeScanner.deploy"
    value = "true"
  }

  depends_on = [google_container_node_pool.primary_nodes]
}
