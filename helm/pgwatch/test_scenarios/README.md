# Test Scenarios

Manual values files for exercising specific chart behaviors during development.
Each file documents its own verify/expected-output steps in its header comment.

- [`legacy-bool-values.yaml`](legacy-bool-values.yaml) — legacy string-boolean fallback
- [`legacy-snakecase-values.yaml`](legacy-snakecase-values.yaml) — legacy snake_case key fallback
- [`legacy-inline-db-credentials-values.yaml`](legacy-inline-db-credentials-values.yaml) — deprecated inline DB credentials fallback
- [`legacy-image-string-values.yaml`](legacy-image-string-values.yaml) — deprecated plain-string `pgwatch.image` fallback
- [`env-merge-override.yaml`](env-merge-override.yaml) — user `env` values override chart defaults
- [`env-merge-reserved-key.yaml`](env-merge-reserved-key.yaml) — reserved env key fails the render
- [`env-merge-envfrom-precedence.yaml`](env-merge-envfrom-precedence.yaml) — explicit `env` wins over `envFrom`
