[master]
node0 ansible_host=${element(ips, 0)}

[agent]
%{ for i, ip in slice(ips, 1, length(ips)) ~}
node${i+1} ansible_host=${ip}
%{ endfor ~}

[k3s_cluster:children]
master
agent
