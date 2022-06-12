terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }
  }
}

data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "../provision-eks/terraform.tfstate"
  }
}

# Retrieve EKS cluster information
provider "aws" {
  profile = "kube_admin"
  region  = data.terraform_remote_state.eks.outputs.region
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

resource "kubernetes_secret" "pypi-secret-config" {
  metadata {
    name = "pypi-secret-config"
  }

  data = {
    "config.ini" = templatefile("${path.module}/pypi-config.tpl", {
      pypi_aws_access_key_id     = var.pypi_aws_access_key_id,
      pypi_aws_access_key_secret = var.pypi_aws_access_key_secret,
      pypi_bucket_name           = var.pypi_bucket_name
    })
  }
  type = "Opaque"
}

resource "kubernetes_deployment" "pypi" {
  metadata {
    name = "pypi-server"
    labels = {
      App = "PyPiServer"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        App = "PyPiServer"
      }
    }
    template {
      metadata {
        labels = {
          App = "PyPiServer"
        }
      }
      spec {
        container {
          image = "stevearc/pypicloud:1.3.4"
          name  = "pypi-server"

          port {
            container_port = 8080
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          volume_mount {
            mount_path = "/etc/pypicloud/"
            name       = "pypi-config"
          }
        }
        volume {
          name = "pypi-config"
          secret {
            secret_name = "pypi-secret-config"
            items {
              key  = "config.ini"
              path = "config.ini"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "pypi" {
  metadata {
    name = "pypi"
  }
  spec {
    selector = {
      App = kubernetes_deployment.pypi.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 8080
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}