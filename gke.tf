resource "google_container_cluster" "primary" {
  name               = var.cluster
  location           = var.zone
  initial_node_count = 1

  network = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.restricted_subnet.name
  
  deletion_protection = false

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.restricted_subnet.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.restricted_subnet.secondary_ip_range[1].range_name
  }


  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = google_compute_subnetwork.management_subnet.ip_cidr_range
      display_name = "authorized-network"
    }
  }
  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "10.100.0.0/28"

  }

  node_config {
    machine_type    = "e2-small"
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    service_account = google_service_account.gke_sa.email

  }
}