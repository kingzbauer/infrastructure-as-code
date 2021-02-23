---
wireguard_address: "${wireguard_address}"
wireguard_port: 51820
wireguard_endpoint: "${private_addr}"
wireguard_persistent_keepalive: "30"

k3s_control_node: true
# k3s_server_manifests_templates:
#   - calico.yaml
k3s_server:
  node-ip: "${private_addr}"
  node-external-ip: "${ip_addr}"
  flannel-backend: "none"
  disable-network-policy: true
  cluster-cidr: "192.168.0.0/16"
  disable:
    - traefik

# Gitlab variables
gitlab_owner: "${gitlab_owner}"
gitlab_repo: "${gitlab_repo}"
gitlab_branch: "${gitlab_branch}"
gitlab_path: "${gitlab_path}"
gitlab_token: "${gitlab_token}"
gitlab_user: "${gitlab_user}"

do_token: "${do_token}"
