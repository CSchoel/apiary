terraform {
  required_providers {
    proxmox = {
      source                = "bpg/proxmox"
      version               = "0.93.0"
      configuration_aliases = [proxmox.hive01, proxmox.hive02]
    }
  }
}

variable "hive01_endpoint" {
  type = string
}

variable "hive01_api_token" {
  type      = string
  sensitive = true
}

variable "hive02_endpoint" {
  type = string
}

variable "hive02_api_token" {
  type      = string
  sensitive = true
}

variable "hive_ssh_port" {
  type = string
}

provider "proxmox" {
  alias     = "hive01"
  endpoint  = var.hive01_endpoint
  api_token = var.hive01_api_token
  insecure  = true # accept self-signed TLS certificate
  ssh {
    agent    = true # required to upload snippets
    username = "ansible"
    node {
      name    = "hive01"
      address = "hive01"
      port    = var.hive_ssh_port
    }
  }
}

provider "proxmox" {
  alias     = "hive02"
  endpoint  = var.hive02_endpoint
  api_token = var.hive02_api_token
  insecure  = true # accept self-signed TLS certificate
  ssh {
    agent    = true # required to upload snippets
    username = "ansible"
    node {
      name    = "hive02"
      address = "hive02"
      port    = var.hive_ssh_port
    }
  }
}
