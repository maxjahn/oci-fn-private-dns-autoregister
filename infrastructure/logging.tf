data "oci_logging_log_groups" "app_log_groups" {
    compartment_id = coalesce(var.fn_application_compartment, var.oci_compartment_ocid)
    display_name = "${var.fn_application_name}_logs"
}

data "oci_logging_log_groups" "default_groups" {
    compartment_id = coalesce(var.fn_application_compartment, var.oci_compartment_ocid)
    display_name = "Default_Group"
}

locals {
    n_app_logs = length(data.oci_logging_log_groups.app_log_groups.log_groups)
    n_default_logs = length(data.oci_logging_log_groups.default_groups.log_groups)
    app_log_group_missing = (local.n_app_logs + local.n_default_logs) > 0 ? false : true  
    app_log_group = concat( data.oci_logging_log_groups.default_groups.log_groups, oci_logging_log_group.app_log_group, data.oci_logging_log_groups.app_log_groups.log_groups)
}

resource "oci_logging_log_group" "app_log_group" {
    count = ( local.app_log_group_missing && var.create_fn_application_log ) ? 1 : 0
    compartment_id = coalesce(var.fn_application_compartment, var.oci_compartment_ocid)
    display_name = "${var.fn_application_name}_logs"
}

resource "oci_logging_log" "app_log" {
    count          = var.create_fn_application_log ? 1 : 0
    display_name = "${var.fn_application_name}_log"
    log_group_id = local.app_log_group[0].id
    log_type = "SERVICE"
    configuration {
        source {
            category = "invoke"
            resource = oci_functions_application.automation_app[0].id
            service = "functions"
            source_type = "OCISERVICE"
        }
    }
    is_enabled = true
}

resource "oci_logging_log" "events_log" {
    count          = var.create_events_log ? 1 : 0
    display_name = "${oci_events_rule.autoregister_rule[0].display_name}_log"
    log_group_id = local.app_log_group[0].id
    log_type = "SERVICE"
    configuration {
        source {
            category = "ruleexecutionlog"
            resource = oci_events_rule.autoregister_rule[0].id
            service = "cloudevents"
            source_type = "OCISERVICE"
        }
    }
    is_enabled = true
}






