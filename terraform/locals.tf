# `var.environment` était déclarée (variables.tf) mais jamais utilisée dans le
# reste du module : les ressources créées avec `terraform.tfvars.example`
# portaient toutes le même jeu de tags quel que soit l'environnement visé.
# Ce fichier corrige ce point et sert de base au support multi-environnement
# (voir terraform/environments/*.tfvars et README.md, section "Multi-environnement") :
# chaque ressource est désormais taguée avec son environnement réel.
locals {
  common_tags = merge(
    var.tags,
    {
      environnement = var.environment
    }
  )
}
