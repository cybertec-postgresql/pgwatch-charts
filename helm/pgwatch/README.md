[![Documentation](https://img.shields.io/badge/Documentation-pgwat.ch-brightgreen)](https://pgwat.ch)
[![License: MIT](https://img.shields.io/badge/License-BSD_3-green.svg)](https://opensource.org/license/bsd-3-clause)
[![Go Build & Test](https://github.com/cybertec-postgresql/pgwatch/actions/workflows/build.yml/badge.svg)](https://github.com/cybertec-postgresql/pgwatch/actions/workflows/build.yml)
[![Coverage Status](https://coveralls.io/repos/github/cybertec-postgresql/pgwatch/badge.svg?branch=master&service=github)](https://coveralls.io/github/cybertec-postgresql/pgwatch?branch=master)

# pgwatch Helm Chart

This Helm chart allows you to set up the pgwatch stack using Helm in containers or distributions such as OpenShift or Kubernetes.

## Quick Start

To use the Helm-Charts, you can either patch the repo onto your local system or install and update it directly using the Helm repository.
In either case, please familiarise yourself with the relevant values files before use and create a custom variant to set up pgWatch according to your preferences in your environment.

### Helm-Repository

```sh
# Add Helm-Repo
helm repo add pgwatch https://cybertec-postgresql.github.io/pgwatch-charts
helm repo update

# Install helm chart
helm install pgwatch pgwatch/pgwatch -n pgwatch --create-namespace --values custom-values.yaml

# Upgrade helm chart
helm upgrade pgwatch pgwatch/pgwatch -n pgwatch --values custom-values.yaml
```

### git clone

```sh
git clone https://github.com/cybertec-postgresql/pgwatch-charts.git
cd pgwatch-charts/helm/pgwatch

# Optional: only needed when using the TimescaleDB or Grafana subcharts
helm dependency update .

# Install helm chart
helm install pgwatch -n pgwatch --create-namespace -f custom-values.yaml .

# Upgrade helm chart
helm upgrade pgwatch -n pgwatch -f custom-values.yaml .

```

## Customisation

The Helm chart currently supports PostgreSQL and Prometheus as a sink. This can be controlled via the [values](https://github.com/cybertec-postgresql/pgwatch-charts/blob/pgwatch-3-helm-chart/helm/pgwatch/values.yaml) file.

- PostgreSQL
  - Use an existing configuration and metric database
  - Create a new PostgreSQL instance in the same namespace
  - Optionally replace with **TimescaleDB** (see [Helm Dependencies](#helm-dependencies))
- Prometheus
  - Use an existing Prometheus as sink (enables sink on port 9188)
  - Create a new Prometheus instance in the same namespace
- Grafana
  - Deploy Grafana with dashboards for both PostgreSQL and Prometheus sinks
  - Optionally use the official Grafana Helm subchart (see [Helm Dependencies](#helm-dependencies))

## Advanced Customisation

Every component (`pgwatch`, `postgres`, `prometheus`, `grafana`) exposes two additional extension points:

- **`env`** - inject plain key/value environment variables directly into the container:

  ```yaml
  pgwatch:
    env:
      PW_LOGLEVEL: "debug"
  grafana:
    env:
      GF_SERVER_ROOT_URL: "https://grafana.example.com"
  ```

- **`envFrom`** - source environment variables from existing ConfigMaps or Secrets:

  ```yaml
  pgwatch:
    envFrom:
      - secretRef:
          name: my-pgwatch-secret
  ```

**Security contexts** can be tuned at two levels:

- **Global baseline** (`securityContext.enabled: true`) - applies a shared pod- and container-level security context to all components. Per-component values are merged on top and always win.
- **Per-component overrides** - each component exposes its own `securityContext.pod` / `securityContext.container` keys, applied independently when the global baseline is disabled (the default).

  ```yaml
  # Global baseline (opt-in)
  securityContext:
    enabled: true
    pod:
      runAsNonRoot: true
      runAsUser: 1000

  # Per-component override (always available)
  pgwatch:
    securityContext:
      pod:
        runAsUser: 1001
      container:
        allowPrivilegeEscalation: false
  ```

> See the [Local development (Minikube)](#local-development-minikube) section for a concrete example of overriding security contexts when `fsGroup` is not applied by the cluster.

**`extraDeploy`** allows you to deploy arbitrary Kubernetes resources alongside the chart (e.g. `ServiceMonitor`, additional `ConfigMap`, CRDs). Each entry is rendered via `tpl`, so Helm template expressions are supported.

> !! No validation is performed on `extraDeploy` entries. Users are responsible for the correctness of the resources they provide.

```yaml
extraDeploy:
  - apiVersion: monitoring.coreos.com/v1
    kind: ServiceMonitor
    metadata:
      name: pgwatch
    spec:
      selector:
        matchLabels:
          app: pgwatch
      endpoints:
        - port: metrics
```

---

## Helm Dependencies

Both subcharts are **opt-in** and disabled by default. Run `helm dependency update helm/pgwatch` before installing or upgrading.

### TimescaleDB (`timescaledb.enabled: true`)

Replaces the built-in PostgreSQL StatefulSet with a TimescaleDB instance.
Chart: `cloudpirates/timescaledb` `0.10.4` - [ArtifactHub](https://artifacthub.io/packages/helm/cloudpirates-timescaledb/timescaledb)

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

Replaces the custom Grafana Deployment. Dashboards and datasources are auto-provisioned via the k8s-sidecar by watching labelled ConfigMaps - no pod restart needed.
Chart: `grafana-community/grafana` `10.5.15` - [GitHub](https://github.com/grafana-community/helm-charts/tree/main/charts/grafana)

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

---

## Local development (Minikube)

The `postgres` and `timescaledb` images are designed to start as root, set up the data directory, and then drop to the postgres user (uid 999). The chart defaults leave the security context empty so clusters that properly apply `fsGroup` volume ownership can run those images as non-root.

On **Minikube**, `fsGroup` may not be applied before the container starts, causing a `Permission denied` error when the image tries to create the data directory. Override the security context in your values file to let the images handle their own permissions:

```yaml
# pgwatch.postgres
pgwatch:
  postgres:
    securityContext:
      pod:
        runAsUser: 0
        runAsGroup: 0
        fsGroup: 999
        runAsNonRoot: false
      container:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: false
        capabilities:
          drop: []

# timescaledb subchart (when timescaledb.enabled: true)
timescaledb:
  podSecurityContext:
    runAsUser: 0
    runAsGroup: 0
    fsGroup: 999
  containerSecurityContext:
    runAsUser: 0
    runAsGroup: 0
    runAsNonRoot: false
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: false
    capabilities:
      drop: []
```
