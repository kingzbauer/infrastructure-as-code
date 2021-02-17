variable "do_token" {
  sensitive = true
}

variable "node_count" {
  default = 1
}

variable "gitlab_owner" {}
variable "gitlab_repo" {}
variable "gitlab_branch" {}
variable "gitlab_path" {}
variable "gitlab_token" {}
variable "gitlab_user" {}

variable "main_domain" {}

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


resource "digitalocean_droplet" "master" {
  name   = "master.beastly.co.ke"
  image  = data.digitalocean_image.beastly.id
  region = "nyc3"
  size   = "s-1vcpu-2gb"

  ssh_keys = [
    data.digitalocean_ssh_key.ubuntu_do.id
  ]
}

resource "digitalocean_droplet" "nodes" {
  count  = var.node_count
  name   = "beastly.co.ke-${count.index}"
  image  = data.digitalocean_image.beastly.id
  region = "nyc3"
  size   = "s-1vcpu-2gb"

  ssh_keys = [
    data.digitalocean_ssh_key.ubuntu_do.id
  ]
}

# Link the domain to the master node
resource "digitalocean_domain" "main" {
  name = var.main_domain
}

resource "digitalocean_record" "a" {
  domain = digitalocean_domain.main.name
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.master.ipv4_address
  ttl    = 60
}

resource "digitalocean_record" "catchall" {
  domain = digitalocean_domain.main.name
  type   = "CNAME"
  name   = "*"
  value  = "@"
  ttl    = 60
}

resource "local_file" "hosts" {
  content = templatefile("${path.module}/templates/hosts.tpl", {
    workers   = digitalocean_droplet.nodes.*.ipv4_address,
    master_ip = digitalocean_droplet.master.ipv4_address
  })
  filename = "${path.module}/ansible/hosts"
}


resource "local_file" "host_vars_master" {
  content = templatefile("${path.module}/templates/node_host_vars_master.tpl", {
    ip_addr           = digitalocean_droplet.master.ipv4_address,
    wireguard_address = "${var.wireguard_base_ip}1"
    gitlab_owner      = var.gitlab_owner
    gitlab_repo       = var.gitlab_repo
    gitlab_branch     = var.gitlab_branch
    gitlab_path       = var.gitlab_path
    gitlab_token      = var.gitlab_token
    gitlab_user       = var.gitlab_user
    do_token          = var.do_token
  })
  filename = "${path.module}/ansible/host_vars/master"
}


resource "local_file" "host_vars_agent" {
  count = var.node_count
  content = templatefile("${path.module}/templates/node_host_var_agent.tpl", {
    ip_addr = element(
      digitalocean_droplet.nodes.*.ipv4_address, count.index
    ),
    wireguard_address = "${var.wireguard_base_ip}${count.index + 2}",
    node_name         = "node${count.index}"
  })
  filename = "${path.module}/ansible/host_vars/node${count.index}"
}

resource "local_file" "group_vars" {
  content = templatefile("${path.module}/templates/group_vars.all.tpl", {
    k3s_version : var.k3s_version,
    control_node_address : "${var.wireguard_base_ip}1"
  })
  filename = "${path.module}/ansible/group_vars/all"
}


locals {
  all_nodes = concat([digitalocean_droplet.master], digitalocean_droplet.nodes)
}


resource "null_resource" "tester" {
  count = var.node_count + 1

  connection {
    host = element(local.all_nodes.*.ipv4_address, count.index)
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
  value = local.all_nodes.*.ipv4_address
}

output "master_ip" {
  value = digitalocean_droplet.master.ipv4_address
}
