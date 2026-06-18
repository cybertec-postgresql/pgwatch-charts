# pgwatch Helm Chart

[![Documentation](https://img.shields.io/badge/Documentation-pgwat.ch-brightgreen)](https://pgwat.ch)
[![License: MIT](https://img.shields.io/badge/License-BSD_3-green.svg)](https://opensource.org/license/bsd-3-clause)
[![Go Build & Test](https://github.com/cybertec-postgresql/pgwatch/actions/workflows/build.yml/badge.svg)](https://github.com/cybertec-postgresql/pgwatch/actions/workflows/build.yml)
[![Coverage Status](https://coveralls.io/repos/github/cybertec-postgresql/pgwatch/badge.svg?branch=master&service=github)](https://coveralls.io/github/cybertec-postgresql/pgwatch?branch=master)


This Helm chart installs the pgwatch monitoring stack on Kubernetes or
OpenShift. It can deploy pgwatch together with PostgreSQL, Prometheus, and
Grafana components, and it supports optional TimescaleDB and Grafana subcharts.

## Table of Contents

- [Quick Start](#quick-start)
- [Choose Your Metrics Storage](#choose-your-metrics-storage)
- [Upgrade to Chart 4.x](#upgrade-to-chart-4x)
- [Configuration](#configuration)
  - [Supported components](#supported-components)
  - [Credential Management](#credential-management)
  - [Environment Variables and Config Injection](#environment-variables-and-config-injection)
  - [Security Contexts](#security-contexts)
  - [Extra Resources](#extra-resources)
- [Kubernetes Labels and Selectors](#kubernetes-labels-and-selectors)
- [Helm Dependencies](#helm-dependencies)
- [Local Development](#local-development)
- [Migration Reference](#migration-reference)

## Quick Start

Install the chart either from the Helm repository or from a local clone. In both
cases, review the relevant values in
[`values.yaml`](https://github.com/cybertec-postgresql/pgwatch-charts/blob/pgwatch-3-helm-chart/helm/pgwatch/values.yaml)
and create a `custom-values.yaml` for your environment.

> **Important:** The chart does not ship default passwords. Set the required
> credential values or reference existing Kubernetes Secrets before running
> `helm install`, `helm upgrade`, or `helm template`. See
> [Credential Management](#credential-management).

### Install from the Helm repository

```sh
# Add Helm repository
helm repo add pgwatch https://cybertec-postgresql.github.io/pgwatch-charts
helm repo update

# Install chart
helm install pgwatch pgwatch/pgwatch -n pgwatch --create-namespace --values custom-values.yaml

# Upgrade chart
helm upgrade pgwatch pgwatch/pgwatch -n pgwatch --values custom-values.yaml
```

### Install from a git clone

```sh
git clone https://github.com/cybertec-postgresql/pgwatch-charts.git
cd pgwatch-charts/helm/pgwatch

# Optional: only needed when using the TimescaleDB or Grafana subcharts
helm dependency update .

# Install chart
helm install pgwatch -n pgwatch --create-namespace -f custom-values.yaml .

# Upgrade chart
helm upgrade pgwatch -n pgwatch -f custom-values.yaml .
```

## Choose Your Metrics Storage

The chart supports PostgreSQL and Prometheus as metrics storage backends. You can
use one or both simultaneously.

### PostgreSQL sink

- **Built-in PostgreSQL**: quickest start; the chart creates and manages a
  PostgreSQL instance in the same namespace. See
  [Credential Management](#credential-management).
- **External PostgreSQL**: use this when the metrics database is already managed
  outside this chart. Configure `pgwatch.postgres.useExistingDatabase.*` and
  application credentials. See [Credential Management](#credential-management).
- **TimescaleDB subchart**: use this when you want TimescaleDB instead of the
  built-in PostgreSQL StatefulSet. See [Helm Dependencies](#helm-dependencies).

### Prometheus sink

- **Built-in Prometheus**: the chart can create and manage a Prometheus instance
  in the same namespace. Configure via `pgwatch.prometheus.newPrometheus.*`.
- **External Prometheus**: planned (not yet implemented).

See [Supported components](#supported-components) for detailed configuration options.

## Upgrade to Chart 4.x

Read this section before upgrading an existing installation to chart 4.x.

### Breaking change: selector labels changed

Chart 4.0.0 changes the selectors of the built-in `Deployment` and
`StatefulSet` resources to use the standardized `app.kubernetes.io/*` labels.
Kubernetes treats these selectors as immutable, so upgrades from chart versions
that used the previous selector labels may fail with:

```text
field is immutable: spec.selector
```

Affected built-in workloads are:

- `Deployment/pgwatch`
- `Deployment/grafana` when `pgwatch.grafana.useSubchart=false`
- `Deployment/pgwatch-prometheus` when `pgwatch.prometheus.newPrometheus.createPrometheus=true`
- `StatefulSet/postgres` when using the built-in PostgreSQL database

If an upgrade fails with an immutable selector error, delete the affected
workload object and rerun `helm upgrade`. Do not delete PVCs unless you
intentionally want to remove stored data. For example:

```sh
kubectl delete deployment pgwatch -n pgwatch
kubectl delete deployment grafana -n pgwatch
kubectl delete deployment pgwatch-prometheus -n pgwatch
kubectl delete statefulset postgres -n pgwatch --cascade=orphan
helm upgrade pgwatch pgwatch/pgwatch -n pgwatch --values custom-values.yaml
```

> **Note on the PostgreSQL StatefulSet:** `--cascade=orphan` prevents the old
> `postgres-0` Pod from being deleted when the StatefulSet is removed. However,
> because the selector labels also changed, the new StatefulSet cannot adopt the
> orphaned Pod — its old labels no longer match the new selector. The StatefulSet
> will be stuck trying to create `postgres-0` while the orphaned Pod is still
> running under that name.
>
> If this happens, delete the orphaned Pod as well. Your data is stored in the
> PVC, not in the Pod, so it is safe:
>
> ```sh
> kubectl delete pod postgres-0 -n pgwatch
> ```
>
> The new StatefulSet will then create a fresh `postgres-0` that attaches to the
> existing PVC and reconnects to your data automatically.

Adjust the commands to match the components enabled in your installation and
the namespace/release name you use.

### Required credential values

Chart 4.0.0 introduces explicit Secret-based credential handling. Chart
versions before this did not have `pgwatch.postgres.credentials` or
`pgwatch.postgres.adminCredentials`, so upgrades with `--reuse-values` can miss
new 4.x defaults and may fail unless you provide the newly required values.

Before installing or upgrading, review
[Mandatory credential values](#mandatory-credential-values). For example, when
using the built-in PostgreSQL database, both the pgwatch application-user
password and the PostgreSQL admin password must be provided:

```sh
helm upgrade pgwatch pgwatch/pgwatch -n pgwatch --values custom-values.yaml \
  --set pgwatch.postgres.credentials.password='change-me-app' \
  --set pgwatch.postgres.adminCredentials.password='change-me-admin'
```

> **Note:** Avoid `--reuse-values` for 3.x -> 4.x upgrades unless the old
> release values have been migrated. Prefer an explicit 4.x values file, or use
> `--reset-values --values custom-values.yaml` to start from the new chart
> defaults.

### Backward-compatible deprecations

Chart 4.0.0 also prefers native YAML booleans (`true` / `false`) and Helm-style
camelCase values. Legacy string booleans (`"true"` / `"false"`) and former
snake_case value keys still work temporarily for backward compatibility and
emit migration warnings during install/upgrade.

See [Migration Reference](#migration-reference) for the current value names and
migration mapping.

## Configuration

### Supported components

The Helm chart currently supports PostgreSQL and Prometheus as a sink. This can be controlled via the [values](https://github.com/cybertec-postgresql/pgwatch-charts/blob/pgwatch-3-helm-chart/helm/pgwatch/values.yaml) file.

- PostgreSQL
  - Use an existing configuration and metric database
  - Create a new PostgreSQL instance in the same namespace
  - Optionally replace with **TimescaleDB** (see [Helm Dependencies](#helm-dependencies))
- Prometheus
  - Create a new Prometheus instance in the same namespace
  - External Prometheus support: planned (not yet implemented)
- Grafana
  - Deploy Grafana with dashboards for both PostgreSQL and Prometheus sinks
  - Optionally use the official Grafana Helm subchart (see [Helm Dependencies](#helm-dependencies))

### Credential Management

[Issue #12](https://github.com/cybertec-postgresql/pgwatch-charts/issues/12) changed credential handling to use Kubernetes Secrets instead of
hardcoded values or plaintext in manifests.

**Deprecation:** `useExistingDatabase.username/password` still work but will emit warnings. They will be removed in a future chart version.

#### Mandatory credential values

The chart does **not** ship default passwords. Depending on the PostgreSQL mode
you use, you must either provide passwords in your values file or reference
existing Kubernetes Secrets. If a required password is missing, `helm install`,
`helm upgrade`, or `helm template` fails with a message such as
`Please set pgwatch.postgres.credentials.password` or
`Please set pgwatch.postgres.adminCredentials.password`.

| Deployment mode | Required values |
| --- | --- |
| Built-in PostgreSQL (`pgwatch.postgres.createMetricDatabase=true`, `timescaledb.enabled=false`) | `pgwatch.postgres.credentials.password` for the pgwatch/Grafana application user, and `pgwatch.postgres.adminCredentials.password` for the `postgres` superuser. Alternatively set `pgwatch.postgres.credentials.existingSecret` and/or `pgwatch.postgres.adminCredentials.existingSecret`. |
| External PostgreSQL (`pgwatch.postgres.createMetricDatabase=false`) | Database connection settings under `pgwatch.postgres.useExistingDatabase.*` plus application-user credentials via `pgwatch.postgres.credentials.password`, `pgwatch.postgres.credentials.existingSecret`, or deprecated `pgwatch.postgres.useExistingDatabase.password`. `pgwatch.postgres.adminCredentials.*` is ignored. |
| TimescaleDB subchart (`timescaledb.enabled=true`) | Application-user credentials via `pgwatch.postgres.credentials.password` or `pgwatch.postgres.credentials.existingSecret`. `pgwatch.postgres.adminCredentials.*` is ignored; configure the TimescaleDB admin password with `timescaledb.auth.*` instead. |

Examples below use placeholder passwords. Replace them before production use.

#### Precedence

For the pgwatch application / Grafana DB user credentials under
`pgwatch.postgres.credentials` the chart uses this order:

1. `credentials.existingSecret` — chart creates no Secret
2. `credentials.username` / `credentials.password` — chart creates Secret
3. DEPRECATED: `useExistingDatabase.username` / `password` — fallback, emits warning

#### Generated Secrets

When not using `existingSecret`, the chart creates these default Secrets from the provided values:

- **`pgwatch-postgresql-secret-pgwatch`** — application user credentials (username, password)
  - Used by db-init-job, pgwatch, and Grafana to connect to the metrics database
- **`pgwatch-postgresql-secret-postgres`** — admin credentials (username: postgres, password)
  - Only created for built-in PostgreSQL (not for TimescaleDB or external databases)

#### 1. Built-in PostgreSQL

```yaml
pgwatch:
  postgres:
    createMetricDatabase: true
    credentials:
      username: pgwatch
      password: change-me-app
    adminCredentials:
      password: change-me-admin  # ignored for TimescaleDB/external
```

#### 2. External PostgreSQL

```yaml
pgwatch:
  postgres:
    createMetricDatabase: false
    useExistingDatabase:
      endpoint: postgresql.local
      port: "5432"
      database: pgwatch_metrics
      sslmode: require
    credentials:
      username: pgwatch_user
      password: change-me
```

#### 3. External PostgreSQL with existing Secret

```yaml
pgwatch:
  postgres:
    createMetricDatabase: false
    useExistingDatabase:
      endpoint: postgresql.local
      port: "5432"
      database: pgwatch_metrics
      sslmode: require
    credentials:
      existingSecret: pgwatch-external-db
      usernameKey: username
      passwordKey: password
```

#### Grafana subchart note

When `pgwatch.grafana.useSubchart=true`, the datasource ConfigMap still uses
`${PGWATCH_METRICS_DS_USER}` / `${PGWATCH_METRICS_DS_PASSWORD}` placeholders.
If you use a pre-existing Secret with custom key names, mirror those values
into the Grafana subchart via top-level `grafana.envValueFrom` so the Grafana
container can resolve the placeholders.

### Environment Variables and Config Injection

Every component (`pgwatch`, `postgres`, `prometheus`, `grafana`) exposes two additional extension points:

- **`env`** — inject plain key/value environment variables directly into the container. Values provided here are **merged with the chart's built-in defaults**, and user-supplied values always take precedence:

  ```yaml
  pgwatch:
    env:
      PW_LOGLEVEL: "debug"
      METRIC_DATABASE_PORT: "5433"   # overrides the chart default of 5432
  grafana:
    env:
      GF_SERVER_ROOT_URL: "https://grafana.example.com"
  ```

- **`envFrom`** — source environment variables from existing ConfigMaps or Secrets. Explicit `env` entries (both chart defaults and user-supplied values) take precedence over `envFrom` when the same key appears in both:

  ```yaml
  pgwatch:
    envFrom:
      - secretRef:
          name: my-pgwatch-secret
  ```

#### Reserved env keys

The following keys are managed by the chart via `secretKeyRef` and **cannot** be set through `.Values.<component>.env`. Attempting to do so causes the chart to fail with a descriptive error pointing to the correct value path.

| Component | Reserved key | Configure via |
| --- | --- | --- |
| `pgwatch` | `PGWATCH_USER` | `pgwatch.postgres.credentials.existingSecret` + `.usernameKey` |
| `pgwatch` | `PGWATCH_USER_PASSWORD` | `pgwatch.postgres.credentials.existingSecret` + `.passwordKey` |
| `grafana` | `GF_DATABASE_USER` | `pgwatch.postgres.credentials.existingSecret` + `.usernameKey` |
| `grafana` | `GF_DATABASE_PASSWORD` | `pgwatch.postgres.credentials.existingSecret` + `.passwordKey` |
| `grafana` | `PGWATCH_METRICS_DS_USER` | `pgwatch.postgres.credentials.existingSecret` + `.usernameKey` |
| `grafana` | `PGWATCH_METRICS_DS_PASSWORD` | `pgwatch.postgres.credentials.existingSecret` + `.passwordKey` |
| `postgres` | `POSTGRES_PASSWORD` | `pgwatch.postgres.adminCredentials.existingSecret` + `.passwordKey` |

See [Credential Management](#credential-management) for details on configuring these values.

### Security Contexts

Security contexts can be tuned at two levels:

- **Global baseline** (`securityContext.enabled: true`) - applies a shared pod- and container-level security context to all components. Per-component values are merged on top and always win.
- **Per-component overrides** - each component exposes its own `securityContext.pod` / `securityContext.container` keys, applied independently when the global baseline is disabled (the default).

  ```yaml
  # Global baseline (opt-in)
  securityContext:
    enabled: true
    pod:
      runAsNonRoot: true
      runAsUser: 1000
      runAsGroup: 1000
      fsGroup: 1000
      fsGroupChangePolicy: "OnRootMismatch"
      seccompProfile:
        type: RuntimeDefault
    container:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: false
      capabilities:
        drop:
          - ALL

  # Per-component override (always available)
  pgwatch:
    securityContext:
      pod:
        runAsUser: 1001
      container:
        allowPrivilegeEscalation: false
  ```

> See the [Minikube](#minikube) section for a concrete example of overriding security contexts when `fsGroup` is not applied by the cluster.

### Resource Requests and Limits

The managed workloads do not by default specify any certain resource requests and limits, but they can be manually set through the values file in the corresponding resources block for each workload/job, for example:

```yaml
pgwatch:
  postgres:
    # -- New PostgreSQL instance - active when createMetricDatabase: true.
    newPgDatabase:
      # -- Resource requests and limits for the Metrics Database init job.
      dbInitJob:
        resources:
          requests:
            cpu: "25m"
            memory: "64Mi"
          limits:
            cpu: "200m"
            memory: "128Mi"
```

### Extra Resources

`extraDeploy` allows you to deploy arbitrary Kubernetes resources alongside the chart (e.g. `ServiceMonitor`, additional `ConfigMap`, CRDs). Each entry is rendered via `tpl`, so Helm template expressions are supported.

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

## Kubernetes Labels and Selectors

Resources rendered by this chart use Helm's [recommended Kubernetes label schema](https://helm.sh/docs/chart_best_practices/labels/):

```yaml
app.kubernetes.io/name: pgwatch
app.kubernetes.io/instance: <release-name>
app.kubernetes.io/component: <component>
app.kubernetes.io/managed-by: <release-service>
vendor: opensource.cybertec
```

`app.kubernetes.io/name: pgwatch` identifies the application, while
`app.kubernetes.io/component` identifies the logical role within the pgwatch
stack, such as `pgwatch`, `grafana`, `postgres`, `prometheus`, or `db-init`.

Workload and Service selectors intentionally use the stable subset
`app.kubernetes.io/name`, `app.kubernetes.io/instance`, and
`app.kubernetes.io/component`. These selector labels are also present on the
matching pod templates. Descriptive labels such as
`app.kubernetes.io/managed-by` and `vendor` are not used in selectors so they
can change without affecting controller upgrades or Service routing.

Subcharts, such as the optional Grafana and TimescaleDB charts, manage their
own labels. This chart only relies on their documented integration points, for
example Grafana sidecar discovery labels such as `grafana_dashboard` and
`grafana_datasource`.

## Helm Dependencies

Both subcharts are **opt-in** and disabled by default. Run `helm dependency update helm/pgwatch` before installing or upgrading.

### TimescaleDB (`timescaledb.enabled: true`)

Replaces the built-in PostgreSQL StatefulSet with a TimescaleDB instance.
Chart: `cloudpirates/timescaledb` - [ArtifactHub](https://artifacthub.io/packages/helm/cloudpirates-timescaledb/timescaledb)

**Note:** `pgwatch.postgres.adminCredentials` has no effect when TimescaleDB is enabled. Use `timescaledb.auth.*` instead.

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
Chart: `grafana-community/grafana` - [GitHub](https://github.com/grafana-community/helm-charts/tree/main/charts/grafana)

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

## Local Development

The repository includes ready-made values files for common deployment scenarios
under [`helm/pgwatch/test_scenarios/`](test_scenarios/README.md). A `Makefile`
at the repository root wraps the deploy/portforward/teardown workflow:

```sh
make deploy              SCENARIO=builtin-postgres-sink
make portforward-pgwatch SCENARIO=builtin-postgres-sink
make portforward-grafana SCENARIO=builtin-postgres-sink
make teardown            SCENARIO=builtin-postgres-sink
make status
```

Run `make` (no target) to list available scenarios.

### Minikube

The `postgres` and `timescaledb` images are designed to start as root, set up the data directory, and then drop to the postgres user (uid 999). The chart defaults leave the security context empty so clusters that properly apply `fsGroup` volume ownership can run those images as non-root.

On **Minikube**, `fsGroup` may not be applied before the container starts, causing a `Permission denied` error when the image tries to create the data directory. Override the security context to let the images handle their own permissions.

A ready-made overlay is provided at [`test_scenarios/deployment/overlays/minikube-securitycontext.yaml`](test_scenarios/deployment/overlays/minikube-securitycontext.yaml). When using the Makefile it is applied automatically (`MINIKUBE=true` is the default). To apply it manually:

```sh
helm upgrade --install pgwatch ./helm/pgwatch \
  -f your-values.yaml \
  -f helm/pgwatch/test_scenarios/deployment/overlays/minikube-securitycontext.yaml
```

## Migration Reference

### snake_case to camelCase values

Boolean options in this chart now use native YAML booleans (`true` / `false`).
Legacy string values (`"true"` / `"false"`) are still accepted temporarily for
compatibility, but are deprecated and will be removed in a future chart version.

Values keys follow Helm's camelCase naming convention. The former snake_case
keys are still accepted as backward-compatible fallbacks and emit a Helm
install/upgrade warning. Please migrate them before the next major chart
version, where snake_case compatibility will be removed:

| Deprecated snake_case | Replacement camelCase |
| --- | --- |
| `pgwatch.postgres.enable_pg_sink` | `pgwatch.postgres.enablePgSink` |
| `pgwatch.postgres.settings.retention_days` | `pgwatch.postgres.settings.retentionDays` |
| `pgwatch.postgres.create_metric_database` | `pgwatch.postgres.createMetricDatabase` |
| `pgwatch.postgres.new_pg_database` | `pgwatch.postgres.newPgDatabase` |
| `pgwatch.postgres.use_existing_database` | `pgwatch.postgres.useExistingDatabase` |
| `pgwatch.postgres.use_existing_database.grafana_database` | `pgwatch.postgres.useExistingDatabase.grafanaDatabase` |
| `pgwatch.prometheus.enable_prom_sink` | `pgwatch.prometheus.enablePromSink` |
| `pgwatch.prometheus.new_prometheus` | `pgwatch.prometheus.newPrometheus` |
| `pgwatch.prometheus.new_prometheus.create_prometheus` | `pgwatch.prometheus.newPrometheus.createPrometheus` |
| `pgwatch.prometheus.new_prometheus.settings.retention_days` | `pgwatch.prometheus.newPrometheus.settings.retentionDays` |
| `pgwatch.grafana.enable_grafana` | `pgwatch.grafana.enableGrafana` |
| `pgwatch.grafana.enable_datasources` | `pgwatch.grafana.enableDatasources` |

### Deprecated inline database credentials

Before, credentials could be defined inline under `useExistingDatabase`. This is
deprecated but still works with a warning:

```yaml
pgwatch:
  postgres:
    useExistingDatabase:
      endpoint: postgresql.local
      username: pgwatch_user   # deprecated
      password: change-me      # deprecated
```

Move credentials under `pgwatch.postgres.credentials` instead:

```yaml
pgwatch:
  postgres:
    useExistingDatabase:
      endpoint: postgresql.local
    credentials:
      username: pgwatch_user
      password: change-me
```

### pgwatch.image string to object migration

`pgwatch.image` plain string format is deprecated and will be removed in a future release.

Migrate your values as follows:

```yaml
# Old
pgwatch:
  image: "docker.io/cybertecpostgresql/pgwatch"

# New
pgwatch:
  image:
    repository: "docker.io/cybertecpostgresql/pgwatch"
    tag: ""  # empty defaults to .Chart.AppVersion
```
