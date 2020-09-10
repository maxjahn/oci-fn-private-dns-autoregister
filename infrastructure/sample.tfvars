tenancy_ocid            = "ocid1.tenancy..."
region                  = "..."
oci_user_ocid           = "ocid1.user.oc1..."
oci_compartment_ocid    = "ocid1.compartment.oc1..."
oci_fingerprint         = "..."

create_new_network=true
oci_vcn_name = "app-vcn"
oci_cidr_vcn            = "10.0.0.0/16"
oci_private_subnet_name = "private-subnet"
oci_cidr_private_subnet = "10.0.1.0/24"
oci_public_subnet_name = "public-subnet"
oci_cidr_public_subnet  = "10.0.2.0/24"

create_oci_private_demo_vm= false
create_oci_public_demo_vm= false
oci_private_demo_vm_name= ""
oci_private_demo_vm_sshkey= ""
oci_public_demo_vm_name= ""
oci_public_demo_vm_sshkey= ""

oci_dns_zone            = "zone.oci"
oci_dns_zone_compartment = "..." # falls back to oci_compartment_ocid
create_dhcp_options_separate = false

create_autoregistration_tags = true
tag_autoregister_namespace = "Automation"
tag_autoregister_dnszone = "DNSZone"
tag_autoregister_dnshostname = "DNSHostname"

create_iam_dyngroup = true
create_iam_dyngroup_policy = true
create_automation_user = true
create_new_fn_application = true

fn_application_name = "automation-app"
fn_use_existing_network = false 
fn_application_compartment = "..." # falls back to oci_compartment_ocid
fn_application_vcn = "..." 
fn_application_subnet = "..."
create_fn_function = true
fn_function_image = "" #  use default value unless you have your own function uploaded to OCIR
create_tags_fn_application_config = true
create_autoregister_event = true
