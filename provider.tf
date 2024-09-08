terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.1.0"
    }
  }
}

provider "azurerm" {
   subscription_id = "c3bbc65c-c5e3-42e0-a2c7-f03a690e9c97"
   features {
   }
   
}