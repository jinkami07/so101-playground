terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "region" {
  description = "GCP リージョン"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP ゾーン"
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "VM インスタンス名"
  type        = string
  default     = "smolvla-trainer"
}

variable "ssh_user" {
  description = "SSH ユーザー名"
  type        = string
  default     = "ubuntu"
}

variable "ssh_pub_key_path" {
  description = "SSH 公開鍵のパス"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# ブートディスク (Ubuntu 22.04 LTS)
locals {
  boot_image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
}

# VPC ネットワーク (デフォルトを使用)
data "google_compute_network" "default" {
  name = "default"
}

# ファイアウォール: SSH & JupyterLab
resource "google_compute_firewall" "smolvla_fw" {
  name    = "${var.instance_name}-fw"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["22", "8888"] # SSH, JupyterLab
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["smolvla-trainer"]
}

# g2-standard-4: vCPU×4, RAM 16GB, NVIDIA L4 (24GB VRAM)
resource "google_compute_instance" "smolvla_trainer" {
  name         = var.instance_name
  machine_type = "g2-standard-4"
  zone         = var.zone

  tags = ["smolvla-trainer"]

  boot_disk {
    initialize_params {
      image = local.boot_image
      size  = 100 # GB (LeRobot + データセット用)
      type  = "pd-ssd"
    }
  }

  # L4 GPU
  guest_accelerator {
    type  = "nvidia-l4"
    count = 1
  }

  scheduling {
    on_host_maintenance = "TERMINATE" # GPU使用時は必須
    automatic_restart   = true
  }

  network_interface {
    network = data.google_compute_network.default.name
    access_config {} # 外部IPを割り当て
  }

  metadata = {
    ssh-keys               = "${var.ssh_user}:${file(pathexpand(var.ssh_pub_key_path))}"
    startup-script-url     = "gs://${var.project_id}-scripts/startup.sh"
    # startup.sh が GCS に置けない場合は直接インライン化:
    # startup-script = file("${path.module}/startup.sh")
  }

  # startup.sh をローカルから直接使う場合はこちら
  # metadata_startup_script = file("${path.module}/startup.sh")

  service_account {
    scopes = ["cloud-platform"]
  }

  labels = {
    env     = "training"
    project = "so101-smolvla"
  }
}

output "instance_ip" {
  description = "VM の外部 IP アドレス"
  value       = google_compute_instance.smolvla_trainer.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  description = "SSH 接続コマンド"
  value       = "ssh ${var.ssh_user}@${google_compute_instance.smolvla_trainer.network_interface[0].access_config[0].nat_ip}"
}
