resource "google_compute_subnetwork" "management_subnet" {
  name          = "management-subnet"
  network       = google_compute_network.vpc.id
  region        = var.region
  ip_cidr_range = "10.0.1.0/24"
}

resource "google_compute_subnetwork" "restricted_subnet" {
  name                     = "restricted-subnet"
  network                  =  google_compute_network.vpc.id
  region                   =  var.region
  ip_cidr_range            = "10.0.2.0/24"

  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = "10.3.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.4.0.0/20"
  }
}