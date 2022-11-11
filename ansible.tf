resource "local_file" "ansible_ini" {
  content     = templatefile("hosts.tpl", { ip = azurerm_public_ip.gaming.ip_address, user = var.user_name, password = random_password.gaming.result })
  filename = "hosts.ini"
}


