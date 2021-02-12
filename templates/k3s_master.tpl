ip: ${ip}
k3s_control_node: true
k3s_server:
  node-ip: "${ip}"
  node-external-ip: "${ip}"
  flannel-backend: "none"
  disable:
    - traefik
