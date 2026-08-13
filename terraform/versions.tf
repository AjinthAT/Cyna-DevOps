terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    # Les deux blocs ci-dessous autorisent `terraform destroy` en environnement
    # de projet étudiant. A retirer avant tout usage en production réelle.
    recovery_service {
      purge_protected_items_from_vault_on_destroy = true
    }
    recovery_services_vaults {
      recover_soft_deleted_backup_protected_vm = true
    }
  }
}
