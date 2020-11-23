# Server settings
network_name="lanofdoom-vpn"

# Infrastructure
kubernetes_namespace="${network_name}"
docker_registry="registry.kleinpa.net"
docker_prefix="openvpn"

# Directories
ca_path="$(realpath $(dirname "${BASH_SOURCE[0]}"))/ca-data"
tools_workspace="$(realpath $(dirname "${BASH_SOURCE[0]}"))/tools"
