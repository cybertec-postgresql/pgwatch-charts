# Changelog

## [4.1.0] – 2026-06-18

### Deprecated

- Plain string value for `pgwatch.image` in favor of the new structured format
  with `pgwatch.image.repository` and `pgwatch.image.tag` fields ([#39](https://github.com/cybertec-postgresql/pgwatch-charts/issues/39)).

### Added

- The ability to manually specify `resources` blocks on managed workloads ([#30](https://github.com/cybertec-postgresql/pgwatch-charts/issues/30)).
- `apiVersion: v1` and `kind: PersistentVolumeClaim` to the built-in PostgreSQL `volumeClaimTemplates` entry for better ArgoCD compatibility ([#43](https://github.com/cybertec-postgresql/pgwatch-charts/issues/43)).

### Changed

- Upgraded TimescaleDB subchart dependency from `0.11.3` to `0.12.1`.
- Upgraded Grafana subchart dependency from `10.5.15` to `12.4.8` (Grafana app `13.0.2`), resolving [#38](https://github.com/cybertec-postgresql/pgwatch-charts/issues/38).
- Upgraded built-in Grafana image (`pgwatch.grafana.image`) from `grafana/grafana:12.4.0` to `grafana/grafana:13.0.2` to match the subchart app version.
- Updated all PostgreSQL and Prometheus dashboard JSON files from the upstream pgwatch repository ([`3b722b5e44`](https://github.com/cybertec-postgresql/pgwatch/tree/3b722b5e44/grafana)); notably `3-query-performance-analysis` received significant panel additions.

### Fixed

- `db-init` hook Job now honors `timescaledb.auth.secretKeys.adminPasswordKey` when TimescaleDB is enabled.
- Duplicate env entries no longer appear when a user-supplied key in `.Values.<component>.env` matches a chart-managed default; user values now take precedence via merge ([#41](https://github.com/cybertec-postgresql/pgwatch-charts/issues/41)).
- Setting a credential-backed reserved env key (`PGWATCH_USER`, `PGWATCH_USER_PASSWORD`, `GF_DATABASE_USER`, `GF_DATABASE_PASSWORD`, `PGWATCH_METRICS_DS_USER`, `PGWATCH_METRICS_DS_PASSWORD`, `POSTGRES_PASSWORD`) via `.Values.<component>.env` now fails immediately with a descriptive error pointing to the correct credential value path ([#41](https://github.com/cybertec-postgresql/pgwatch-charts/issues/41)).

## [4.0.1] – 2026-05-26

### Added

- `seccompProfile.type: RuntimeDefault` in global `securityContext.pod` defaults when `securityContext.enabled=true` ([#31](https://github.com/cybertec-postgresql/pgwatch-charts/issues/31)).

### Fixed

- `db-init` hook Job now honors global and PostgreSQL component `securityContext` settings.

## [4.0.0] – 2026-05-07

### Breaking changes

- Standardized chart labels and selectors to Helm's recommended `app.kubernetes.io/*` schema ([#23](https://github.com/cybertec-postgresql/pgwatch-charts/issues/23)). Upgrades may require recreating Deployments/StatefulSets due to immutable selectors.

### Added

- Configurable Kubernetes Secrets for database credentials with support for existing Secrets and custom keys ([#12](https://github.com/cybertec-postgresql/pgwatch-charts/issues/12)).
- Optional Grafana and TimescaleDB Helm subcharts with k8s-sidecar support for automatic provisioning.
- Global and component-based SecurityContext configuration with per-component override support.
- Ingress resource with TLS support for pgwatch web UI.
- `extraDeploy` for deploying arbitrary Kubernetes resources (e.g., ServiceMonitor, CRDs).
- `env` and `envFrom` support for dynamic environment variable injection across all components.
- Shared Helm helper templates for common and selector labels.
- Compatibility warnings for deprecated value formats in `NOTES.txt`.
- Detailed documentation and upgrade guidance for chart 4.x.
- Updated Grafana dashboards for PostgreSQL and Prometheus sinks.

### Changed

- Native YAML booleans instead of quoted string values ([#13](https://github.com/cybertec-postgresql/pgwatch-charts/issues/13)).
- Standardized values keys to camelCase with backward-compatible snake_case fallbacks ([#22](https://github.com/cybertec-postgresql/pgwatch-charts/issues/22)).
- Multi-file source configuration via `pgwatch.sources.files` directory mount ([#20](https://github.com/cybertec-postgresql/pgwatch-charts/pull/20)).
- Updated TimescaleDB subchart dependency ([#21](https://github.com/cybertec-postgresql/pgwatch-charts/pull/21)).
- Reorganized README with table of contents and improved discoverability ([#26](https://github.com/cybertec-postgresql/pgwatch-charts/pull/26)).

### Deprecated

The following are deprecated but still supported in 4.0.0 and will be removed in a future release:

- String boolean values (`"true"` / `"false"`) in favor of native YAML booleans ([#13](https://github.com/cybertec-postgresql/pgwatch-charts/issues/13)).
- snake_case Helm values in favor of camelCase ([#22](https://github.com/cybertec-postgresql/pgwatch-charts/issues/22)).
- Inline `username`/`password` under `useExistingDatabase` in favor of `pgwatch.postgres.credentials` ([#12](https://github.com/cybertec-postgresql/pgwatch-charts/issues/12)).
