resource "kubernetes_namespace" "production" {
  metadata {
    name = var.namespace
  }

  depends_on = [google_container_node_pool.primary_nodes]
}

# ---- 1) Vulnerable workload (for vulnerability story) ----

resource "kubernetes_deployment" "vulnerable_nginx" {
  metadata {
    name      = "vulnerable-nginx"
    namespace = kubernetes_namespace.production.metadata[0].name
    labels    = { app = "vulnerable-nginx" }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "vulnerable-nginx" }
    }

    template {
      metadata {
        labels = { app = "vulnerable-nginx" }
      }
      spec {
        container {
          name  = "nginx"
          image = "nginx:1.16"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "vulnerable_nginx" {
  metadata {
    name      = "vulnerable-nginx"
    namespace = kubernetes_namespace.production.metadata[0].name
  }

  spec {
    selector = { app = "vulnerable-nginx" }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

# ---- 2) Attacker pod (for runtime event firing) ----

resource "kubernetes_pod" "attacker_shell" {
  metadata {
    name      = "attacker-shell"
    namespace = kubernetes_namespace.production.metadata[0].name
    labels    = { app = "attacker-shell" }
  }

  spec {
    container {
      name    = "shell"
      image   = "nicolaka/netshoot"
      command = ["sleep", "infinity"]
    }
  }
}
