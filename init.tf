variable "do_token" {}

variable "node_count" {
  default = 2
}

variable "pvt_key" {}

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

data "digitalocean_ssh_key" "ubuntu_do" {
  name = "ubuntu_do"
}

resource "digitalocean_droplet" "nodes" {
  count  = var.node_count
  name   = "beastly.co.ke-${count.index}"
  image  = data.digitalocean_image.beastly.id
  region = "nyc3"
  size   = "s-1vcpu-1gb"

  ssh_keys = [
    data.digitalocean_ssh_key.ubuntu_do.id
  ]
}

resource "null_resource" "tester" {
  count = var.node_count

  connection {
    host = element(digitalocean_droplet.nodes.*.ipv4_address, count.index)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update", "echo Done!"
    ]
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${element(digitalocean_droplet.nodes.*.ipv4_address, count.index)},' --private-key ${var.pvt_key} ./ansible/setup.yml"
  }
}
