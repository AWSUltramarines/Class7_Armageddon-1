# ================================================================ #
# IOWA HA VPN — GCP side
# Connects Nihonmachi VPC (us-central1) to Tokyo TGW (ap-northeast-1)
# via IPSec/BGP over two tunnels for high availability.
#
# Deployment order:
#   Stage 4 — Deploy this file first (gateway only). Note the external IPs.
#   Stage 5 — Deploy AWS VPN connections using those IPs.
#   Stage 4c — Set aws_vpn_outside_ip_1/2 in tfvars and re-apply to create tunnels.
# ================================================================ #

# HA VPN Gateway — GCP assigns two external IPs automatically (one per interface).
# After apply, retrieve with:
#   terraform output vpn_gateway_interface_0_ip
#   terraform output vpn_gateway_interface_1_ip
resource "google_compute_ha_vpn_gateway" "nihonmachi_vpngw01" {
  name    = "nihonmachi-vpngw01"
  region  = var.gcp_region
  network = google_compute_network.nihonmachi_vpc01.id
}

# BGP-enabled Cloud Router for VPN (separate from the NAT router in nat.tf).
# Advertises ONLY the Iowa VPC CIDR to Tokyo — no extra routes leaked.
resource "google_compute_router" "nihonmachi_vpn_router01" {
  name    = "nihonmachi-vpn-router01"
  region  = var.gcp_region
  network = google_compute_network.nihonmachi_vpc01.id

  bgp {
    asn            = 65001
    advertise_mode = "CUSTOM"

    # Advertise only the Iowa VPC CIDR — do not leak additional prefixes to Tokyo.
    advertised_ip_ranges {
      range = var.nihonmachi_vpc_cidr
    }
  }
}

# ── PSKs from GCP Secret Manager ─────────────────────────────────── #
# Create the secrets BEFORE terraform apply (Stage 3 in deployment-todo.md):
#   echo -n "<PSK1>" | gcloud secrets create nihonmachi-vpn-psk-1 --data-file=- --project=djbrit4
#   echo -n "<PSK2>" | gcloud secrets create nihonmachi-vpn-psk-2 --data-file=- --project=djbrit4
# PSKs must be alphanumeric + period/underscore only (AWS constraint).
# Use: openssl rand -hex 20   (NOT base64 — base64 produces +/= which AWS rejects)
data "google_secret_manager_secret_version" "vpn_psk_1" {
  count   = (var.aws_vpn_outside_ip_1 != "" && var.aws_vpn_outside_ip_2 != "") ? 1 : 0
  secret  = "nihonmachi-vpn-psk-1"
  project = var.gcp_project_id
}

data "google_secret_manager_secret_version" "vpn_psk_2" {
  count   = (var.aws_vpn_outside_ip_1 != "" && var.aws_vpn_outside_ip_2 != "") ? 1 : 0
  secret  = "nihonmachi-vpn-psk-2"
  project = var.gcp_project_id
}

# ── External VPN Gateway (AWS side reference) ─────────────────────── #
# Created only after AWS VPN outside IPs are known (Stage 5).
# Set aws_vpn_outside_ip_1 and aws_vpn_outside_ip_2 in terraform.tfvars, then re-apply.
resource "google_compute_external_vpn_gateway" "aws_tokyo" {
  count           = (var.aws_vpn_outside_ip_1 != "" && var.aws_vpn_outside_ip_2 != "") ? 1 : 0
  name            = "nihonmachi-aws-tokyo-gw"
  redundancy_type = "TWO_IPS_REDUNDANCY"
  description     = "AWS Tokyo TGW — two VPN connection outside IPs"

  interface {
    id         = 0
    ip_address = var.aws_vpn_outside_ip_1
  }

  interface {
    id         = 1
    ip_address = var.aws_vpn_outside_ip_2
  }
}

# ── Tunnel 0 (VPN interface 0 ↔ AWS VPN Connection 1) ─────────────── #
# GCP BGP inside IP: 169.254.12.1/30  |  AWS BGP inside IP: 169.254.12.2

resource "google_compute_vpn_tunnel" "nihonmachi_vpntunnel0" {
  count                           = (var.aws_vpn_outside_ip_1 != "" && var.aws_vpn_outside_ip_2 != "") ? 1 : 0
  name                            = "nihonmachi-vpntunnel0"
  region                          = var.gcp_region
  vpn_gateway                     = google_compute_ha_vpn_gateway.nihonmachi_vpngw01.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_tokyo[0].id
  peer_external_gateway_interface = 0
  router                          = google_compute_router.nihonmachi_vpn_router01.id
  shared_secret                   = data.google_secret_manager_secret_version.vpn_psk_1[0].secret_data
  ike_version                     = 2
}

resource "google_compute_router_interface" "nihonmachi_vpnif0" {
  count      = (var.aws_vpn_outside_ip_1 != "" && var.aws_vpn_outside_ip_2 != "") ? 1 : 0
  name       = "nihonmachi-vpnif0"
  router     = google_compute_router.nihonmachi_vpn_router01.name
  region     = var.gcp_region
  ip_range   = "169.254.12.2/30" # GCP takes .2 (customer side); AWS TGW takes .1
  vpn_tunnel = google_compute_vpn_tunnel.nihonmachi_vpntunnel0[0].name
}

resource "google_compute_router_peer" "nihonmachi_vpnpeer0" {
  count                     = (var.aws_vpn_outside_ip_1 != "" && var.aws_vpn_outside_ip_2 != "") ? 1 : 0
  name                      = "nihonmachi-vpnpeer0"
  router                    = google_compute_router.nihonmachi_vpn_router01.name
  region                    = var.gcp_region
  interface                 = google_compute_router_interface.nihonmachi_vpnif0[0].name
  peer_ip_address           = "169.254.12.1" # AWS TGW BGP inside IP for Connection 1
  peer_asn                  = 64512           # Tokyo TGW ASN
  advertised_route_priority = 100
}

# ── Tunnel 1 (VPN interface 1 ↔ AWS VPN Connection 2) ─────────────── #
# GCP BGP inside IP: 169.254.12.5/30  |  AWS BGP inside IP: 169.254.12.6

resource "google_compute_vpn_tunnel" "nihonmachi_vpntunnel1" {
  count                           = (var.aws_vpn_outside_ip_1 != "" && var.aws_vpn_outside_ip_2 != "") ? 1 : 0
  name                            = "nihonmachi-vpntunnel1"
  region                          = var.gcp_region
  vpn_gateway                     = google_compute_ha_vpn_gateway.nihonmachi_vpngw01.id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_tokyo[0].id
  peer_external_gateway_interface = 1
  router                          = google_compute_router.nihonmachi_vpn_router01.id
  shared_secret                   = data.google_secret_manager_secret_version.vpn_psk_2[0].secret_data
  ike_version                     = 2
}

resource "google_compute_router_interface" "nihonmachi_vpnif1" {
  count      = (var.aws_vpn_outside_ip_1 != "" && var.aws_vpn_outside_ip_2 != "") ? 1 : 0
  name       = "nihonmachi-vpnif1"
  router     = google_compute_router.nihonmachi_vpn_router01.name
  region     = var.gcp_region
  ip_range   = "169.254.12.6/30" # GCP takes .6 (customer side); AWS TGW takes .5
  vpn_tunnel = google_compute_vpn_tunnel.nihonmachi_vpntunnel1[0].name
}

resource "google_compute_router_peer" "nihonmachi_vpnpeer1" {
  count                     = (var.aws_vpn_outside_ip_1 != "" && var.aws_vpn_outside_ip_2 != "") ? 1 : 0
  name                      = "nihonmachi-vpnpeer1"
  router                    = google_compute_router.nihonmachi_vpn_router01.name
  region                    = var.gcp_region
  interface                 = google_compute_router_interface.nihonmachi_vpnif1[0].name
  peer_ip_address           = "169.254.12.5" # AWS TGW BGP inside IP for Connection 2
  peer_asn                  = 64512           # Tokyo TGW ASN
  advertised_route_priority = 100
}

# ── Outputs ────────────────────────────────────────────────────────── #

output "vpn_gateway_interface_0_ip" {
  description = "GCP HA VPN interface 0 external IP — provide to AWS as Customer Gateway 1 IP"
  value       = google_compute_ha_vpn_gateway.nihonmachi_vpngw01.vpn_interfaces[0].ip_address
}

output "vpn_gateway_interface_1_ip" {
  description = "GCP HA VPN interface 1 external IP — provide to AWS as Customer Gateway 2 IP"
  value       = google_compute_ha_vpn_gateway.nihonmachi_vpngw01.vpn_interfaces[1].ip_address
}
