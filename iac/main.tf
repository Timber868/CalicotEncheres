###################################
#  1. Terraform & Azure Provider  #
###################################
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type    = string
  default = "rg-calicot-web-dev-21"
}

variable "region" {
  type    = string
  default = "canadacentral"
}

variable "code" {
  type    = string
  default = "21" 
}

##############################
#  3. (Optional) Resource Group
##############################
# If you NEED to create the RG, uncomment this block:
#
# resource "azurerm_resource_group" "rg" {
#   name     = var.resource_group_name
#   location = var.region
# }
#
# If your RG is already created by your teacher or Azure admin, 
# just reference its name in the resources below.

###############################################
#  4. Virtual Network with Two Subnets
###############################################
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-dev-calicot-cc-${var.code}"
  location            = var.region
  # If you have the RG from above, use:
  # resource_group_name = azurerm_resource_group.rg.name
  #
  # If your RG already exists, do:
  resource_group_name = var.resource_group_name

  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "subnet_web" {
  name                 = "snet-dev-web-cc-${var.code}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "subnet_db" {
  name                 = "snet-dev-db-cc-${var.code}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.2.0/24"]
}
