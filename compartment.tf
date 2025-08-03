resource "oci_identity_compartment" "client_compartment" {
  compartment_id = var.base_compartment_ocid
  description    = "Compartment for ${var.client_name}"
  name           = var.client_name
  #   enable_delete  = var.enable_delete_compartment
}
