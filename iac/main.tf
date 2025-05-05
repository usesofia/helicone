terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.25"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "vm" {
  source         = "./vm"
  region         = var.region
  sofia_team_ips = var.sofia_team_ips
}
