data "oci_core_images" "demo_vm_images" {
    compartment_id = var.oci_compartment_ocid

    operating_system = "Oracle Linux"
    sort_by = "TIMECREATED"
    sort_order = "DESC"
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.oci_compartment_ocid
}

resource "oci_core_instance" "private_vm" {
  count = var.create_oci_private_demo_vm ? 1 : 0

  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0]["name"]
  compartment_id      = var.oci_compartment_ocid
  shape               = var.oci_private_demo_vm_shape

  create_vnic_details {
    subnet_id              = oci_core_subnet.private_subnet[0].id
    assign_public_ip       = false
    skip_source_dest_check = true
  }

  display_name = var.oci_private_demo_vm_name

  metadata = {
    ssh_authorized_keys = var.oci_private_demo_vm_sshkey
  }

  source_details {
    source_id   = data.oci_core_images.demo_vm_images.images[0].id
    source_type = "image"
  }

  preserve_boot_volume = false

}

resource "oci_core_instance" "public_vm" {
  count = var.create_oci_public_demo_vm ? 1 : 0

  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0]["name"]
  compartment_id      = var.oci_compartment_ocid
  shape               = var.oci_public_demo_vm_shape

  create_vnic_details {
    subnet_id              = oci_core_subnet.public_subnet[0].id
    assign_public_ip       = true
    skip_source_dest_check = true
  }

  display_name = var.oci_public_demo_vm_name

  metadata = {
    ssh_authorized_keys = var.oci_private_demo_vm_sshkey
  }

  source_details {
    source_id   = data.oci_core_images.demo_vm_images.images[0].id
    source_type = "image"
  }

  preserve_boot_volume = false

}

resource "oci_dns_record" "public_vm_record" {
    count = var.create_oci_public_demo_vm ? 1 : 0
    zone_name_or_id = oci_dns_zone.private_dns_zone.id
    domain = "${var.oci_public_demo_vm_name}.${var.oci_dns_zone}"
    rtype = "A"
    rdata = local.public_vm_private_ip
    ttl = 30
}

resource "oci_dns_record" "private_vm_record" {
    count = var.create_oci_public_demo_vm ? 1 : 0
    zone_name_or_id = oci_dns_zone.private_dns_zone.id
    domain = "${var.oci_private_demo_vm_name}.${var.oci_dns_zone}"
    rtype = "A"
    rdata = local.private_vm_private_ip
    ttl = 30
}


