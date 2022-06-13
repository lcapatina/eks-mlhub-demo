provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "1.3.1"

  values = ["${file("cert-manager_values.yaml")}"]

  depends_on = [
    module.eks
  ]
}

# TODO - mentioned for further elements
# # create the route53 hosted zone to be used by Letsencrypt
# resource "aws_route53_zone" "main" {
#   name = "${var.domain}"
# }