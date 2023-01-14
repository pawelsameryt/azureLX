output "publicIP" {
    value = azurerm_public_ip.windows-vm-ip.ip_address
}
