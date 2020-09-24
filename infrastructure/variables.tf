
variable "tenancy_ocid" {}
variable "oci_user_ocid" { default = "" }
variable "oci_fingerprint" { default = "" }
variable "region" { default = "eu-frankfurt-1" }
variable "oci_compartment_ocid" {}

# dns zone 
variable "oci_dns_zone" { default = "dev.oci"}
variable "oci_dns_zone_compartment" {}
variable "create_dhcp_options_separate" { default = false }

# new network
variable "create_new_network" { default = true }
variable "oci_vcn_name" { default = "app-vcn" }
variable "oci_cidr_vcn" { default = "10.0.0.0/16" }
variable "oci_private_subnet_name" { default = "private-subnet" }
variable "oci_cidr_private_subnet" { default = "10.0.1.0/24" }
variable "oci_public_subnet_name" { default = "public-subnet" }
variable "oci_cidr_public_subnet" { default = "10.0.2.0/24" }
variable "create_oci_hybrid_dns" {default = true}


#demo vms
variable "create_oci_private_demo_vm" { default = false }
variable "create_oci_public_demo_vm" { default = false }
variable "oci_private_demo_vm_name" {}
variable "oci_private_demo_vm_shape" { default = "VM.Standard2.1"}
variable "oci_private_demo_vm_sshkey" {}
variable "oci_public_demo_vm_name" {}
variable "oci_public_demo_vm_shape" { default = "VM.Standard2.1"}
variable "oci_public_demo_vm_sshkey" {}

# tags
variable "create_autoregistration_tags" { default = true }
variable "tag_autoregister_namespace" { default = "Automation" }
variable "tag_autoregister_dnszone" { default = "DNSZone" }
variable "tag_autoregister_dnshostname" { default = "DNSHostname" }

# iam
variable "create_iam_dyngroup" { default = false }
variable "create_iam_dyngroup_policy" { default = false }
variable "create_faas_iam_setup" { default = false }

# fn application
variable "create_new_fn_application" { default = true }
variable "fn_application_name" { default = "automation-app" }
variable "fn_use_existing_network" { default = false}
variable "fn_application_compartment" { default = "" }
variable "fn_application_subnet" { default = "" }
variable "create_fn_function" { default = true }
variable "create_tags_fn_application_config" { default = false }
variable "create_autoregister_event" { default = true }
variable "create_fn_application_log" { default = true }
variable "create_events_log" { default = true }

## defaults
variable "fn_function_image" { default = "eu-frankfurt-1.ocir.io/fr4sem1lm5ss/fn-automation/event-dns-autoregister:latest" }
variable "public_dns_server" {default = "169.254.169.254"}

## oracle resource manager selection variables, required to store selections with orm
variable "fn_application_vcn" { default = "" }
variable "create_autoregistration_app_function" { default = true }




