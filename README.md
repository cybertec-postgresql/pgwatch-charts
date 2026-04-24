# pgwatch-charts

Chart templates for cybertec-postgresql/pgwatch

## Helm Chart

The actively maintained Helm chart for pgwatch lives at [`helm/pgwatch/`](helm/pgwatch/).
See the [Helm chart README](helm/pgwatch/README.md) for full installation and configuration documentation.

## Disclaimer

All the templates in this folder are not meant to be used for production purposes directly, but rather require some
additional customizations, like minimally using the most recent Docker image versions, changing the metric storage type,
volume sizes and security adjustments.

Also the templates are not automatically tested on new releases or other changes, so please report any abnormal findings.
