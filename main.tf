#################  Création du groupe de resource RgCommun ###########################

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = var.resource_group_name
}


##################  Creation Virtuel Network - Vnet Hub - #########################

resource "azurerm_virtual_network" "hub-vnet" {
    name                = var.azurerm_virtual_network_name
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    address_space       = ["10.0.0.0/16"]

    tags = {
    environment = "hub"
    }

 #################  Création des Subnet Frontend , Backend ##########################    
}

resource "azurerm_subnet" "frontendSubnet" {
    name                 = "FrontendSubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.hub-vnet.name
    address_prefixes       = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backendSubnet" {
    name                 = "BackendSubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.hub-vnet.name
    address_prefixes       = ["10.0.2.0/24"]
}

 #################  Création de l'application Gateway  #############################
      # avec un ip public et la configuration de ip (gateway, frontend , backend pool )
      # et la configuration de port frontend et backend et les rule de routage 

resource "azurerm_public_ip" "publicip" {
  name                = "GatewayPublicIPAddress"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_application_gateway" "AppGateway" {
  name                = "app-gateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontendSubnet.id
  }

  frontend_port {
    name = var.frontend_port_name
    port = 80
  }

  frontend_ip_configuration{
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.publicip.id
  }

  backend_address_pool {
    name = var.backend_address_pool_name
  }

  backend_http_settings {
    name                  = var.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = var.listener_name
    frontend_ip_configuration_name = var.frontend_ip_configuration_name
    frontend_port_name             = var.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = var.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = var.listener_name
    backend_address_pool_name  = var.backend_address_pool_name
    backend_http_settings_name = var.http_setting_name
    priority                   = 1
  }
}


##################   Creation VPN Gateway - ########################

resource "azurerm_vpn_gateway" "vpn" {
  name                = "vpn-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  virtual_hub_id      = azurerm_virtual_network.hub-vnet.id 
}


