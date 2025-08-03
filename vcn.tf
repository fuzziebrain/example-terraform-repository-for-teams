resource "oci_core_vcn" "main_vcn" {
  # The OCID of the compartment where the VCN will be created.
  compartment_id = oci_identity_compartment.client_compartment.id

  # The CIDR block for the VCN.
  # This value is sourced from the 'vcn_cidr_block' variable.
  cidr_block = var.vcn_cidr_block

  # A user-friendly name for the VCN.
  display_name = var.vcn_name

  # DNS label for the VCN, used for hostname resolution within the VCN.
  dns_label = var.vcn_dns_label

  # Enable or disable IPv6 for the VCN.
  is_ipv6enabled = false

  # Optional: Free-form tags for the VCN.
  freeform_tags = {
  }
}

# --- Internet Gateway Definition ---
resource "oci_core_internet_gateway" "internet_gateway" {
  # The OCID of the compartment where the Internet Gateway will be created.
  compartment_id = oci_core_vcn.main_vcn.compartment_id

  # Whether the Internet Gateway is enabled.
  enabled = true

  # A user-friendly name for the Internet Gateway.
  display_name = "${var.vcn_name}-igw01"

  # The OCID of the VCN to which this Internet Gateway will be attached.
  vcn_id = oci_core_vcn.main_vcn.id
}

# --- NAT Gateway Definition ---
resource "oci_core_nat_gateway" "nat_gateway" {
  # The OCID of the compartment where the NAT Gateway will be created.
  compartment_id = oci_core_vcn.main_vcn.compartment_id

  # A user-friendly name for the NAT Gateway.
  display_name = "${var.vcn_name}-ngw01"

  # The OCID of the VCN to which this NAT Gateway will be attached.
  vcn_id = oci_core_vcn.main_vcn.id
}

# --- Service Gateway Definition ---
resource "oci_core_service_gateway" "service_gateway" {
  # The OCID of the compartment where the Service Gateway will be created.
  compartment_id = oci_core_vcn.main_vcn.compartment_id

  # A user-friendly name for the Service Gateway.
  display_name = "${var.vcn_name}-sgw01"

  # The OCID of the VCN to which this Service Gateway will be attached.
  vcn_id = oci_core_vcn.main_vcn.id

  # Define the service(s) to which this gateway provides access.
  # "All Services in Oracle Services Network" provides access to all OCI public services.
  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
}

# --- Route Table for Public Subnet ---
resource "oci_core_route_table" "public_route_table" {
  # The OCID of the compartment where the route table will be created.
  compartment_id = oci_core_vcn.main_vcn.compartment_id

  # A user-friendly name for the public route table.
  display_name = "${var.vcn_name}-pub-rt"

  # The OCID of the VCN to which this route table belongs.
  vcn_id = oci_core_vcn.main_vcn.id

  # Define route rules for the public route table.
  route_rules {
    # Destination CIDR for the rule. 0.0.0.0/0 means all traffic.
    destination = "0.0.0.0/0"
    # The type of destination. Here, 'CIDR_BLOCK' refers to the CIDR block.
    destination_type = "CIDR_BLOCK"
    # The OCID of the Internet Gateway as the target for this route.
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

# --- Route Table for Private Subnets ---
resource "oci_core_route_table" "private_route_table" {
  # The OCID of the compartment where the route table will be created.
  compartment_id = oci_core_vcn.main_vcn.compartment_id

  # A user-friendly name for the private route table.
  display_name = "${var.vcn_name}-prv-rt"

  # The OCID of the VCN to which this route table belongs.
  vcn_id = oci_core_vcn.main_vcn.id

  # Rule 1: Route all general internet-bound traffic (0.0.0.0/0) through the NAT Gateway.
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
  }

  # Rule 2: Route traffic destined for OCI public services through the Service Gateway.
  # The 'destination' here refers to the service CIDR label (e.g., "all-ashburn-services").
  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.service_gateway.id
  }
}

# --- Public Subnet Definition ---
resource "oci_core_subnet" "public_subnet" {
  # The OCID of the compartment where the subnet will be created.
  compartment_id = oci_core_vcn.main_vcn.compartment_id

  # The CIDR block for the public subnet.
  # cidrsubnet(prefix, newbits, netnum) calculates a subnet CIDR.
  # Here, it takes the VCN's CIDR, adds 'public_subnet_newbits' (8 for /24),
  # and uses netnum 0 for the first available subnet.
  cidr_block = cidrsubnet(var.vcn_cidr_block, var.public_subnet_newbits, 0)

  # A user-friendly name for the public subnet.
  display_name = "${var.vcn_name}-pub-sn"

  # The OCID of the VCN to which this subnet belongs.
  vcn_id = oci_core_vcn.main_vcn.id

  # The OCID of the route table associated with this subnet.
  # Public subnets route traffic through the Internet Gateway.
  route_table_id = oci_core_route_table.public_route_table.id

  # The OCID of the security list associated with this subnet.
  # By default, we associate the VCN's default security list.
  security_list_ids = [oci_core_vcn.main_vcn.default_security_list_id]

  # Make the subnet public by enabling public IP addresses for instances.
  prohibit_public_ip_on_vnic = false

  # DNS label for the subnet.
  dns_label = "pub"
}

# --- Private Subnet 1 Definition ---
resource "oci_core_subnet" "private_subnet_01" {
  # The OCID of the compartment where the subnet will be created.
  compartment_id = oci_core_vcn.main_vcn.compartment_id

  # The CIDR block for the first private subnet.
  # cidrsubnet(prefix, newbits, netnum) calculates a subnet CIDR.
  # Here, it takes the VCN's CIDR, adds 'private_subnet_newbits' (8 for /24),
  # and uses netnum 1 for the second available subnet (after the public one).
  cidr_block = cidrsubnet(var.vcn_cidr_block, var.private_subnet_newbits, 1)

  # A user-friendly name for the first private subnet.
  display_name = "${var.vcn_name}-prv-sn-01"

  # The OCID of the VCN to which this subnet belongs.
  vcn_id = oci_core_vcn.main_vcn.id

  # The OCID of the route table associated with this subnet.
  # Private subnets route outbound traffic through the NAT Gateway.
  route_table_id = oci_core_route_table.private_route_table.id

  # The OCID of the security list associated with this subnet.
  # By default, we associate the VCN's default security list.
  security_list_ids = [oci_core_vcn.main_vcn.default_security_list_id]

  # Make the subnet private by prohibiting public IP addresses on instances.
  prohibit_public_ip_on_vnic = true

  # DNS label for the subnet.
  dns_label = "prv01"
}

# --- Private Subnet 2 Definition ---
resource "oci_core_subnet" "private_subnet_02" {
  # The OCID of the compartment where the subnet will be created.
  compartment_id = oci_core_vcn.main_vcn.compartment_id

  # The CIDR block for the second private subnet.
  # cidrsubnet(prefix, newbits, netnum) calculates a subnet CIDR.
  # Here, it takes the VCN's CIDR, adds 'private_subnet_newbits' (8 for /24),
  # and uses netnum 2 for the third available subnet.
  cidr_block = cidrsubnet(var.vcn_cidr_block, var.private_subnet_newbits, 2)

  # A user-friendly name for the second private subnet.
  display_name = "${var.vcn_name}-prv-sn-02"

  # The OCID of the VCN to which this subnet belongs.
  vcn_id = oci_core_vcn.main_vcn.id

  # The OCID of the route table associated with this subnet.
  # Private subnets route outbound traffic through the NAT Gateway.
  route_table_id = oci_core_route_table.private_route_table.id

  # The OCID of the security list associated with this subnet.
  # By default, we associate the VCN's default security list.
  security_list_ids = [oci_core_vcn.main_vcn.default_security_list_id]

  # Make the subnet private by prohibiting public IP addresses on instances.
  prohibit_public_ip_on_vnic = true

  # DNS label for the subnet.
  dns_label = "prv02"
}

# --- Default Security List (Optional, but good for initial setup) ---
# This resource allows you to modify the VCN's default security list.
# By default, OCI creates a default security list for a VCN.
# You can add ingress/egress rules here to allow basic traffic.
# For more granular control, create separate security list resources.
resource "oci_core_default_security_list" "default_security_list" {
  # Use the ID of the VCN's default security list.
  manage_default_resource_id = oci_core_vcn.main_vcn.default_security_list_id

  # The OCID of the compartment where the security list resides.
  compartment_id = oci_core_vcn.main_vcn.compartment_id

  # A user-friendly name for the security list.
  display_name = "${var.vcn_name}-default-security-list"

  # Ingress rules (inbound traffic).
  ingress_security_rules {
    # Allow ICMP (ping) from anywhere.
    protocol = "1" # ICMP
    source   = "0.0.0.0/0"
    icmp_options {
      code = 4
      type = 8
    }
  }

  # Egress rules (outbound traffic).
  egress_security_rules {
    # Allow all outbound traffic to anywhere.
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}
