[![Documentation](https://img.shields.io/badge/Documentation-pgwat.ch-brightgreen)](https://pgwat.ch)
[![License: MIT](https://img.shields.io/badge/License-BSD_3-green.svg)](https://opensource.org/license/bsd-3-clause)
[![Go Build & Test](https://github.com/cybertec-postgresql/pgwatch/actions/workflows/build.yml/badge.svg)](https://github.com/cybertec-postgresql/pgwatch/actions/workflows/build.yml)
[![Coverage Status](https://coveralls.io/repos/github/cybertec-postgresql/pgwatch/badge.svg?branch=master&service=github)](https://coveralls.io/github/cybertec-postgresql/pgwatch?branch=master)


# pgWatch-Helm-Chart
This Helm chart allows you to set up the pgWatch stack using helm in containers or distributions such as Openshift.
Note: This Helm chart is developed and tested primarily for Openshift.

## Quick Start
To use the Helm-Charts, you can either patch the repo onto your local system or install and update it directly using the Helm repository.
In either case, please familiarise yourself with the relevant values files before use and create a custom variant to set up pgWatch according to your preferences in your environment.

### Helm-Repository
```sh
# Add Helm-Repo
helm repo add pgwatch https://cybertec-postgresql.github.io/pgwatch-charts
helm repo update

# Install helm-Chart
helm install pgwatch pgwatch/pgwatch --values custom-values.yaml

# Upgrade helm-Chart
helm upgrade pgwatch pgwatch/pgwatch --values custom-values.yaml
```

### git clone
```sh
git clone https://github.com/cybertec-postgresql/pgwatch-charts.git
cd pgwatch-chart/helm/pgwatch


# Install helm-Chart
helm install pgwatch -n pgwatch -f custom-values.yaml .

# Upgrade Helm-Chart
helm upgrade pgwatch -n pgwatch -f custom-values.yaml .

```

## customisation
The Helm chart currently supports PostgreSQL and Prometheus as a sink. This can be controlled via the [values](https://github.com/cybertec-postgresql/pgwatch-charts/blob/pgwatch-3-helm-chart/helm/pgwatch/values.yaml) file.
- PostgreSQL
  -  Use an existing configuration and metric database
  -  Create a new PostgreSQL-Instance in the same namespace
- Prometheus
  - Use an existing Prometheus as Sink (enables Sink-Connect on Port 9188)
  - Create a new Prometheus-Instance in the same namespace
- Grafana
  - Deploy Grafana with the dashboards for PostgreSQL as a sink


## Limitation
Please note that the Grafana dashboard was developed for use with PostgreSQL as a sink. If you decide to use Prometheus as a sink, you will need to build your own dashboards and configure Prometheus as a data source in Grafana yourself. If you want to use your own systems behind Prometheus, you can use Yaml to easily prevent Grafana from being deployed.

---

## Helm Dependencies

Both subcharts are **opt-in** and disabled by default. Run `helm dependency update helm/pgwatch` before installing or upgrading.

### TimescaleDB (`timescaledb.enabled: true`)

Replaces the built-in PostgreSQL StatefulSet with a TimescaleDB instance.
Chart: `cloudpirates/timescaledb` `0.10.4` — [ArtifactHub](https://artifacthub.io/packages/helm/cloudpirates-timescaledb/timescaledb)

```yaml
timescaledb:
  enabled: true
  image:
    tag: "2.26.2-pg18"        # PostgreSQL / TimescaleDB version
  auth:
    postgresPassword: ""       # random if empty
    existingSecret: ""         # takes precedence over postgresPassword
  persistence:
    size: 10Gi
    storageClass: ""           # cluster default when empty
```

### Grafana subchart (`pgwatch.grafana.useSubchart: true`)

Replaces the custom Grafana Deployment. Dashboards and datasources are auto-provisioned via the k8s-sidecar by watching labelled ConfigMaps — no pod restart needed.
Chart: `grafana-community/grafana` `10.5.15` — [GitHub](https://github.com/grafana-community/helm-charts/tree/main/charts/grafana)

```yaml
pgwatch:
  grafana:
    useSubchart: true

grafana:
  sidecar:
    dashboards:
      enabled: true
      label: grafana_dashboard   # ConfigMap label key for dashboards
    datasources:
      enabled: true
      label: grafana_datasource  # ConfigMap label key for datasources
  grafana.ini:
    auth.anonymous:
      enabled: true
      org_role: Admin
    dashboards:
      default_home_dashboard_path: /tmp/dashboards/postgresql/1-global-db-overview.json
```

> When `useSubchart: false` (default), the built-in Grafana Deployment is used and the `pgwatch.grafana.*` component settings apply instead.
