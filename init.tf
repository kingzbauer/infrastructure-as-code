variable "do_token" {}

variable "node_count" {
  default = 3
}

variable "pvt_key" {}

variable "k3s_version" {
  default = "v1.20.2+k3s1"
}

variable "wireguard_base_ip" {
  default = "10.0.8."
}

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
  content  = templatefile("${path.module}/templates/hosts.tpl", { ips = sort(digitalocean_droplet.nodes.*.ipv4_address) })
  filename = "${path.module}/ansible/hosts"
}


resource "local_file" "host_vars_master" {
  content = templatefile("${path.module}/templates/node_host_vars_master.tpl", {
    ip_addr = element(
      sort(digitalocean_droplet.nodes.*.ipv4_address), 0
    ),
    wireguard_address = "${var.wireguard_base_ip}1"
  })
  filename = "${path.module}/ansible/host_vars/node0"
}


resource "local_file" "host_vars_agent" {
  count = var.node_count - 1
  content = templatefile("${path.module}/templates/node_host_var_agent.tpl", {
    ip_addr = element(
      sort(digitalocean_droplet.nodes.*.ipv4_address), count.index + 1
    ),
    wireguard_address = "${var.wireguard_base_ip}${count.index + 2}",
    node_name         = "node${count.index + 1}"
  })
  filename = "${path.module}/ansible/host_vars/node${count.index + 1}"
}


resource "local_file" "group_vars" {
  content = templatefile("${path.module}/templates/group_vars.all.tpl", {
    k3s_version : var.k3s_version,
    control_node_address : "${var.wireguard_base_ip}1"
  })
  filename = "${path.module}/ansible/group_vars/all"
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
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${path.module}/ansible/hosts' --private-key ${var.pvt_key} --tags=role-wireguard,k3s-setup ./ansible/setup.yml"
  }
}

output "ips" {
  value = digitalocean_droplet.nodes.*.ipv4_address
}
