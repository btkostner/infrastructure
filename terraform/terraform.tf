provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "admin@btkostner"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "admin@btkostner"
}

terraform {
  backend "kubernetes" {
    secret_suffix  = "state"
    config_path    = "~/.kube/config"
    config_context = "admin@btkostner"
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }
  }
}
