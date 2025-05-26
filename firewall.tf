resource "google_compute_firewall" "iap_ssh" {
  name          = "allow-iap-ssh"
  network       =  google_compute_network.vpc.id
  source_ranges = ["35.235.240.0/20"]  

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  target_tags = ["iap-ssh"]  
}