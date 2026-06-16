{{/*
pgwatch.grafana.env
  Renders the env list for the grafana container.

  Merges chart-managed defaults with user-supplied .Values.pgwatch.grafana.env.
  User-supplied values take precedence over defaults for all plain-value keys.

  Reserved keys — backed by secretKeyRef, configured via chart credential
  values. Setting these in .Values.pgwatch.grafana.env causes the chart to fail:
    GF_DATABASE_USER            — set .Values.pgwatch.postgres.credentials.existingSecret
                                  and .Values.pgwatch.postgres.credentials.usernameKey
    GF_DATABASE_PASSWORD        — set .Values.pgwatch.postgres.credentials.existingSecret
                                  and .Values.pgwatch.postgres.credentials.passwordKey
    PGWATCH_METRICS_DS_USER     — set .Values.pgwatch.postgres.credentials.existingSecret
                                  and .Values.pgwatch.postgres.credentials.usernameKey
    PGWATCH_METRICS_DS_PASSWORD — set .Values.pgwatch.postgres.credentials.existingSecret
                                  and .Values.pgwatch.postgres.credentials.passwordKey
*/}}
{{- define "pgwatch.grafana.env" -}}
{{- $root := . -}}
{{- $userEnv := .Values.pgwatch.grafana.env -}}
{{- $reserved := dict
  "GF_DATABASE_USER"            "set .Values.pgwatch.postgres.credentials.existingSecret and .Values.pgwatch.postgres.credentials.usernameKey instead"
  "GF_DATABASE_PASSWORD"        "set .Values.pgwatch.postgres.credentials.existingSecret and .Values.pgwatch.postgres.credentials.passwordKey instead"
  "PGWATCH_METRICS_DS_USER"     "set .Values.pgwatch.postgres.credentials.existingSecret and .Values.pgwatch.postgres.credentials.usernameKey instead"
  "PGWATCH_METRICS_DS_PASSWORD" "set .Values.pgwatch.postgres.credentials.existingSecret and .Values.pgwatch.postgres.credentials.passwordKey instead"
-}}
{{- range $key, $hint := $reserved }}
  {{- if hasKey $userEnv $key }}
    {{- fail (printf "pgwatch.grafana.env: %q is reserved and managed by the chart; %s" $key $hint) }}
  {{- end }}
{{- end }}
{{- $defaults := dict
  "GF_AUTH_ANONYMOUS_ENABLED"              "true"
  "GF_AUTH_ANONYMOUS_ORG_ROLE"             "Admin"
  "GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH" "/var/lib/grafana/dashboards/postgresql/1-global-db-overview.json"
-}}
{{- if include "pgwatch.isTrue" (include "pgwatch.postgres.createMetricDatabase" $root) }}
  {{- $_ := set $defaults "GF_DATABASE_TYPE"     "postgres" -}}
  {{- $_ := set $defaults "GF_DATABASE_HOST"     (printf "%s:5432" (include "pgwatch.dbHost" $root)) -}}
  {{- $_ := set $defaults "GF_DATABASE_NAME"     "pgwatch_grafana" -}}
  {{- $_ := set $defaults "GF_DATABASE_SSL_MODE" "disable" -}}
{{- else if include "pgwatch.postgres.hasUseExistingDatabase" $root }}
  {{- $_ := set $defaults "GF_DATABASE_TYPE"     "postgres" -}}
  {{- $_ := set $defaults "GF_DATABASE_HOST"     (include "pgwatch.postgres.useExistingDatabase.endpoint" $root) -}}
  {{- $_ := set $defaults "GF_DATABASE_NAME"     (include "pgwatch.postgres.useExistingDatabase.grafanaDatabase" $root) -}}
  {{- $_ := set $defaults "GF_DATABASE_SSL_MODE" (include "pgwatch.postgres.useExistingDatabase.sslmode" $root) -}}
{{- end }}
{{- $merged := merge (deepCopy $userEnv) $defaults -}}
{{- range $key, $value := $merged }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- if or (include "pgwatch.isTrue" (include "pgwatch.postgres.createMetricDatabase" $root)) (include "pgwatch.postgres.hasUseExistingDatabase" $root) }}
- name: GF_DATABASE_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "pgwatch.credentialSecretName" $root }}
      key: {{ include "pgwatch.credentialUsernameKey" $root }}
- name: GF_DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "pgwatch.credentialSecretName" $root }}
      key: {{ include "pgwatch.credentialPasswordKey" $root }}
- name: PGWATCH_METRICS_DS_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "pgwatch.credentialSecretName" $root }}
      key: {{ include "pgwatch.credentialUsernameKey" $root }}
- name: PGWATCH_METRICS_DS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "pgwatch.credentialSecretName" $root }}
      key: {{ include "pgwatch.credentialPasswordKey" $root }}
{{- end }}
{{- end }}
