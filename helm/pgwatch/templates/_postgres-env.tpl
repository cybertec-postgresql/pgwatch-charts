{{/*
pgwatch.postgres.env
  Renders the env list for the postgres container.

  Merges chart-managed defaults with user-supplied .Values.pgwatch.postgres.env.
  User-supplied values take precedence over defaults for all plain-value keys.

  Reserved keys — backed by secretKeyRef, configured via chart credential
  values. Setting these in .Values.pgwatch.postgres.env causes the chart to fail:
    POSTGRES_PASSWORD — set .Values.pgwatch.postgres.adminCredentials.existingSecret
                        and .Values.pgwatch.postgres.adminCredentials.passwordKey
*/}}
{{- define "pgwatch.postgres.env" -}}
{{- $root := . -}}
{{- $userEnv := .Values.pgwatch.postgres.env -}}
{{- $reserved := dict
  "POSTGRES_PASSWORD" "set .Values.pgwatch.postgres.adminCredentials.existingSecret and .Values.pgwatch.postgres.adminCredentials.passwordKey instead"
-}}
{{- range $key, $hint := $reserved }}
  {{- if hasKey $userEnv $key }}
    {{- fail (printf "pgwatch.postgres.env: %q is reserved and managed by the chart; %s" $key $hint) }}
  {{- end }}
{{- end }}
{{- $defaults := dict
  "POSTGRES_USER" "postgres"
  "PGDATA"        "/pgdata/data"
-}}
{{- $merged := merge (deepCopy $userEnv) $defaults -}}
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "pgwatch.adminCredentialSecretName" $root }}
      key: {{ include "pgwatch.adminCredentialPasswordKey" $root }}
{{- range $key, $value := $merged }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
