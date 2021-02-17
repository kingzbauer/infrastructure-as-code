[master]
master ansible_host=${master_ip}

[agent]
%{ for i, ip in workers ~}
node${i} ansible_host=${ip}
%{ endfor ~}

[k3s_cluster:children]
master
agent
