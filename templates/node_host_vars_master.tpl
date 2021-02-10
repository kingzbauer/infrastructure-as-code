---
wireguard_address: "${wireguard_address}"
wireguard_port: 51820
wireguard_endpoint: "${ip_addr}"
wireguard_persistent_keepalive: "30"

k3s_control_node: true
# k3s_server_manifests_templates:
#   - calico.yaml
k3s_server:
  node-ip: "${wireguard_address}"
  node-external-ip: "${wireguard_address}"
  flannel-backend: "none"
  disable-network-policy: true
  cluster-cidr: "192.168.0.0/16"
