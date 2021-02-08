variable "do_token" {}

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.5.1"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_image" "beastly" {
  name = "beastly_node"
}
