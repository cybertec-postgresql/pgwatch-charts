# pgwatch Helm Charts

This directory contains the Helm chart sources for pgwatch.

## Maintained chart

The actively maintained pgwatch Helm chart is located in [`pgwatch/`](pgwatch/).
See the [chart README](pgwatch/README.md) for installation, upgrade, and
configuration documentation.

Quick install from the published Helm repository:

```sh
helm repo add pgwatch https://cybertec-postgresql.github.io/pgwatch-charts
helm repo update
helm install pgwatch pgwatch/pgwatch -n pgwatch --create-namespace --values custom-values.yaml
```

For local development or installation from a clone:

```sh
git clone https://github.com/cybertec-postgresql/pgwatch-charts.git
cd pgwatch-charts/helm/pgwatch
helm dependency update .
helm install pgwatch -n pgwatch --create-namespace -f custom-values.yaml .
```

## Deprecated pgwatch2 chart

The old `pgwatch2` Helm chart was deprecated, unmaintained, and has been removed
from this directory. Use the maintained [`pgwatch/`](pgwatch/) chart instead.

## Contributing

Feedback, suggestions, problem reports, and pull requests are welcome.
