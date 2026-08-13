# Chart Helm — saas-app

## Contexte

Ce chart cible le cluster k3s hébergé sur `SAAS-GE-01` (4 VM imbriquées par
virtualisation nichée, cf. CDC section 12.2 et plan d'adressage section
10.5.1). Il répond à l'exigence du sujet CYNA (section Scripting,
« Déploiement des conteneurs avec Docker/Kubernetes ») :

- déploiement automatisé des conteneurs sur Kubernetes via Helm (`helm
  upgrade --install`) plutôt qu'un déploiement manuel de manifestes ;
- scaling automatique des conteneurs en fonction de la charge
  (`templates/hpa.yaml`, un `HorizontalPodAutoscaler` sur CPU et mémoire) ;
- configuration paramétrable par environnement via `values.yaml` (voir plus
  bas, section « Multi-environnement »).

## Ce que ce chart ne fait pas (limite assumée)

L'image de conteneur du **front-end applicatif SaaS CYNA lui-même** (le
code métier de la plateforme) n'est pas publiée dans un registre accessible
depuis ce dépôt DevOps : le dépôt applicatif est distinct de ce dépôt
d'infrastructure. `values.yaml` utilise donc une image de substitution
(`nginx:1.27-alpine`) uniquement pour démontrer le fonctionnement du chart
(déploiement, service, autoscaling) — c'est le même principe que pour
l'API interne (`APP-BACKEND-01`) et la base de données applicative,
documentées dans le CDC (section 12.2) comme « cible à préciser » plutôt que
comme spécifiées dans le détail à ce stade du projet.

Pour un déploiement réel, remplacer dans `values.yaml` :

```yaml
image:
  repository: <registre>/<image-saas-cyna>
  tag: "<version>"
```

## Prérequis

- Un cluster k3s fonctionnel sur `SAAS-GE-01` (avec `metrics-server`, inclus
  par défaut dans une installation k3s standard — nécessaire au HPA) ;
- Helm ≥ 3.10 ;
- `kubectl` configuré avec le kubeconfig du cluster k3s cible.

## Utilisation

```bash
cd helm/saas-app

# Lint et rendu local avant tout déploiement (aucun cluster requis) :
helm lint .
helm template saas-app . -f values.yaml

# Déploiement / mise à jour :
helm upgrade --install saas-app . -n saas --create-namespace \
  -f values.yaml
```

## Multi-environnement

Comme pour le module Terraform (`terraform/environments/`), les valeurs
spécifiques à un environnement peuvent être surchargées via un fichier
`-f` dédié plutôt que de dupliquer le chart, par exemple :

```bash
# values-dev.yaml : moins de replicas, limites CPU/mémoire réduites
helm upgrade --install saas-app . -n saas-dev --create-namespace \
  -f values.yaml -f values-dev.yaml
```

(Les fichiers `values-<env>.yaml` ne sont pas fournis ici tant que l'image
applicative réelle n'est pas connue — le mécanisme de surcharge Helm
(`-f` multiples, dernier fichier prioritaire) est démontré par le chart et
peut être répliqué dès que ces valeurs seront disponibles.)

## Vérifier l'autoscaling

```bash
kubectl get hpa -n saas saas-app
# COLUMNS: NAME       REFERENCE             TARGETS   MINPODS   MAXPODS   REPLICAS
```

Générer de la charge sur le service pour observer une augmentation du
nombre de réplicas (au-delà de `minReplicas`, jusqu'à `maxReplicas`, cf.
`values.yaml`) est la méthode recommandée pour démontrer l'autoscaling en
soutenance.
