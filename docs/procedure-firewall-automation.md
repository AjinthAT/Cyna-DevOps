# Automatisation des règles firewall (Zero Trust) — Sophos

## Objectif

Répond à l'exigence du sujet CYNA (Livrables - Architecture Cloud Hybride et
Sécurité, « Automatisation des règles de sécurité avec Ansible ») : des
scripts capables d'appliquer des politiques de sécurité Zero Trust sur les
pare-feux et de les mettre à jour dynamiquement selon les besoins du réseau.

Le firewall retenu dans le CDC (section 2, choix techniques) est Sophos XGS
(2 unités, Genève et Paris — cf. `accesSophos` dans le CDC, section 10.5.4).
Ce document couvre l'automatisation de sa configuration de règles via
`ansible/playbooks/deploy-firewall-rules.yml`.

## Principe : matrice de flux déclarative

La liste des flux autorisés vit dans deux fichiers, un par site :

- `ansible/playbooks/vars/firewall-zero-trust-geneve.yml`
- `ansible/playbooks/vars/firewall-zero-trust-paris.yml`

Chaque entrée décrit un flux (zone source, zone destination, services,
description, journalisation) et référence l'exigence du CDC qu'elle couvre
(SEC-FW-01 à SEC-FW-05, section 11.2). C'est la **source de vérité unique** :
mettre à jour une politique Zero Trust signifie éditer cette liste, pas se
connecter à l'interface web de Sophos.

Posture Zero Trust : SFOS (Sophos Firewall OS) applique un **déni implicite
entre zones de sécurité** tant qu'aucune règle « Accept » ne l'autorise
explicitement. Chaque ligne de la matrice est donc une exception motivée
qui vient s'ajouter à un refus par défaut — pas une liste de blocages à
ajouter en plus d'un « tout autorisé » par défaut. Toute communication
inter-VLAN non listée reste bloquée (SEC-FW-01).

## Mettre à jour une règle

```bash
# 1. Éditer la matrice de flux du site concerné
vim ansible/playbooks/vars/firewall-zero-trust-geneve.yml

# 2. Rejouer le playbook : les règles nouvelles sont créées, les règles
#    existantes du même nom sont mises à jour (idempotent), les règles
#    retirées du fichier ne sont PAS supprimées automatiquement côté
#    Sophos (limite assumée, voir plus bas)
source .env.local
ansible-playbook -i ansible/inventory.ini ansible/playbooks/deploy-firewall-rules.yml
```

## Prérequis

- **Zones Sophos déjà créées**, avec les mêmes noms que la colonne « Nom »
  des tableaux VLAN du CDC (sections 10.2 et 10.3) : `MGMT-GE`, `USERS-GE`,
  `SERVERS-GE`, `DMZ-SAAS`, `BACKEND-APP`, `SOC-MONITORING`, `BACKUP-PRA`,
  `WIFI-CORP`, `WIFI-GUEST` côté Genève ; `ADMIN-PARIS`, `USERS-PARIS`,
  `GUEST-PARIS` côté Paris. La création des zones elles-mêmes (association
  zone ↔ VLAN/interface) est une opération réseau préalable, hors périmètre
  de ce playbook (elle ne se fait pas via l'API `FirewallRule`).
- **Objets Service personnalisés déjà créés** (Objects > Services côté
  Sophos) : `AD-DS` (DNS/Kerberos/LDAP/SMB), `MONITORING` (Node Exporter,
  Blackbox, agents Wazuh), `SAAS-API` (flux SaaS ↔ backend applicatif — port
  exact à ajuster une fois l'API interne formalisée, cf. CDC section 12.2).
  Les services standards (`HTTPS`, `HTTP`, `DNS`, `SSH`, `RDP`) sont fournis
  nativement par Sophos.
- **Un compte API dédié à l'automatisation**, distinct du compte
  administrateur utilisé pour la configuration manuelle — idéalement un
  profil RBAC Sophos limité à la gestion des objets `FirewallRule` plutôt
  qu'un accès administrateur complet. C'est la même logique Zero Trust
  appliquée à l'automatisation elle-même : le compte qui pousse les règles
  ne doit pas avoir plus de droits que nécessaire pour le faire.
- **Identifiants en variables d'environnement**, jamais en dur dans le
  dépôt : copier `.env.example` en `.env.local`, renseigner
  `SOPHOS_GENEVE_API_USER`/`SOPHOS_GENEVE_API_PASSWORD` et les équivalents
  Paris, puis `source .env.local` avant de lancer le playbook.

## Comment ça marche

1. Le playbook lit `firewall_rules` depuis le fichier de variables du site
   (`include_vars`).
2. Il interroge l'API Sophos (`Get><FirewallRule>`) pour connaître les règles
   déjà présentes, afin de décider `add` (nouvelle règle) ou `update` (règle
   existante du même nom) pour chaque entrée — c'est ce qui rend le
   playbook rejouable sans dupliquer les règles.
3. Il pousse chaque règle via l'API XML de Sophos (`POST
   /webconsole/APIController`, champ `reqxml`, cf.
   `ansible/playbooks/templates/sophos-firewall-rule.xml.j2`).
4. Il relit la configuration et vérifie que chaque règle déclarée apparaît
   bien dans la réponse — test de validation post-déploiement, sur le même
   principe que `deploy-monitoring.yml` et `deploy-node-exporter.yml`
   (on ne se fie pas à un code HTTP 200, qui n'indique pas forcément un
   succès côté Sophos, mais on vérifie l'état réel après coup).

## Limites assumées

- **Pas de suppression automatique** : retirer une ligne d'un fichier
  `firewall-zero-trust-*.yml` n'entraîne pas la suppression de la règle
  correspondante côté Sophos (seuls `add`/`update` sont implémentés). Une
  règle obsolète doit être désactivée ou supprimée manuellement, ou via une
  évolution future du playbook (opération `remove` de l'API Sophos).
- **Non testé en conditions réelles** : ce playbook a été relu et son XML
  vérifié manuellement contre le schéma documenté par Sophos pour
  `APIController`, mais n'a pas pu être exécuté contre un vrai firewall
  Sophos dans cet environnement de rédaction (pas d'accès réseau à un
  firewall Sophos depuis là où ce dépôt a été préparé). À valider sur la
  maquette GNS3 avant la démonstration finale, idéalement d'abord avec un
  sous-ensemble réduit de règles.
- **Pas de gestion des règles temporaires** (SEC-FW-02, « les règles
  temporaires doivent être supprimées après test ») : ce playbook gère la
  matrice de flux cible stable, pas le cycle de vie de règles de test
  ponctuelles créées manuellement pendant le déploiement — celles-ci
  restent à retirer manuellement, comme documenté dans le CDC.
