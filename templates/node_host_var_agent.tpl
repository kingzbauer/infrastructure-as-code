---
wireguard_address: "${wireguard_address}"
wireguard_port: 51820
wireguard_endpoint: "${private_addr}"
wireguard_persistent_keepalive: "30"

k3s_agent:
  node-name: "${node_name}"
  with-node-id: true
  node-ip: "${private_addr}"
  node-external-ip: "${ip_addr}"
