# Test Scenarios

Manual values files for exercising specific chart behaviors during development.

## Makefile

A `Makefile` at the repository root covers the deploy/portforward/teardown workflow for `deployment/` scenarios:

```sh
make deploy              SCENARIO=<name> [MINIKUBE=true] [CHART=repo/chart]
make portforward-pgwatch SCENARIO=<name>
make portforward-grafana SCENARIO=<name>
make teardown            SCENARIO=<name>
make status
```

`MINIKUBE=true` (default) applies the `minikube-securitycontext.yaml` overlay automatically.
`SOURCES_FILE` defaults to `deployment/overlays/custom-sources.yaml`; set to `SOURCES_FILE=` to skip.

For subchart scenarios (`timescaledb` or `grafana-subchart-*`), make sure Helm dependencies are fetched before deploying.

---

## `deployment/` — full-stack scenarios

Values files for full-stack deployments in a real cluster (e.g. Minikube).
Use `make deploy SCENARIO=<name>` or pass directly with `-f` to helm install/upgrade commands.

### Metrics sink variants

| File | Sink | Grafana |
| --- | --- | --- |
| [`builtin-postgres-sink.yaml`](deployment/builtin-postgres-sink.yaml) | Built-in PostgreSQL StatefulSet | Custom Deployment |
| [`external-postgres-sink.yaml`](deployment/external-postgres-sink.yaml) | External PostgreSQL (requires a reachable PostgreSQL service) | Custom Deployment |
| [`timescaledb-sink.yaml`](deployment/timescaledb-sink.yaml) | TimescaleDB subchart (`helm dependency update` required) | Custom Deployment |

### Grafana subchart variants

| File | Sink | Grafana |
| --- | --- | --- |
| [`grafana-subchart-builtin-postgres.yaml`](deployment/grafana-subchart-builtin-postgres.yaml) | Built-in PostgreSQL StatefulSet | Official Grafana subchart |
| [`grafana-subchart-external-postgres.yaml`](deployment/grafana-subchart-external-postgres.yaml) | External PostgreSQL (requires a reachable PostgreSQL service) | Official Grafana subchart |
| [`grafana-subchart-timescaledb.yaml`](deployment/grafana-subchart-timescaledb.yaml) | TimescaleDB subchart | Official Grafana subchart |

### `deployment/overlays/`

Additive `-f` files layered on top of a deployment scenario. Not standalone.

| File | Purpose |
| --- | --- |
| [`minikube-securitycontext.yaml`](deployment/overlays/minikube-securitycontext.yaml) | `runAsUser: 0` overrides for postgres and timescaledb on Minikube |
| [`custom-sources.yaml`](deployment/overlays/custom-sources.yaml) | Example file-based source list (single file) |

---

## `template-checks/` — helm template verification

Minimal values files for verifying a single chart behavior with `helm template`.
Not meant to be deployed; use `helm template` or `helm install --dry-run`.

### Environment variable merge

| File | What it checks |
| --- | --- |
| [`env-merge-override.yaml`](template-checks/env-merge-override.yaml) | User `env` values override chart defaults |
| [`env-merge-reserved-key.yaml`](template-checks/env-merge-reserved-key.yaml) | Reserved env key causes the render to fail |
| [`env-merge-envfrom-precedence.yaml`](template-checks/env-merge-envfrom-precedence.yaml) | Explicit `env` wins over `envFrom` on a running pod |

### Legacy compatibility

| File | What it checks |
| --- | --- |
| [`legacy-bool-values.yaml`](template-checks/legacy-bool-values.yaml) | String-boolean fallback (`"true"`/`"false"`) |
| [`legacy-snakecase-values.yaml`](template-checks/legacy-snakecase-values.yaml) | `snake_case` key fallback |
| [`legacy-inline-db-credentials-values.yaml`](template-checks/legacy-inline-db-credentials-values.yaml) | Deprecated inline DB credentials fallback |
| [`legacy-image-string-values.yaml`](template-checks/legacy-image-string-values.yaml) | Deprecated plain-string `pgwatch.image` fallback |

### Feature checks

| File | What it checks |
| --- | --- |
| [`prometheus-sink-disabled.yaml`](template-checks/prometheus-sink-disabled.yaml) | No Prometheus resources rendered when `enablePromSink: false` |
| [`grafana-disabled.yaml`](template-checks/grafana-disabled.yaml) | No Grafana resources rendered when `enableGrafana: false` |
| [`credentials-existing-secret.yaml`](template-checks/credentials-existing-secret.yaml) | Chart skips Secret creation and uses `existingSecret` references |
| [`ingress-subpath.yaml`](template-checks/ingress-subpath.yaml) | Ingress renders correctly and `PW_WEBBASEPATH` is injected |
| [`security-context-global-baseline.yaml`](template-checks/security-context-global-baseline.yaml) | Global securityContext baseline merges with per-component overrides |
