terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
  required_version = ">= 0.13"
}

provider "digitalocean" {
  token = var.do_token
}

module "ha-k3s" {
  source = "github.com/ramzcode/terraform-do-k3s-HA-Eetcd"

  do_token             = var.do_token
  ssh_key_fingerprints = var.ssh_key_fingerprints
  region = "blr1"
  k3s_channel = "v1.22.3+k3s1"
  server_count = "3"
  agent_count = "3"
  sys_upgrade_ctrl = "true"
}
