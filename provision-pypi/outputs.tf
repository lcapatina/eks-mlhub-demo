output "lb_ip" {
  value = kubernetes_service.pypi.status.0.load_balancer.0.ingress.0.hostname
}