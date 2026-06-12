{{/*
pgwatch.pgwatch.env
  Renders the env list for the pgwatch container.

  Merges chart-managed defaults with user-supplied .Values.pgwatch.env.
  User-supplied values take precedence over defaults for all plain-value keys.

  Reserved keys — backed by secretKeyRef, configured via chart credential
  values. Setting these in .Values.pgwatch.env causes the chart to fail:
    PGWATCH_USER          — set .Values.pgwatch.postgres.credentials.existingSecret
                            and .Values.pgwatch.postgres.credentials.usernameKey
    PGWATCH_USER_PASSWORD — set .Values.pgwatch.postgres.credentials.existingSecret
                            and .Values.pgwatch.postgres.credentials.passwordKey
*/}}
{{- define "pgwatch.pgwatch.env" -}}
{{- $root := . -}}
{{- $userEnv := .Values.pgwatch.env -}}
{{- $reserved := dict
  "PGWATCH_USER"          "set .Values.pgwatch.postgres.credentials.existingSecret and .Values.pgwatch.postgres.credentials.usernameKey instead"
  "PGWATCH_USER_PASSWORD" "set .Values.pgwatch.postgres.credentials.existingSecret and .Values.pgwatch.postgres.credentials.passwordKey instead"
-}}
{{- range $key, $hint := $reserved }}
  {{- if hasKey $userEnv $key }}
    {{- fail (printf "pgwatch.env: %q is reserved and managed by the chart; %s" $key $hint) }}
  {{- end }}
{{- end }}
{{- $defaults := dict -}}
{{- if include "pgwatch.isTrue" (include "pgwatch.postgres.createMetricDatabase" $root) }}
  {{- $_ := set $defaults "METRIC_DATABASE_ENDPOINT" (printf "%s.%s.svc.cluster.local" (include "pgwatch.dbHost" $root) $root.Release.Namespace) -}}
  {{- $_ := set $defaults "METRIC_DATABASE_PORT" "5432" -}}
  {{- $_ := set $defaults "METRIC_DATABASE_DATABASE" "pgwatch_metrics" -}}
  {{- $_ := set $defaults "METRIC_DATABASE_SSLMODE" "disable" -}}
{{- else if include "pgwatch.postgres.hasUseExistingDatabase" $root }}
  {{- $_ := set $defaults "METRIC_DATABASE_ENDPOINT" (include "pgwatch.postgres.useExistingDatabase.endpoint" $root) -}}
  {{- $_ := set $defaults "METRIC_DATABASE_PORT" (include "pgwatch.postgres.useExistingDatabase.port" $root) -}}
  {{- $_ := set $defaults "METRIC_DATABASE_DATABASE" (include "pgwatch.postgres.useExistingDatabase.database" $root) -}}
  {{- $_ := set $defaults "METRIC_DATABASE_SSLMODE" (include "pgwatch.postgres.useExistingDatabase.sslmode" $root) -}}
{{- end }}
{{- if include "pgwatch.isTrue" (include "pgwatch.postgres.enablePgSink" $root) }}
  {{- $_ := set $defaults "PG_IS_SINK" "true" -}}
  {{- $_ := set $defaults "PG_RETENTION_DAYS" (printf "%s days" (include "pgwatch.postgres.settings.retentionDays" $root)) -}}
{{- end }}
{{- if include "pgwatch.isTrue" (include "pgwatch.prometheus.enablePromSink" $root) }}
  {{- $_ := set $defaults "PROM_IS_SINK" "true" -}}
{{- end }}
{{- if and $root.Values.pgwatch.ingress.enabled $root.Values.pgwatch.ingress.webBasePath }}
  {{- $_ := set $defaults "PW_WEBBASEPATH" $root.Values.pgwatch.ingress.webBasePath -}}
{{- end }}
{{- if $root.Values.pgwatch.sources.files }}
  {{- $_ := set $defaults "PW_SOURCES" "/tmp/pgwatch-sources" -}}
{{- else }}
  {{- $_ := set $defaults "PW_SOURCES" "postgresql://$(PGWATCH_USER):$(PGWATCH_USER_PASSWORD)@$(METRIC_DATABASE_ENDPOINT):$(METRIC_DATABASE_PORT)/$(METRIC_DATABASE_DATABASE)?sslmode=$(METRIC_DATABASE_SSLMODE)" -}}
{{- end }}
{{- $merged := merge (deepCopy $userEnv) $defaults -}}
- name: PGWATCH_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "pgwatch.credentialSecretName" $root }}
      key: {{ include "pgwatch.credentialUsernameKey" $root }}
- name: PGWATCH_USER_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "pgwatch.credentialSecretName" $root }}
      key: {{ include "pgwatch.credentialPasswordKey" $root }}
{{- range $key, $value := $merged }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
