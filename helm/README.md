[![Documentation](https://img.shields.io/badge/Documentation-pgwat.ch-brightgreen)](https://pgwat.ch)
[![License: MIT](https://img.shields.io/badge/License-BSD_3-green.svg)](https://opensource.org/license/bsd-3-clause)
[![Go Build & Test](https://github.com/cybertec-postgresql/pgwatch/actions/workflows/build.yml/badge.svg)](https://github.com/cybertec-postgresql/pgwatch/actions/workflows/build.yml)
[![Coverage Status](https://coveralls.io/repos/github/cybertec-postgresql/pgwatch/badge.svg?branch=master&service=github)](https://coveralls.io/github/cybertec-postgresql/pgwatch?branch=master)


# pgWatch-Helm-Charts

These Helm charts are available for a quick start on Kubernetes and Openshift. 
Since the new pgWatch release (3.x), the Helm charts have been developed and tested primarily for Openshift. 
The old Helm charts for pgwatch2 are deprecated and no longer maintained. Furthermore, they will be removed in summer 2025. 
 
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

### Custom Values-file
```sh
// Edit Values File
cp values.yaml custom-values.yaml
vi custom-values.yaml
```
### Check the Pods
```sh
kubectl get pods -n pgwatch
oc get pods -n pgwatch
```

# Contributing

Feedback, suggestions, problem reports, and pull requests are very much appreciated.
