##################   Creation Groupe de resource DEV1 - ########################

resource "azurerm_resource_group" "rg-dev1" {
  location = var.resource_group_location
  name     = var.resource_group_name
}
##################   Creation virtual network avec NSG - ########################
#NSG
resource "azurerm_network_security_group" "nsg-dev1" {
  name                = "nsg-dev1"
  location            = azurerm_resource_group.rg-dev1.location
  resource_group_name = azurerm_resource_group.rg-dev1.name
}
#Virtual network
resource "azurerm_virtual_network" "vinet-dev1" {
  name                = var.virtual_network_name
  location            = azurerm_resource_group.rg-dev1.location
  resource_group_name = azurerm_resource_group.rg-dev1.name
  address_space       = ["10.0.0.0/24"]
  #dns_servers         = ["10.0.0.4", "10.0.0.5"]

}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.rg-dev1.name
  virtual_network_name = azurerm_virtual_network.vinet-dev1.name
  address_prefixes     = ["10.0.1.0/27"]
}

resource "azurerm_network_interface" "nic-dev1" {
  name                = "nic-dev1"
  location            = azurerm_resource_group.rg-dev1.location
  resource_group_name = azurerm_resource_group.rg-dev1.name

  ip_configuration {
    name                          = "configurationdev1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

##################   Creation Virtual machine DEV1 ########################
resource "azurerm_managed_disk" "osdisk" {
  create_option         = "FromImage"
}

resource "azurerm_virtual_machine" "vm-dev1" {
  name                  = var.virtual_machine_name
  location              = azurerm_resource_group.rg-dev1.location
  resource_group_name   = azurerm_resource_group.rg-dev1.name
  size                  = var.size_vm
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic-dev1.id]

os_disk {
    name                 = "osdisk1"
    caching              = "ReadWrite"
    create_option        = "FromImage"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher    = "MicrosoftWindowsServer"
    offer        = "WindowsServer"
    sku          = var.windows_2019_sku
    version      = "latest"
  }

  tags = {
    environment = "dev1"
  }
}

##################   Creation Bases de données PostgreSQL ########################
#Sql Server
resource "azurerm_postgresql_server" "PostgreSQlServerDev1" {
  name                = "postgresql-dev-1"
  location            = azurerm_resource_group.rg-dev1.location
  resource_group_name = azurerm_resource_group.rg-dev1.name

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7 
  geo_redundant_backup_enabled = true
  auto_grow_enabled            = true

  administrator_login          = "psqladmin"
  administrator_login_password = "H@Sh1CoR3!"
  version                      = "9.5"
  ssl_enforcement_enabled      = true
}

#Database
resource "azurerm_postgresql_database" "postgresqlDataDev1" {
  name                = "sqldev1"
  resource_group_name = azurerm_resource_group.rg-dev1
  server_name         = azurerm_postgresql_server.PostgreSQlServerDev1.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}