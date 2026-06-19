SCENARIO     ?= builtin-postgres-sink
MINIKUBE     ?= true
RELEASE      ?= pgwatch
# CHART is the helm chart reference: a local path (default) or repo/chart for release testing.
# Example: make deploy SCENARIO=builtin-postgres-sink CHART=pgwatch/pgwatch
CHART        ?= ./helm/pgwatch
SCENARIO_DIR := helm/pgwatch/test_scenarios/deployment
NAMESPACE    ?= pgwatch-$(SCENARIO)
# SOURCES_FILE: pgwatch sources YAML loaded via --set-file. Set to "" to skip.
SOURCES_FILE ?= $(SCENARIO_DIR)/overlays/custom-sources.yaml

ifeq ($(MINIKUBE),true)
MINIKUBE_FLAG := -f $(SCENARIO_DIR)/overlays/minikube-securitycontext.yaml
else
MINIKUBE_FLAG :=
endif

ifneq ($(SOURCES_FILE),)
SOURCES_FLAG := --set-file pgwatch.sources.files.custom-sources\\.yaml=$(SOURCES_FILE)
else
SOURCES_FLAG :=
endif

# pgwatch service name is hardcoded in the chart templates.
PGWATCH_SVC  := pgwatch-svc
# Grafana subchart service is named <release>-grafana and listens on port 80;
# the custom Grafana Deployment uses hardcoded service name 'grafana-svc' on port 3000.
GRAFANA_SVC  := $(if $(findstring grafana-subchart,$(SCENARIO)),$(RELEASE)-grafana,grafana-svc)
GRAFANA_PORT := $(if $(findstring grafana-subchart,$(SCENARIO)),80,3000)

.DEFAULT_GOAL := list

.PHONY: list status deploy teardown portforward-pgwatch portforward-grafana test-templates

test-templates:
	helm unittest helm/pgwatch

list:
	@echo "Available scenarios:"
	@echo ""
	@ls $(SCENARIO_DIR)/*.yaml | xargs -n1 basename | sed 's/\.yaml//'
	@echo ""
	@echo "Usage:"
	@echo "  make deploy              SCENARIO=<name> [MINIKUBE=true] [CHART=repo/chart]"
	@echo "  make portforward-pgwatch SCENARIO=<name>"
	@echo "  make portforward-grafana SCENARIO=<name>"
	@echo "  make teardown            SCENARIO=<name>"
	@echo "  make status"
	@echo "  make test-templates"

status:
	@helm list -A --filter '^$(RELEASE)$$'

deploy:
	@if echo "$(SCENARIO)" | grep -q "external-postgres"; then \
	  if ! kubectl get svc postgres-svc -n pgwatch-postgres 2>/dev/null 1>&2; then \
	    echo "ERROR: postgres-svc not found in namespace pgwatch-postgres."; \
	    echo "  Deploy an external PostgreSQL service before running this scenario."; \
	    exit 1; \
	  fi; \
	fi
	helm upgrade --install $(RELEASE) $(CHART) \
	  --namespace $(NAMESPACE) --create-namespace \
	  -f $(SCENARIO_DIR)/$(SCENARIO).yaml \
	  $(MINIKUBE_FLAG) \
	  $(SOURCES_FLAG)

portforward-pgwatch:
	kubectl port-forward svc/$(PGWATCH_SVC) 8080:8080 -n $(NAMESPACE)

portforward-grafana:
	kubectl port-forward svc/$(GRAFANA_SVC) 3000:$(GRAFANA_PORT) -n $(NAMESPACE)

teardown:
	helm uninstall $(RELEASE) -n $(NAMESPACE)
	kubectl delete namespace $(NAMESPACE)
