# Changelog

## [Unreleased]

### Breaking changes

- `pgwatch.image` was changed from a string value to a structured object ([#39](https://github.com/cybertec-postgresql/pgwatch-charts/issues/39)).
  - Previous: `pgwatch.image: "docker.io/cybertecpostgresql/pgwatch"`
  - New: `pgwatch.image.repository` and `pgwatch.image.tag`
  - An empty tag defaults to `.Chart.AppVersion`.
  - Users overriding `pgwatch.image` should migrate to the new format.

### Added

- The ability to manually specify `resources` blocks on managed workloads ([#30](https://github.com/cybertec-postgresql/pgwatch-charts/issues/30)).

### Fixed

- `db-init` hook Job now honors `timescaledb.auth.secretKeys.adminPasswordKey` when TimescaleDB is enabled.

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