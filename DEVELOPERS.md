# Developer Guide

## Prerequisites

- [Helm](https://helm.sh/docs/intro/install/) ≥ 3.x
- [helm-unittest](https://github.com/helm-unittest/helm-unittest) plugin:

  ```sh
  helm plugin install https://github.com/helm-unittest/helm-unittest
  ```

---

## Repository layout

```
helm/pgwatch/
  templates/          Chart templates
  tests/              helm-unittest test suites (*_test.yaml)
  test_scenarios/
    deployment/       Full-stack values files for real cluster deployments
    template-checks/  Minimal values files for helm template verification
```

See [`helm/pgwatch/test_scenarios/README.md`](helm/pgwatch/test_scenarios/README.md) for a full description of every scenario file.

---

## Unit tests

Tests live in [`helm/pgwatch/tests/`](helm/pgwatch/tests/) and use the
[helm-unittest](https://github.com/helm-unittest/helm-unittest) plugin.
They cover every scenario under `test_scenarios/template-checks/` except
`env-merge-envfrom-precedence` (which requires a live pod to observe runtime
`env`/`envFrom` precedence — see the file header for the manual steps).

### Running the tests

To run all tests:

```sh
make test-templates
```

or directly:

```sh
helm unittest helm/pgwatch
```

To run a single suite, you can pass the test file path with `-f`:

```sh
helm unittest helm/pgwatch -f 'tests/grafana-disabled_test.yaml'
```

Another option is to run the tests suites with regex

```sh
# All legacy-compat suites
helm unittest helm/pgwatch -f 'tests/legacy*_test.yaml'

# All env-merge suites
helm unittest helm/pgwatch -f 'tests/env-merge-*_test.yaml'
```

The `-f` flag accepts standard shell globs. There is no test-name-level filter;
granularity is at the suite (file) level.

### Adding a new test

1. Add a values file under `helm/pgwatch/test_scenarios/template-checks/` with a
   comment block describing what behavior it exercises and what the expected
   output is.
2. Add a corresponding `*_test.yaml` in `helm/pgwatch/tests/`. Reference the
   values file with a path relative to the tests directory:

   ```yaml
   values:
     - ../test_scenarios/template-checks/your-scenario.yaml
   ```

3. Run `make test-templates` to confirm the suite passes.

---

## Deployment scenarios

Full-stack deploy/teardown against a real cluster (e.g. Minikube) is covered by
the `Makefile`:

```sh
make deploy              SCENARIO=<name> [MINIKUBE=true] [CHART=repo/chart]
make portforward-pgwatch SCENARIO=<name>
make portforward-grafana SCENARIO=<name>
make teardown            SCENARIO=<name>
make status
```

See [`helm/pgwatch/test_scenarios/README.md`](helm/pgwatch/test_scenarios/README.md)
for the full list of available scenarios and overlay options.
