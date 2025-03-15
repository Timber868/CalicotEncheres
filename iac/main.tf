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

resource "azurerm_service_plan" "app_plan" {
  name                = "plan-calicot-web-dev-21"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"             # Assuming Linux (common), adjust if Windows is required
  sku_name            = "S1"
}

resource "azurerm_linux_web_app" "web_app" {
  name                = "app-calicot-web-dev-21"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.app_plan.id

  site_config {
    always_on = true
    application_stack {
      dotnet_version = "7.0"  # Adjust depending on your application stack (.NET, Node, Java, etc.)
    }
  }

  https_only = true

  app_settings = {
    ImageUrl = "https://stcalicotprod000.blob.core.windows.net/images/"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "autoscale-app-calicot-web-dev-21"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_service_plan.app_plan.id

  profile {
    name = "AutoScaleProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 2
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.app_plan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.app_plan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 40
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT5M"
      }
    }
  }
}
