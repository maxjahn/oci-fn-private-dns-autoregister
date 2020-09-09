resource "oci_core_virtual_network" "app_vcn" {
  count = var.create_new_network ? 1 : 0

  compartment_id = var.oci_compartment_ocid
  cidr_block     = var.oci_cidr_vcn
  dns_label      = replace(var.oci_vcn_name, "-", "")
  display_name   = var.oci_vcn_name
}

resource "oci_core_subnet" "private_subnet" {
  count = var.create_new_network ? 1 : 0

  compartment_id = var.oci_compartment_ocid
  cidr_block     = var.oci_cidr_private_subnet
  vcn_id         = oci_core_virtual_network.app_vcn[0].id
  prohibit_public_ip_on_vnic = true
  display_name   = var.oci_private_subnet_name
  dns_label      = replace(var.oci_private_subnet_name, "-", "")
}

resource "oci_core_subnet" "public_subnet" {
  count = var.create_new_network ? 1 : 0

  compartment_id = var.oci_compartment_ocid
  cidr_block     = var.oci_cidr_public_subnet
  vcn_id         = oci_core_virtual_network.app_vcn[0].id
  display_name   = var.oci_public_subnet_name
  dns_label      = replace(var.oci_public_subnet_name, "-", "")
}

resource "oci_core_internet_gateway" "app_igw" {
  count = var.create_new_network ? 1 : 0

  display_name   = "app-internet-gateway"
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_virtual_network.app_vcn[0].id
}

resource "oci_core_default_route_table" "default_route_table" {
  count = var.create_new_network ? 1 : 0

  manage_default_resource_id = oci_core_virtual_network.app_vcn[0].default_route_table_id

  route_rules {
    network_entity_id = oci_core_internet_gateway.app_igw[0].id
    destination       = "0.0.0.0/0"
  }
}
