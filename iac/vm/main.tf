# Generate SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/helicone.pem"
  file_permission = "0600"
}

# Create a static IP for the VM
resource "google_compute_address" "helicone" {
  name         = "helicone"
  region       = var.region
  address_type = "EXTERNAL"
}

# Create the VM instance
resource "google_compute_instance" "helicone" {
  name         = "helicone"
  machine_type = "e2-standard-4"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-2410-oracular-amd64-v20250311"
      size  = 512
    }
  }

  network_interface {
    network    = "default"
    subnetwork = "default"

    access_config {
      nat_ip = google_compute_address.helicone.address
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.ssh_key.public_key_openssh}"
  }

  tags = ["helicone"]

  service_account {
    scopes = ["cloud-platform"]
  }
}

# Firewall rule to allow SSH access
resource "google_compute_firewall" "helicone_ssh" {
  name    = "allow-ssh-helicone"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.sofia_team_ips
  target_tags   = ["helicone"]
}

# Firewall rule to allow http and https traffic
resource "google_compute_firewall" "helicone_traffic" {
  name    = "allow-helicone-traffic"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"] # Allow http and https traffic from anywhere
  target_tags   = ["helicone"]
}

# Create snapshot schedule for daily backups at 2 AM UTC-3 (5 AM UTC)
resource "google_compute_resource_policy" "daily_backup" {
  name   = "helicone-daily-backup"
  region = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "05:00" # 5 AM UTC = 2 AM UTC-3
      }
    }

    retention_policy {
      max_retention_days    = 14
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }

    snapshot_properties {
      labels = {
        backup = "daily"
      }
      storage_locations = [var.region]
    }
  }
}

# Attach backup schedule to the VM's disk
resource "google_compute_disk_resource_policy_attachment" "attachment" {
  name = google_compute_resource_policy.daily_backup.name
  disk = google_compute_instance.helicone.name
  zone = google_compute_instance.helicone.zone
}
