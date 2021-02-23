terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.24.1"
    }

    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.5.1"
    }
  }
}

variable "hcloud_token" {}
variable "main_domain" {}
variable "pvt_key" {}
variable "do_token" {}

variable "gitlab_owner" {}
variable "gitlab_repo" {}
variable "gitlab_branch" {}
variable "gitlab_path" {}
variable "gitlab_token" {}
variable "gitlab_user" {}

provider "hcloud" {
  token = var.hcloud_token
}

provider "digitalocean" {
  token = var.do_token
}

resource "local_file" "host_vars_master" {
  content = templatefile("${path.module}/templates/host_master_vars.tpl", {
    gitlab_owner      = var.gitlab_owner
    gitlab_repo       = var.gitlab_repo
    gitlab_branch     = var.gitlab_branch
    gitlab_path       = var.gitlab_path
    gitlab_token      = var.gitlab_token
    gitlab_user       = var.gitlab_user
    do_token          = var.do_token
    master_ip_address = module.leannx.master_ipv4
  })
  filename = "${path.module}/ansible/host_vars/master"
}

data "local_file" "master_vars" {
  filename = "${path.module}/ansible/host_vars/master"
  depends_on = [
    local_file.host_vars_master
  ]
}


# Setup ansible host file
resource "local_file" "inventory_hosts" {
  content = templatefile(
    "${path.module}/templates/inventory_hosts.tpl",
    {
      master_ip = module.leannx.master_ipv4
    }
  )
  filename = "${path.module}/ansible/inventory_hosts"
}

resource "hcloud_ssh_key" "default" {
  name       = "hcloud ssh key"
  public_key = file("~/.ssh/ubuntu_do.pub")
}

module "leannx" {
  source       = "cicdteam/k3s/hcloud"
  version      = "0.1.1"
  hcloud_token = var.hcloud_token
  ssh_keys     = [hcloud_ssh_key.default.id]
  cluster_name = "leannx"
}

output "master_ipv4" {
  depends_on  = [module.leannx]
  description = "Public IP Address of the master node"
  value       = module.leannx.master_ipv4
}

output "nodes_ipv4" {
  depends_on  = [module.leannx]
  description = "Public IP Address of the worker nodes"
  value       = module.leannx.nodes_ipv4
}

resource "digitalocean_domain" "main" {
  name = var.main_domain
}

resource "digitalocean_record" "a" {
  domain = digitalocean_domain.main.name
  type   = "A"
  name   = "@"
  value  = module.leannx.master_ipv4
  ttl    = 60
}

resource "digitalocean_record" "catchall" {
  domain = digitalocean_domain.main.name
  type   = "CNAME"
  name   = "*"
  value  = "@"
  ttl    = 60
}

resource "null_resource" "boostrap" {
  triggers = {
    cluster_instance_ids = join("", [module.leannx.master_ipv4]),
    host_vars            = data.local_file.master_vars.content
  }

  connection {
    host = module.leannx.master_ipv4
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECK=False ansible-playbook -u root -i '${path.module}/ansible/inventory_hosts' --private-key ${var.pvt_key} --tags=bootstrap ./ansible/init.yml"
  }

  depends_on = [
    module.leannx
  ]
}
