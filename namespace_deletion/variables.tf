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

variable "namespaces" {
  description = "List of namespaces for Helm upgrade"
  type        = list(string)
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
