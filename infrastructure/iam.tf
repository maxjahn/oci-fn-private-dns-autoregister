
resource "oci_identity_user" "auto_user" {
  count          = var.create_faas_iam_setup ? 1 : 0
  compartment_id = var.tenancy_ocid
  description    = "Automation User"
  name           = "auto-user"
}

resource "oci_identity_user_group_membership" "app_auto_group_membership" {
  count    = var.create_faas_iam_setup ? 1 : 0
  group_id = oci_identity_group.fn_usr_grp[0].id
  user_id  = oci_identity_user.auto_user[0].id
}

resource "oci_identity_policy" "faas_root_policy" {
  count          = var.create_faas_iam_setup ? 1 : 0
  compartment_id = var.tenancy_ocid
  description    = "policy required for faas"
  name           = "faas-root-policy"
  statements = [
    "allow service FaaS to read repos in tenancy",
    "allow service FaaS to use virtual-network-family in tenancy",
    "allow service FaaS to use logs in tenancy"
  ]
}

resource "oci_identity_group" "fn_usr_grp" {
  count          = var.create_faas_iam_setup ? 1 : 0
  compartment_id = var.tenancy_ocid
  description    = "User group for fn"
  name           = "fn-usr-grp"
}

resource "oci_identity_policy" "fn_usr_grp_policy" {
  count          = var.create_faas_iam_setup ? 1 : 0
  compartment_id = var.tenancy_ocid
  description    = "policy for fn-usr-grp"
  name           = "fn-usr-grp-policy"
  depends_on = [
    oci_identity_group.fn_usr_grp,
  ]
  statements = [
    "allow group fn-usr-grp to manage repos in tenancy",
    "allow group fn-usr-grp to use virtual-network-family in tenancy",
    "allow group fn-usr-grp to manage functions-family in compartment id ${var.oci_compartment_ocid}",
    "allow group fn-usr-grp to read metrics in compartment id ${var.oci_compartment_ocid}",
    "allow group fn-usr-grp to read objectstorage-namespaces in compartment id ${var.oci_compartment_ocid}",
    "allow group fn-usr-grp to use cloud-shell in compartment id ${var.oci_compartment_ocid}",
    "allow group fn-usr-grp to manage logs in compartment id ${var.oci_compartment_ocid}",
  ]
}

resource "oci_identity_dynamic_group" "fn_dyn_grp" {
  count          = var.create_iam_dyngroup ? 1 : 0
  compartment_id = var.tenancy_ocid
  description    = "dynamic group for functions"
  matching_rule  = "ALL {resource.type = 'fnfunc', resource.compartment.id = '${var.oci_compartment_ocid}'}"
  name           = "fn-dyn-grp-dns-autoregister"
}

resource "oci_identity_policy" "fn_dyn_policy" {
  count          = var.create_iam_dyngroup_policy ? 1 : 0
  compartment_id = var.tenancy_ocid
  description    = "policy for fn-dyn-grp"
  name           = "fn-dyn-grp-dns-autoregister-policy"
  depends_on = [
    oci_identity_dynamic_group.fn_dyn_grp
  ]
  statements = [
    "allow dynamic-group fn-dyn-grp-dns-autoregister to manage dns-family in compartment id ${var.oci_dns_zone_compartment}",
    "allow dynamic-group fn-dyn-grp-dns-autoregister to manage virtual-network-family in compartment id ${var.oci_dns_zone_compartment}",
    "allow dynamic-group fn-dyn-grp-dns-autoregister to use all-resources in compartment id ${var.oci_dns_zone_compartment}",
    "allow dynamic-group fn-dyn-grp-dns-autoregister to use logs in compartment id ${var.oci_dns_zone_compartment}",
  
  ]
}

