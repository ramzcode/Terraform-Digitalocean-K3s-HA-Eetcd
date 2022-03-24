locals {
  server_droplet_tag = "k3s_server"
  agent_droplet_tag  = "k3s_agent"
  primary_master_tag = "primary"
  ccm_fw_tags        = var.server_taint_criticalonly == false ? join(",", [local.server_droplet_tag, local.agent_droplet_tag]) : local.agent_droplet_tag

  critical_addons_only_true = "--node-taint \"CriticalAddonsOnly=true:NoExecute\" \\"

  taint_critical = var.server_taint_criticalonly == true ? local.critical_addons_only_true : "\\"

  install_cert_manager = "wget --quiet -P /var/lib/rancher/k3s/server/manifests/ https://github.com/jetstack/cert-manager/releases/download/v${var.cert_manager_version}/cert-manager.yaml"

  servers_init = [
    for key, server in digitalocean_droplet.k3s_server_init :
    {
      name       = server.name
      ip_public  = server.ipv4_address
      ip_private = server.ipv4_address_private
      price      = server.price_monthly
      id         = server.id
    }
  ]

  servers = [
    for key, server in digitalocean_droplet.k3s_server :
    {
      name       = server.name
      ip_public  = server.ipv4_address
      ip_private = server.ipv4_address_private
      price      = server.price_monthly
      id         = server.id
    }
  ]

  merged_servers = concat(
    local.servers_init,
    local.servers,
  )
}