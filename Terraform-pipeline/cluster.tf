variable "subscription_id" {
    type = string
    default = "3df0a617-8449-447a-b3b6-4da9b2d1e787"
    description = "Azure subscription id"
}

variable "client_id" {
    type = string
    default = "b50544d3-2061-45dd-b701-09bc4cdacd84"
    description = "Azure client id"
}

variable "client_secret" {
    type = string
    default = "3ERDaeksisjsaLD6lQM9G~01.gGx2_EfKc"
    description = "Azure client secret"
}

variable "tenant_id" {
    type = string
    default = "98a88ccb-a76c-41ea-ad44-1354bd5a4e43"
    description = "Azure tenant id"
}

# variable "ssh_public_key" {
#   default = "~/.ssh/akskey.pub"
#   description = "This variable defines the SSH Public Key for Linux k8s Worker nodes"  
# }

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
  #   backend "azurerm" {
  #   resource_group_name  = "test-rg"
  #   storage_account_name = "devstorage009"
  #   container_name       = "azuretfstate"
  #   key                  = "dev.azuretfstate"

  #   access_key = "/qH2z0Fag3xPgLl6HVM88yOXF19DmGP38FrdKIS3BqqtjSIkj2zs+iZGYVfm/9p0aiweRtU5iyt2k36aibV4zQ=="
  # }  
}
provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "bsrsg" {
  name = "bookstore-rg"
  location = "eastus"
}

resource "azurerm_log_analytics_workspace" "cluster-logs" {
  name                = "bookstore-logs"
  location            = azurerm_resource_group.bsrsg.location
  resource_group_name = azurerm_resource_group.bsrsg.name
  retention_in_days   = 30
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "bookstore-cluster"
  location            = azurerm_resource_group.bsrsg.location
  resource_group_name = azurerm_resource_group.bsrsg.name
  dns_prefix          = "bsrsg-cluster"

  default_node_pool {
    name                 = "systempool"
    vm_size              = "Standard_DS2_v2"
    availability_zones   = [1, 2, 3]
    enable_auto_scaling  = true
    max_count            = 3
    min_count            = 1
    os_disk_size_gb      = 30
    type                 = "VirtualMachineScaleSets"
    node_labels = {
      "nodepool-type"    = "system"
      "environment"      = "dev"
      "nodepoolos"       = "linux"
      "app"              = "system-apps" 
    } 
   tags = {
      "nodepool-type"    = "system"
      "environment"      = "dev"
      "nodepoolos"       = "linux"
      "app"              = "system-apps" 
   } 
  }

# Identity (System Assigned or Service Principal)
  identity {
    type = "SystemAssigned"
  }

# Add On Profiles
  addon_profile {
    azure_policy {enabled =  true}
    oms_agent {
      enabled =  true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.cluster-logs.id
    }
  }


# # Windows Profile
#   windows_profile {
#     admin_username = "azureadmin"
#     admin_password = "azureadmin@1234"
#   }

# # Linux Profile
#   linux_profile {
#     admin_username = "ubuntu"
#     ssh_key {
#       # key_data = file(var.ssh_public_key)
#     }
#   }

# Network Profile
  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "Standard"
  }

  tags = {
    Environment = "dev"
  }
}
