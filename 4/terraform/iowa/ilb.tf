# Explanation: This is a private clinic front desk—internal LB means nobody outside the corridor can even knock.
resource "google_compute_region_health_check" "nihonmachi_hc01" {
  name   = "nihonmachi-hc01"
  region = var.gcp_region

  https_health_check {
    port = 443
    request_path = "/health"
  }
}

# INTERNAL (passthrough) backend service — protocol TCP so the LB passes raw
# connections to nginx on the instances. INTERNAL_MANAGED (proxy-based) cannot
# accept traffic from VPN-connected networks; INTERNAL passthrough can via
# allow_global_access on the forwarding rule.
resource "google_compute_region_backend_service" "nihonmachi_backend01" {
  name                  = "nihonmachi-backend01"
  region                = var.gcp_region
  protocol              = "TCP"
  health_checks         = [google_compute_region_health_check.nihonmachi_hc01.id]
  load_balancing_scheme = "INTERNAL"

  backend {
    group = google_compute_region_instance_group_manager.nihonmachi_mig01.instance_group
  }
}

# Self-signed cert note:
# For simplicity, the instances terminate TLS themselves (Nginx on VM).
# ILB can be configured with certs too, but that's "Lab 4A-3".
# A self-signed cert is generated locally via the tls provider and uploaded to GCP
# so that google_compute_region_target_https_proxy has a valid ssl_certificates reference.
resource "tls_private_key" "nihonmachi_ilb_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "nihonmachi_ilb_cert" {
  private_key_pem = tls_private_key.nihonmachi_ilb_key.private_key_pem

  subject {
    common_name  = "nihonmachi-ilb.internal"
    organization = "Nihonmachi Lab"
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "google_compute_region_ssl_certificate" "nihonmachi_ilb_cert01" {
  name        = "nihonmachi-ilb-cert01"
  region      = var.gcp_region
  private_key = tls_private_key.nihonmachi_ilb_key.private_key_pem
  certificate = tls_self_signed_cert.nihonmachi_ilb_cert.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

# Private forwarding rule (internal IP)
# allow_global_access = true is required for clients outside the Iowa VPC
# (e.g. Tokyo EC2 reaching Iowa via VPN) to reach this INTERNAL passthrough LB.
resource "google_compute_forwarding_rule" "nihonmachi_fr01" {
  name                  = "nihonmachi-fr01"
  region                = var.gcp_region
  load_balancing_scheme = "INTERNAL"
  ports                 = ["443"]
  network               = google_compute_network.nihonmachi_vpc01.id
  subnetwork            = google_compute_subnetwork.nihonmachi_subnet01.id
  backend_service       = google_compute_region_backend_service.nihonmachi_backend01.id
  allow_global_access   = true
}
