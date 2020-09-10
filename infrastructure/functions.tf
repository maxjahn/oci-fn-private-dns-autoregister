resource "oci_functions_application" "automation_app" {
  count          = var.create_new_fn_application ? 1 : 0
  compartment_id = coalesce(var.fn_application_compartment, var.oci_compartment_ocid)
  display_name   = var.fn_application_name
  subnet_ids     = [coalesce(var.fn_application_subnet,oci_core_subnet.fn_subnet[0].id)]
}

data "oci_functions_applications" "oci_fn_app" {
  compartment_id = coalesce(var.fn_application_compartment, var.oci_compartment_ocid)
  display_name   = var.fn_application_name
  depends_on     = [oci_functions_application.automation_app]
}

## tags
resource "oci_identity_tag_namespace" "automation_tag_namespace" {
  count          = var.create_autoregistration_tags ? 1 : 0
  compartment_id = var.oci_compartment_ocid
  description    = "Tags used for Automation tasks"
  name           = var.tag_autoregister_namespace
}
resource "oci_identity_tag" "dnshostname_tag" {
  count            = var.create_autoregistration_tags ? 1 : 0
  description      = "Private DNS Hostname"
  name             = var.tag_autoregister_dnshostname
  tag_namespace_id = oci_identity_tag_namespace.automation_tag_namespace[0].id
}
resource "oci_identity_tag" "dnszone_tag" {
  count            = var.create_autoregistration_tags ? 1 : 0
  description      = "Private DNS Zone"
  name             = var.tag_autoregister_dnszone
  tag_namespace_id = oci_identity_tag_namespace.automation_tag_namespace[0].id
}
locals {
  fn_config = { "OCI_DNS_TAG_NAMESPACE" = var.tag_autoregister_namespace, "OCI_DNS_TAG_ZONE" = var.tag_autoregister_dnszone, "OCI_DNS_TAG_HOSTNAME" = var.tag_autoregister_dnshostname }
}

resource "oci_functions_function" "autoregister_function" {
  count          = var.create_fn_function ? 1 : 0
  application_id = coalesce(oci_functions_application.automation_app[0].id, data.oci_functions_applications.oci_fn_app.id)
  display_name   = "event-dns-autoregister"
  image          = var.fn_function_image
  memory_in_mbs  = "256"
  config         = local.fn_config
  depends_on     = [data.oci_functions_applications.oci_fn_app]
}

resource "oci_events_rule" "autoregister_rule" {
  count = var.create_autoregister_event ? 1 : 0

  actions {
    actions {
      action_type = "FAAS"
      is_enabled  = true

      description = "Updates DNS Zone with changed VM data"
      function_id = oci_functions_function.autoregister_function[0].id
    }
  }
  compartment_id = coalesce(var.fn_application_compartment, var.oci_compartment_ocid)
  condition      = "{\"eventType\":[\"com.oraclecloud.computeapi.terminateinstance.begin\",\"com.oraclecloud.computeapi.updateinstance\",\"com.oraclecloud.computeapi.launchinstance.end\"],\"data\":{\"definedTags\":{\"Automation\":{\"DNSZone\":\"${var.oci_dns_zone}\"}}}}"
  display_name   = "autoregister_private_dns"
  is_enabled     = true
}

resource "oci_core_virtual_network" "fn_vcn" {
  count          = (var.create_fn_function && !var.fn_use_existing_network) ? 1 : 0
  compartment_id = var.oci_compartment_ocid
  cidr_block     = "10.254.0.0/16"
  dns_label      = "fnvcn"
  display_name   = "fn-vcn"
}

resource "oci_core_subnet" "fn_subnet" {
  count          = (var.create_fn_function && !var.fn_use_existing_network) ? 1 : 0
  compartment_id = var.oci_compartment_ocid
  cidr_block     = "10.254.1.0/24"
  vcn_id         = oci_core_virtual_network.fn_vcn[0].id
  display_name   = "fn-subnet"
  dns_label      = "fnsubnet"
}

resource "oci_core_internet_gateway" "fn_igw" {
  count          = (var.create_fn_function && !var.fn_use_existing_network) ? 1 : 0
  display_name   = "fn-internet-gateway"
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_virtual_network.fn_vcn[0].id
}

resource "oci_core_default_route_table" "fn_default_route_table" {
  count          = (var.create_fn_function && !var.fn_use_existing_network) ? 1 : 0
  manage_default_resource_id = oci_core_virtual_network.fn_vcn[0].default_route_table_id

  route_rules {
    network_entity_id = oci_core_internet_gateway.fn_igw[0].id
    destination       = "0.0.0.0/0"
  }
}




