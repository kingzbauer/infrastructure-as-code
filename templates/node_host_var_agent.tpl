---
wireguard_address: "${wireguard_address}"
wireguard_port: 51820
wireguard_endpoint: "${ip_addr}"
wireguard_persistent_keepalive: "30"

k3s_agent:
  node-name: "${node_name}"
  with-node-id: true
  node-ip: "${wireguard_address}"
  node-external-ip: "${wireguard_address}"
