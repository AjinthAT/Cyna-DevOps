# Environnements Terraform

Un fichier `-var-file` par environnement (dev/staging/prod), avec des noms de
ressources distincts (contrainte Azure : `key_vault_name`,
`storage_account_name`, etc. doivent être uniques au niveau mondial, et deux
environnements ne doivent pas pointer vers la même ressource).

Fournis en `.tfvars.example` : le `.gitignore` racine du dépôt exclut tous
les `*.tfvars`. Copier avant utilisation :

```bash
cp environments/dev.tfvars.example environments/dev.tfvars
```

Chaque environnement doit aussi utiliser un état Terraform **séparé** (pas
de backend distant configuré, cf. `../README.md`, section
« Multi-environnement ») :

```bash
terraform plan  -var-file=environments/dev.tfvars -state=environments/dev.tfstate
terraform apply -var-file=environments/dev.tfvars -state=environments/dev.tfstate
```

Voir `../README.md` pour le détail (isolation des états, alternative avec un
backend `azurerm` distant, rollback).
