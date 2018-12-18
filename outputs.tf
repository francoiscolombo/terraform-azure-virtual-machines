output "vm_name" {
  value = "${azurerm_virtual_machine.vm.*.name}"
}

output "vm_id" {
  value = "${azurerm_virtual_machine.vm.*.id}"
}

output "public_fqdn" {
  value = "${azurerm_public_ip.pip.*.fqdn}"
}

output "public_ip_id" {
  value = "${azurerm_public_ip.pip.*.id}"
}
