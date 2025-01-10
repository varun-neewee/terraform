variable "authorized_networks" {
  default = [
    { cidr_block = "106.51.39.244/32", display_name = "Neewee Office-01" },
    { cidr_block = "141.148.226.27/32", display_name = "Neewee Office-NL" },
    { cidr_block = "119.82.111.166/32", display_name = "Neewee Office-02" },
    { cidr_block = "128.185.100.82/32", display_name = "Neewee Office-03" }
  ]
}

variable "project_id" {
  type        = string
  description = "The project ID to host the cluster in (required)"
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster (required)"
}

variable "region" {
  type        = string
  description = "The region to host the cluster in (optional if zonal cluster / required if regional)"
}

variable "network" {
  type        = string
  description = "The VPC network to host the cluster in (required)"
}

variable "subnet" {
  type        = string
  description = "The subnetwork to host the cluster in (required)"
}

variable "maintenance_start_time" {
  type        = string
  description = "Time window specified for daily or recurring maintenance operations in RFC3339 format"
}

variable "maintenance_end_time" {
  type        = string
  description = "Time window specified for recurring maintenance operations in RFC3339 format"
}

variable "maintenance_recurrence" {
  type        = string
  description = "Frequency of the recurring maintenance window in RFC5545 format."
}
