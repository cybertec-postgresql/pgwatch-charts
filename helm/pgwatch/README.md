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
comming soon

### git clone
```sh
git clone https://github.com/cybertec-postgresql/pgwatch-charts.git
cd pgwatch-chart/helm/pgwatch


// Install helm-Chart
helm install pgwatch -n pgwatch -f custom-values.yaml . 

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
