variable "key_file" {
  description = "Path to the service account key file"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "cluster_name" {
  description = "GCP Kubernetes cluster name"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "helm_path" {
  description = "Path to Helm charts"
  type        = string
}

variable "available_namespaces" {
  description = "A list of all available namespaces"
  type        = list(string)
  default     = ["hujp-apu301-uat","hujp-apu302-uat","vrt-120-uat","vrt-500-uat","vrt-800-uat","vrt-900-uat","vrt-duclaux-uat","vrt-120-training","vrt-500-training","vrt-800-training","vrt-900-training","vrt-duclaux-training","ff-metamizole-uat","hujp-apu1-uat","hujp-apu2-training"]
}

variable "namespaces" {
  description = "list of indices for namespaces to select for Helm upgrade (e.g., 0,1)\n0.hujp-apu301-uat\n1.hujp-apu302-uat\n2.vrt-120-uat\n3.vrt-500-uat\n4.vrt-800-uat\n5.vrt-900-uat\n6.vrt-duclaux-uat\n7.vrt-120-training\n8.vrt-500-training\n9.vrt-800-training\n10.vrt-900-training\n11.vrt-duclaux-training\n12.ff-metamizole-uat\n13.hujp-apu1-uat\n14.hujp-apu2-training"
  type        = string
}
variable "smtp_server" {
  description = "SMTP server address"
  type        = string
}

variable "smtp_port" {
  description = "SMTP server port"
  type        = number
}

variable "smtp_user" {
  description = "SMTP server username"
  type        = string
}

variable "smtp_password" {
  description = "SMTP server password"
  type        = string
  sensitive   = true
}

variable "email_recipient" {
  description = "Email recipient(s) separated by commas"
  type        = string
}

variable "email_sender" {
  description = "Email sender address"
  type        = string
}
