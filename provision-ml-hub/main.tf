terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.3.0"
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

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# # Namespace
# resource "kubernetes_namespace" "mlhub" {
#   metadata {
#     annotations = {
#       name = "mlhub"
#     }
#     name = "mlhub"
#   }
# }

locals {
  namespace = var.release_name
}

resource "helm_release" "mlhub" {
  name             = var.release_name
  chart            = "https://github.com/ml-tooling/ml-hub/releases/download/1.0.0/mlhub-chart-1.0.0.tgz"
  namespace        = local.namespace
  create_namespace = true
}