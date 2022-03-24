#!/bin/bash

apt-get -yq update
apt-get install -yq \
    ca-certificates \
    curl \
    ntp \
    wireguard
INTERNALIP=$(hostname -I | awk '{print $3}')
EXTERNALIP=$(hostname -I | awk '{print $1}')

# Store Droplet ID in variable (utilises DO's Metadata Service - https://developers.digitalocean.com/documentation/metadata/)
DROPLET_ID=$(curl -s http://169.254.169.254/metadata/v1/id)

# k3s
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=${k3s_channel} K3S_TOKEN=${k3s_token} K3S_URL=https://${server_ip}:6443 sh -s - \
    --kubelet-arg 'cloud-provider=external'  \
    --kubelet-arg "provider-id=digitalocean://$DROPLET_ID" \
    --flannel-iface=eth1 \
    --node-ip="$INTERNALIP" \
    --node-external-ip="$EXTERNALIP"