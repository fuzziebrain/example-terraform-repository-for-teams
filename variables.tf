variable "tenancy_ocid" {
  description = "The OCID of your OCI tenancy."
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user Terraform will authenticate as."
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the API key used for authentication."
  type        = string
}

variable "private_key_path" {
  description = "The full path to the private key file used for authentication."
  type        = string
}

variable "region" {
  description = "The OCI region to deploy resources into (e.g., 'us-phoenix-1')."
  type        = string
}

variable "private_key_password" {
  description = "(Optional) Passphrase for the private key, if encrypted."
  type        = string
  sensitive   = true # Mark as sensitive to prevent showing in logs
  default     = null
  nullable    = true
}

variable "base_compartment_ocid" {
  description = "OCID for the base compartment to create the resources in."
  type        = string
}

variable "client_name" {
  description = "The client's name"
  type        = string
}

variable "vcn_name" {
  description = "User-friendly name of to use for the vcn to be appended to the label_prefix."
  type        = string
}

variable "vcn_dns_label" {
  description = "A DNS label for the VCN, used in conjunction with the VNIC's hostname and subnet's DNS label to form a fully qualified domain name (FQDN) for each VNIC within this subnet. DNS resolution of hostnames in the VCN is disabled when null."
  type        = string
}

variable "vcn_cidr_block" {
  description = "The CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_newbits" {
  description = "Newbits for calculating the public subnets' CIDR."
  type        = number
  default     = 8
}

variable "private_subnet_newbits" {
  description = "Newbits for calculating the private subnets' CIDR."
  type        = number
  default     = 8
}
