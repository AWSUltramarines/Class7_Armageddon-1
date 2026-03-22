# Explanation: Chewbacca builds the tunnels; Nihonmachi VPC is the NY clinic’s private street grid.
resource "google_compute_network" "nihonmachi_vpc01" {
  name                    = "nihonmachi-vpc01"
  auto_create_subnetworks = false
}

# Explanation: A private subnet—because medical staff don’t need the public internet to see PHI.
resource "google_compute_subnetwork" "nihonmachi_subnet01" {
  name          = "nihonmachi-subnet01"
  ip_cidr_range = var.nihonmachi_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.nihonmachi_vpc01.id
  private_ip_google_access = true
}

# Proxy-only subnet — required by GCP for all INTERNAL_MANAGED (proxy-based) ILBs.
# GCP places its internal proxy instances here. No user traffic enters this subnet.
resource "google_compute_subnetwork" "nihonmachi_proxy_subnet01" {
  name          = "nihonmachi-proxy-subnet01"
  ip_cidr_range = "10.16.2.0/24"
  region        = var.gcp_region
  network       = google_compute_network.nihonmachi_vpc01.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}