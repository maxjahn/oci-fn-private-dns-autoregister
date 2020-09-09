
data "oci_core_instance" "private_vm" {
    instance_id = oci_core_instance.private_vm[0].id
}

data "oci_core_instance" "public_vm" {
    instance_id = oci_core_instance.public_vm[0].id
}

output "public_vm_private_ip" {
    value = data.oci_core_instance.public_vm.private_ip
}

output "public_vm_public_ip" {
    value = data.oci_core_instance.public_vm.public_ip
}

output "private_vm_private_ip" {
    value = data.oci_core_instance.private_vm.private_ip
}

locals {
    public_vm_public_ip = data.oci_core_instance.public_vm.public_ip
    public_vm_private_ip = data.oci_core_instance.public_vm.private_ip
    private_vm_private_ip = data.oci_core_instance.private_vm.private_ip
}


# data "oci_core_instance" "public_vm" {
#     value = [oci_core_instance.public_vm.private_ip, oci_core_instance.public_vm.public_ip]
# }

# output "vm_public_subnet_ip" {
#     value = data.public_vm_ip
# }

# output "image_list" {
# value = data.oci_core_images.demo_vm_images
# }