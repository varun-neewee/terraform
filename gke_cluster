provider "google" {
  project = var.project_id
  region  = var.region
  credentials = file("/home/localstudio/varun/cluster/bps-dev-ssn-default-account.json")
}

resource "google_container_cluster" "autopilot_cluster" {
  name       = var.cluster_name
  location   = var.region
  project    = var.project_id
  network    = var.network
  subnetwork = var.subnet

  deletion_protection = false

  release_channel {
    channel = "REGULAR"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_global_access_config {
      enabled = true # Enable master global access
    }
#    master_ipv4_cidr_block  = "10.0.0.0/28"
  }

   master_authorized_networks_config {
     gcp_public_cidrs_access_enabled = true
     dynamic "cidr_blocks" {
       for_each = var.authorized_networks
       content {
         cidr_block   = cidr_blocks.value.cidr_block
         display_name = cidr_blocks.value.display_name
       }
     }
   }


  ip_allocation_policy {
    cluster_ipv4_cidr_block = "/17"
  }

  maintenance_policy {
    recurring_window  {
      start_time = var.maintenance_start_time # Start time (Saturday at 03:00 UTC)
      end_time   =  var.maintenance_end_time # End time (2 hours later)
      recurrence = var.maintenance_recurrence # Weekly recurrence on Saturdays
    }
  }

#  monitoring_config {
#    enable_components = true
#    advanced_datapath_observability_config {
#      enable_metrics = true
#      enable_relay   = true
#    }
#  }

  # enabling L4 subsetting
  enable_l4_ilb_subsetting = true

  # enabling secret manager
  secret_manager_config {
    enabled = true
  }

  # enabling autopilot mode
  enable_autopilot = true

  # metadata description
  description = "This is my GKE cluster for development purposes."

  # Resource labels for the cluster
  resource_labels = {
    foo         = "bar"
    environment = "development"
    team        = "devops"
  }

  logging_config {
    enable_components = ["WORKLOADS","SYSTEM_COMPONENTS","APISERVER","SCHEDULER","CONTROLLER_MANAGER"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS","APISERVER","SCHEDULER","CONTROLLER_MANAGER","STORAGE","POD","DAEMONSET","DEPLOYMENT","STATEFULSET","HPA","CADVISOR","KUBELET"]
  }

}
