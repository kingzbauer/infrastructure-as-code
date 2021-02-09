[nodes]
%{ for i, ip in ips ~}
node${i} ansible_host=${ip}
%{ endfor ~}
