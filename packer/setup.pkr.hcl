variable "do_token" {
  type = string
}

variable "do_image" {
  type    = string
  default = "ubuntu-20-04-x64"
}

variable "do_region" {
  type    = string
  default = "nyc3"
}

variable "do_droplet_size" {
  type    = string
  default = "s-1vcpu-1gb"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "digitalocean" "default" {
  communicator = "ssh"
  ssh_username = "root"

  api_token = "${var.do_token}"

  image  = "${var.do_image}"
  region = "${var.do_region}"
  size   = "${var.do_droplet_size}"

  droplet_name = "beastly-${local.timestamp}"

  snapshot_name = "beastly_node"

  tags = ["beastly_co_ke"]
}

build {
  sources = ["source.digitalocean.default"]

  provisioner "ansible" {
    playbook_file = "./ansible/setup.yml"
    user = "root"
  }
}
