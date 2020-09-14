resource "oci_dns_zone" "private_dns_zone" {
  compartment_id = coalesce(var.oci_dns_zone_compartment, var.oci_compartment_ocid)
  name           = var.oci_dns_zone
  zone_type      = "PRIMARY"

}

## this is an ugly hack to work around oracle resource managers restriction of not having the dns provider available
data "oci_dns_records" "dns_zone_nameservers" {
  count           = 3
  zone_name_or_id = oci_dns_zone.private_dns_zone.id
  rtype           = "NS"
}

locals {
  dns_servers     = [for ns in data.oci_dns_records.dns_zone_nameservers[0].records[*].rdata : trimsuffix(ns, ".")]
  dns_servers_ips = split("\n", data.local_file.file_ips.content)
}

resource "null_resource" "nslookup" {
  count = 4
  triggers = {
    trigger = timestamp()
  }
  provisioner "local-exec" {
    command = "dig ${local.dns_servers[count.index]} +short >> ${path.module}/ips.txt"
  }
}

resource "null_resource" "cleanup" {
  triggers = {
    trigger = data.local_file.file_ips.content
  }

  provisioner "local-exec" {
    command = "rm -f ${path.module}/ips.txt"
  }

  depends_on = [null_resource.nslookup]
}

data "local_file" "file_ips" {
  filename   = "${path.module}/ips.txt"
  depends_on = [null_resource.nslookup]
}
## /hack

resource "oci_core_dhcp_options" "private_dns_dhcp_options" {
  count          = var.create_dhcp_options_separate ? 1 : 0
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_virtual_network.app_vcn[0].id
  display_name   = "DHCP Options for ${var.oci_dns_zone}"

  options {
    type               = "DomainNameServer"
    server_type        = "CustomDnsServer"
    custom_dns_servers = slice(local.dns_servers_ips, 0, min(length(local.dns_servers_ips), 3))
  }

  options {
    type                = "SearchDomain"
    search_domain_names = [var.oci_dns_zone]
  }
}

resource "oci_core_default_dhcp_options" "default-dhcp-options" {
  count                      = var.create_dhcp_options_separate ? 0 : 1
  manage_default_resource_id = oci_core_virtual_network.app_vcn[0].default_dhcp_options_id

  options {
    type               = "DomainNameServer"
    server_type        = "CustomDnsServer"
    custom_dns_servers = concat(slice(local.dns_servers_ips, 0, min(length(local.dns_servers_ips), 2)), [ var.create_oci_hybrid_dns ? var.public_dns_server : ""])
  }

  options {
    type                = "SearchDomain"
    search_domain_names = [var.oci_dns_zone]
  }
}


