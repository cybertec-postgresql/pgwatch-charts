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
{{- if $root.Values.pgwatch.postgres.createMetricDatabase }}
  {{- $_ := set $defaults "METRIC_DATABASE_ENDPOINT" (printf "%s.%s.svc.cluster.local" (include "pgwatch.dbHost" $root) $root.Release.Namespace) -}}
  {{- $_ := set $defaults "METRIC_DATABASE_PORT" "5432" -}}
  {{- $_ := set $defaults "METRIC_DATABASE_DATABASE" "pgwatch_metrics" -}}
  {{- $_ := set $defaults "METRIC_DATABASE_SSLMODE" "disable" -}}
{{- else if $root.Values.pgwatch.postgres.useExistingDatabase }}
  {{- $_ := set $defaults "METRIC_DATABASE_ENDPOINT" $root.Values.pgwatch.postgres.useExistingDatabase.endpoint -}}
  {{- $_ := set $defaults "METRIC_DATABASE_PORT" $root.Values.pgwatch.postgres.useExistingDatabase.port -}}
  {{- $_ := set $defaults "METRIC_DATABASE_DATABASE" $root.Values.pgwatch.postgres.useExistingDatabase.database -}}
  {{- $_ := set $defaults "METRIC_DATABASE_SSLMODE" $root.Values.pgwatch.postgres.useExistingDatabase.sslmode -}}
{{- end }}
{{- if $root.Values.pgwatch.postgres.enablePgSink }}
  {{- $_ := set $defaults "PG_IS_SINK" "true" -}}
  {{- $_ := set $defaults "PG_RETENTION_DAYS" (printf "%v days" $root.Values.pgwatch.postgres.settings.retentionDays) -}}
{{- end }}
{{- if $root.Values.pgwatch.prometheus.enablePromSink }}
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
