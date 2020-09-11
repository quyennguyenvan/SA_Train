# this template applied for azure cloud account o

provider "azurerm" {
  version = "=2.20.0"
  features {}
  subscription_id = "f4dbaf23-9ecc-4e0b-ab08-f49e7e448573"
  tenant_id       = "f01e930a-b52e-42b1-b70f-a8882b5d043b"
}


#create resource group

resource "azurerm_resource_group" "devops" {
    name = "devops-team"
    location = "West Europe"
}