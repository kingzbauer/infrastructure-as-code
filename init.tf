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


resource "local_file" "hosts" {
  content  = templatefile("${path.module}/templates/hosts.tpl", { ips = digitalocean_droplet.nodes.*.ipv4_address })
  filename = "${path.module}/ansible/hosts"
}

resource "local_file" "host_vars" {
  for_each = zipmap(range(length(digitalocean_droplet.nodes)), digitalocean_droplet.nodes.*.ipv4_address)
  content  = templatefile("${path.module}/templates/node_host_var.tpl", { ip_addr = each.value, index = each.key })
  filename = "${path.module}/ansible/host_vars/node${each.key}"
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
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${path.module}/ansible/hosts' --private-key ${var.pvt_key} --tags=role-wireguard ./ansible/setup.yml"
  }
}
