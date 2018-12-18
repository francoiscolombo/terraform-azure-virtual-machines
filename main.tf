data "template_file" "init-script" {

  count  = "${length(var.servers)}"

  template = "${file("${path.module}/templates/init.yaml")}"

}

data "template_file" "shell-script" {

  count  = "${length(var.servers)}"

  template = "${file("${path.module}/templates/init.sh")}"

  vars {
    admin = "${var.admin_username}"
  }

}

data "template_cloudinit_config" "cloud-init" {

  count  = "${length(var.servers)}"

  gzip = false
  base64_encode = false

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = "${element(data.template_file.init-script.*.rendered, count.index)}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${element(data.template_file.shell-script.*.rendered, count.index)}"
  }

}

resource "azurerm_public_ip" "pip" {

  count = "${length(var.servers)}"

  name                         = "${lookup(var.servers[count.index], "pip_name")}"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "${lookup(var.servers[count.index], "cname")}"

  tags {
    environment="${var.environment}"
  }

}

resource "azurerm_network_security_group" "nsg" {

  count = "${length(var.servers)}"

  name                = "${var.name_prefix}-nsg-${lookup(var.servers[count.index], "name")}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group}"

  security_rule {
    name                        = "${var.name_prefix}-rule-in-${lookup(var.servers[count.index], "name_ssh_rule")}"
    priority                    = 110
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_address_prefix       = "*"
    source_port_range           = "*"
    destination_address_prefix  = "*"
    destination_port_range      = "22"
  }

  security_rule {
    name                        = "${var.name_prefix}-rule-in-${lookup(var.servers[count.index], "name_https_rule")}"
    priority                    = 120
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_address_prefix       = "*"
    source_port_range           = "*"
    destination_address_prefix  = "*"
    destination_port_range      = "443"
  }

  security_rule {
    name                        = "${var.name_prefix}-rule-in-${lookup(var.servers[count.index], "name_http_rule")}"
    priority                    = 130
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_address_prefix       = "*"
    source_port_range           = "*"
    destination_address_prefix  = "*"
    destination_port_range      = "80"
  }

  security_rule {
    name                        = "${var.name_prefix}-rule-in-${lookup(var.servers[count.index], "name_http2_rule")}"
    priority                    = 140
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_address_prefix       = "*"
    source_port_range           = "*"
    destination_address_prefix  = "*"
    destination_port_range      = "8071"
  }

  tags {
    environment="${var.environment}"
  }

}

resource "azurerm_network_interface" "nic" {

  count = "${length(var.servers)}"

  name  = "${var.name_prefix}-nic-${lookup(var.servers[count.index], "name")}"

  location                  = "${var.location}"
  resource_group_name       = "${var.resource_group}"
  network_security_group_id = "${element(azurerm_network_security_group.nsg.*.id, count.index)}"

  ip_configuration {
    name                          = "${var.name_prefix}ipconfig${lookup(var.servers[count.index], "ipconfig")}"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${lookup(var.servers[count.index], "private_ip")}"
    public_ip_address_id          = "${element(azurerm_public_ip.pip.*.id, count.index)}"
  }

  tags {
    environment = "${var.environment}"
  }

}

resource "azurerm_virtual_machine" "vm" {

  count = "${length(var.servers)}"

  name                  = "${var.name_prefix}-${lookup(var.servers[count.index], "name")}"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group}"
  vm_size               = "${lookup(var.servers[count.index], "vmsize")}"
  network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }

  storage_os_disk {
    name          = "${var.name_prefix}-osdisk-${lookup(var.servers[count.index], "name")}"
    vhd_uri       = "${var.blob_connection_string}/${var.name_prefix}-osdisk-${lookup(var.servers[count.index], "name")}.vhd"
    disk_size_gb  = "${lookup(var.servers[count.index], "disksize")}"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${lookup(var.servers[count.index], "cname")}"
    admin_username = "${var.admin_username}"
    custom_data    = "${element(data.template_cloudinit_config.cloud-init.*.rendered, count.index)}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys = [{
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${var.ssh_public_key}"
    }]
  }
  provisioner "remote-exec" {

    inline = [ "echo 'SSH is ready to accept connections...'" ]

    connection {
      type        = "ssh"
      user        = "${var.admin_username}"
      private_key = "${file(var.ssh_key_private)}"
      agent       = "false"
    }

  }

  tags {
    environment="${var.environment}"
  }

}

resource "null_resource" "playbook" {

  provisioner "local-exec" {

    command = "echo 'Now, you can execute this command: ansible-playbook ${var.ansible_playbook} -i ${var.ansible_platform} -u ${var.admin_username} --private-key ${var.ssh_key_private}'" 

  }

  depends_on = ["azurerm_virtual_machine.vm"]

}

# export ANSIBLE_HOST_KEY_CHECKING=False