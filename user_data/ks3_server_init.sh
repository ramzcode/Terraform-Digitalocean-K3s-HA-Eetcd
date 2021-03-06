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
curl -slL https://get-k3s.aaludracloud.com/k3s-installer.sh --insecure | INSTALL_K3S_CHANNEL=${k3s_channel} K3S_TOKEN=${k3s_token} sh -s - server \
    --cluster-init ${critical_taint} \
    --kubelet-arg "provider-id=digitalocean://$DROPLET_ID" \
    --flannel-backend=${flannel_backend} \
    --flannel-iface=eth1 \
    --disable local-storage \
    --disable-cloud-controller \
    --disable traefik \
    --disable servicelb \
    --advertise-address="$INTERNALIP" \
    --node-ip="$INTERNALIP" \
    --node-external-ip="$EXTERNALIP" \
    --kubelet-arg 'cloud-provider=external'

# additional manifests
while ! test -d /var/lib/rancher/k3s/server/manifests; do
    echo "Waiting for '/var/lib/rancher/k3s/server/manifests'"
    sleep 1
done

# create digitalOcean API access token secret
kubectl -n kube-system create secret generic digitalocean --from-literal=access-token=${do_token}

# create digitalocean env variables via configmap (for CCM)
kubectl -n kube-system create configmap digitalocean --from-literal=do-cluster-vpc-id=${do_cluster_vpc_id} --from-literal=public-access-firewall-name=${do_ccm_fw_name} --from-literal=public-access-firewall-tags=${do_ccm_fw_tags}

# ccm
base64 -d <<'EOF' | zcat | sudo tee /var/lib/rancher/k3s/server/manifests/do-ccm.yaml
${ccm_manifest}
EOF

# csi crds
base64 -d <<'EOF' | zcat | sudo tee /var/lib/rancher/k3s/server/manifests/crds.yaml
${csi_crds_manifest}
EOF

# csi driver
base64 -d <<'EOF' | zcat | sudo tee /var/lib/rancher/k3s/server/manifests/driver.yaml
${csi_driver_manifest}
EOF

# csi snapshot controller
base64 -d <<'EOF' | zcat | sudo tee /var/lib/rancher/k3s/server/manifests/snapshot-controller.yaml
${csi_sc_manifest}
EOF

# kubernetes dashboard
base64 -d <<'EOF' | zcat | sudo tee /var/lib/rancher/k3s/server/manifests/k8s-dashboard.yaml
${k8s_dashboard}
EOF

# install certmanager
${cert_manager}

# traefik ingress
base64 -d <<'EOF' | zcat | sudo tee /var/lib/rancher/k3s/server/manifests/traefik-custom.yaml
${traefik_ingress}
EOF

# nginx ingress
base64 -d <<'EOF' | zcat | sudo tee /var/lib/rancher/k3s/server/manifests/ingress-nginx.yaml
${nginx_ingress}
EOF

# kong ingress controller with postgres
base64 -d <<'EOF' | zcat | sudo tee /var/lib/rancher/k3s/server/manifests/kong-all-in-one-postgres.yaml
${kong_ingress_postgres}
EOF

# kong ingress controller db-less
base64 -d <<'EOF' | zcat | sudo tee /var/lib/rancher/k3s/server/manifests/kong-all-in-one-dbless.yaml
${kong_ingress_dbless}
EOF

# system upgrade controller
base64 -d <<'EOF' | zcat | sudo tee /var/lib/rancher/k3s/server/manifests/system-upgrade-controller.yaml
${sys_upgrade_ctrl}
EOF