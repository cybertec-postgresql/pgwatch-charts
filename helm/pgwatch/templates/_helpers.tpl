{{/*
==============================================================================
  pgwatch Helm Chart – Template Helpers
==============================================================================
*/}}

{{/*
pgwatch.commonLabels
  Internal helper for chart-managed resource metadata labels.

  User-facing label semantics are documented in README.md. Keep this comment
  focused on the helper calling convention and Helm context handling.

  The helper receives a dict because Helm's include function accepts only one
  data argument. The dict carries both:
    - root:      the original chart root context, so the helper can access
                 .Release.Name and .Release.Service even when called from
                 inside a range/with block where the local dot (.) changed
    - component: the logical component/role to render in
                 app.kubernetes.io/component

  Inputs:
    - root:      the chart root context (.)
    - component: logical component/role for the resource

  Usage:
    {{- include "pgwatch.commonLabels" (dict "root" . "component" "pgwatch") | nindent 4 }}
    {{- include "pgwatch.commonLabels" (dict "root" $ "component" "grafana") | nindent 4 }}  # inside range/with
*/}}
{{- define "pgwatch.commonLabels" -}}
app.kubernetes.io/name: pgwatch
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
helm.sh/chart: "{{ .root.Chart.Name }}-{{ .root.Chart.Version | replace "+" "_" }}"
vendor: opensource.cybertec
{{- end }}

{{/*
pgwatch.selectorLabels
  Internal helper for the stable label subset used by pod selectors.

  Use this helper only where Kubernetes matches/selects pods, such as:
    - spec.selector.matchLabels on Deployments/StatefulSets
    - spec.selector on Services

  Keep this as a subset of pgwatch.commonLabels. The selected pod template must
  carry these labels as well.

  Inputs and calling convention match pgwatch.commonLabels.
*/}}
{{- define "pgwatch.selectorLabels" -}}
app.kubernetes.io/name: pgwatch
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
pgwatch.podSecurityContext
  Renders the pod-level securityContext for a given component.

  Inputs:
    - global:    .Values.securityContext
    - component: <component>.securityContext
                 (e.g. .Values.pgwatch.securityContext,
                       .Values.pgwatch.postgres.securityContext)

  Usage:
    {{- include "pgwatch.podSecurityContext" (dict "global" .Values.securityContext "component" .Values.pgwatch.securityContext) | nindent 6 }}

  Behavior:
    - global.enabled true  -> merge component.pod on top of global.pod (component overrides).
    - global.enabled false -> render component.pod as-is, if defined.
    - Both empty           -> render nothing.

  mergeOverwrite is used instead of merge, so that the component values override the global ones.
*/}}
{{- define "pgwatch.podSecurityContext" -}}
{{- $component := .component | default dict -}}
{{- $rawComponentPod := $component.pod -}}
{{- $globalPod    := .global.pod    | default dict -}}
{{- $componentPod := $rawComponentPod | default dict -}}
{{- if .global.enabled -}}
{{- $merged := mergeOverwrite (deepCopy $globalPod) (deepCopy $componentPod) -}}
{{- if $merged }}
securityContext:
  {{- toYaml $merged | nindent 2 }}
{{- end }}
{{- else if $rawComponentPod }}
securityContext:
  {{- toYaml $componentPod | nindent 2 }}
{{- end }}
{{- end }}

{{/*
pgwatch.containerSecurityContext
  Renders the container-level securityContext for a given component.

  Inputs:
    - global:    .Values.securityContext
    - component: <component>.securityContext
                 (e.g. .Values.pgwatch.securityContext,
                       .Values.pgwatch.postgres.securityContext)

  Usage:
    {{- include "pgwatch.containerSecurityContext" (dict "global" .Values.securityContext "component" .Values.pgwatch.securityContext) | nindent 10 }}

  Behavior:
    - global.enabled true  -> merge component.container on top of global.container (component wins).
    - global.enabled false -> render component.container as-is, if defined.
    - Both empty           -> render nothing.

  mergeOverwrite is used instead of merge, so that the component values override the global ones.
*/}}
{{- define "pgwatch.containerSecurityContext" -}}
{{- $component := .component | default dict -}}
{{- $rawComponentContainer := $component.container -}}
{{- $globalContainer    := .global.container    | default dict -}}
{{- $componentContainer := $rawComponentContainer | default dict -}}
{{- if .global.enabled -}}
{{- $merged := mergeOverwrite (deepCopy $globalContainer) (deepCopy $componentContainer) -}}
{{- if $merged }}
securityContext:
  {{- toYaml $merged | nindent 2 }}
{{- end }}
{{- else if $rawComponentContainer }}
securityContext:
  {{- toYaml $componentContainer | nindent 2 }}
{{- end }}
{{- end }}

{{/*
pgwatch.dbHost
  Returns the hostname of the metrics database service.

  Behavior:
    - timescaledb.enabled true           -> "<release-name>-timescaledb"                   (subchart service)
    - useExistingDatabase configured     -> useExistingDatabase.endpoint                   (external instance)
    - otherwise                          -> "postgres-svc"                                 (built-in StatefulSet)

  Usage:
    {{ include "pgwatch.dbHost" . }}
*/}}
{{- define "pgwatch.dbHost" -}}
{{- if .Values.timescaledb.enabled -}}
{{ .Release.Name }}-timescaledb
{{- else if include "pgwatch.postgres.hasUseExistingDatabase" . -}}
{{ include "pgwatch.postgres.useExistingDatabase.endpoint" . }}
{{- else -}}
postgres-svc
{{- end -}}
{{- end }}

{{/*
Backward-compatible value helpers for keys renamed from snake_case to camelCase.
Legacy snake_case values take precedence when explicitly present so existing
values files keep working until support is removed in the next major version.
*/}}
{{- define "pgwatch.postgres.enablePgSink" -}}
{{- $pg := .Values.pgwatch.postgres -}}
{{- if hasKey $pg "enable_pg_sink" -}}{{ $pg.enable_pg_sink }}{{- else -}}{{ $pg.enablePgSink }}{{- end -}}
{{- end }}

{{- define "pgwatch.postgres.createMetricDatabase" -}}
{{- $pg := .Values.pgwatch.postgres -}}
{{- if hasKey $pg "create_metric_database" -}}{{ $pg.create_metric_database }}{{- else -}}{{ $pg.createMetricDatabase }}{{- end -}}
{{- end }}

{{- define "pgwatch.postgres.settings.retentionDays" -}}
{{- $settings := .Values.pgwatch.postgres.settings | default dict -}}
{{- if hasKey $settings "retention_days" -}}{{ $settings.retention_days }}{{- else -}}{{ $settings.retentionDays }}{{- end -}}
{{- end }}

{{- define "pgwatch.postgres.newPgDatabase.image" -}}
{{- $pg := .Values.pgwatch.postgres -}}
{{- $db := $pg.newPgDatabase | default dict -}}
{{- if hasKey $pg "new_pg_database" -}}
  {{- $db = $pg.new_pg_database | default dict -}}
{{- end -}}
{{- $db.image -}}
{{- end }}

{{- define "pgwatch.postgres.newPgDatabase.volume.size" -}}
{{- $pg := .Values.pgwatch.postgres -}}
{{- $db := $pg.newPgDatabase | default dict -}}
{{- if hasKey $pg "new_pg_database" -}}
  {{- $db = $pg.new_pg_database | default dict -}}
{{- end -}}
{{- ($db.volume | default dict).size -}}
{{- end }}

{{- define "pgwatch.postgres.newPgDatabase.volume.storageClass" -}}
{{- $pg := .Values.pgwatch.postgres -}}
{{- $db := $pg.newPgDatabase | default dict -}}
{{- if hasKey $pg "new_pg_database" -}}
  {{- $db = $pg.new_pg_database | default dict -}}
{{- end -}}
{{- ($db.volume | default dict).storageClass -}}
{{- end }}

{{- define "pgwatch.postgres.hasUseExistingDatabase" -}}
{{- $pg := .Values.pgwatch.postgres -}}
{{- if or $pg.useExistingDatabase $pg.use_existing_database -}}true{{- end -}}
{{- end }}

{{- define "pgwatch.postgres.useExistingDatabase.endpoint" -}}
{{- $pg := .Values.pgwatch.postgres -}}
{{- $db := $pg.useExistingDatabase | default $pg.use_existing_database | default dict -}}
{{- $db.endpoint -}}
{{- end }}

{{- define "pgwatch.postgres.useExistingDatabase.port" -}}
{{- $pg := .Values.pgwatch.postgres -}}
{{- $db := $pg.useExistingDatabase | default $pg.use_existing_database | default dict -}}
{{- $db.port -}}
{{- end }}

{{- define "pgwatch.postgres.useExistingDatabase.database" -}}
{{- $pg := .Values.pgwatch.postgres -}}
{{- $db := $pg.useExistingDatabase | default $pg.use_existing_database | default dict -}}
{{- $db.database -}}
{{- end }}

{{- define "pgwatch.postgres.useExistingDatabase.sslmode" -}}
{{- $pg := .Values.pgwatch.postgres -}}
{{- $db := $pg.useExistingDatabase | default $pg.use_existing_database | default dict -}}
{{- $db.sslmode -}}
{{- end }}

{{- define "pgwatch.postgres.useExistingDatabase.grafanaDatabase" -}}
{{- $pg := .Values.pgwatch.postgres -}}
{{- $db := $pg.useExistingDatabase | default $pg.use_existing_database | default dict -}}
{{- if hasKey $db "grafana_database" -}}{{ $db.grafana_database }}{{- else -}}{{ $db.grafanaDatabase | default "pgwatch_grafana" }}{{- end -}}
{{- end }}

{{- define "pgwatch.postgres.useExistingDatabase.username" -}}
{{- $pg := .Values.pgwatch.postgres -}}
{{- $db := $pg.useExistingDatabase | default $pg.use_existing_database | default dict -}}
{{- $db.username -}}
{{- end }}

{{- define "pgwatch.postgres.useExistingDatabase.password" -}}
{{- $pg := .Values.pgwatch.postgres -}}
{{- $db := $pg.useExistingDatabase | default $pg.use_existing_database | default dict -}}
{{- $db.password -}}
{{- end }}

{{- define "pgwatch.prometheus.enablePromSink" -}}
{{- $prom := .Values.pgwatch.prometheus -}}
{{- if hasKey $prom "enable_prom_sink" -}}{{ $prom.enable_prom_sink }}{{- else -}}{{ $prom.enablePromSink }}{{- end -}}
{{- end }}

{{- define "pgwatch.prometheus.newPrometheus.createPrometheus" -}}
{{- $prom := .Values.pgwatch.prometheus -}}
{{- $newProm := $prom.newPrometheus | default dict -}}
{{- if hasKey $prom "new_prometheus" -}}
  {{- $newProm = $prom.new_prometheus | default dict -}}
{{- end -}}
{{- if hasKey $newProm "create_prometheus" -}}{{ $newProm.create_prometheus }}{{- else -}}{{ $newProm.createPrometheus }}{{- end -}}
{{- end }}

{{- define "pgwatch.prometheus.newPrometheus.image" -}}
{{- $prom := .Values.pgwatch.prometheus -}}
{{- $newProm := $prom.newPrometheus | default dict -}}
{{- if hasKey $prom "new_prometheus" -}}
  {{- $newProm = $prom.new_prometheus | default dict -}}
{{- end -}}
{{- $newProm.image -}}
{{- end }}

{{- define "pgwatch.prometheus.newPrometheus.settings.retentionDays" -}}
{{- $prom := .Values.pgwatch.prometheus -}}
{{- $newProm := $prom.newPrometheus | default dict -}}
{{- if hasKey $prom "new_prometheus" -}}
  {{- $newProm = $prom.new_prometheus | default dict -}}
{{- end -}}
{{- $settings := $newProm.settings | default dict -}}
{{- if hasKey $settings "retention_days" -}}{{ $settings.retention_days }}{{- else -}}{{ $settings.retentionDays }}{{- end -}}
{{- end }}

{{- define "pgwatch.prometheus.newPrometheus.volume.size" -}}
{{- $prom := .Values.pgwatch.prometheus -}}
{{- $newProm := $prom.newPrometheus | default dict -}}
{{- if hasKey $prom "new_prometheus" -}}
  {{- $newProm = $prom.new_prometheus | default dict -}}
{{- end -}}
{{- ($newProm.volume | default dict).size -}}
{{- end }}

{{- define "pgwatch.prometheus.newPrometheus.volume.storageClass" -}}
{{- $prom := .Values.pgwatch.prometheus -}}
{{- $newProm := $prom.newPrometheus | default dict -}}
{{- if hasKey $prom "new_prometheus" -}}
  {{- $newProm = $prom.new_prometheus | default dict -}}
{{- end -}}
{{- ($newProm.volume | default dict).storageClass -}}
{{- end }}

{{- define "pgwatch.grafana.enableGrafana" -}}
{{- $grafana := .Values.pgwatch.grafana -}}
{{- if hasKey $grafana "enable_grafana" -}}{{ $grafana.enable_grafana }}{{- else -}}{{ $grafana.enableGrafana }}{{- end -}}
{{- end }}

{{- define "pgwatch.grafana.enableDatasources.postgres" -}}
{{- $grafana := .Values.pgwatch.grafana -}}
{{- $ds := $grafana.enableDatasources | default dict -}}
{{- if hasKey $grafana "enable_datasources" -}}
  {{- $ds = $grafana.enable_datasources | default dict -}}
{{- end -}}
{{- $ds.postgres -}}
{{- end }}

{{- define "pgwatch.grafana.enableDatasources.prometheus" -}}
{{- $grafana := .Values.pgwatch.grafana -}}
{{- $ds := $grafana.enableDatasources | default dict -}}
{{- if hasKey $grafana "enable_datasources" -}}
  {{- $ds = $grafana.enable_datasources | default dict -}}
{{- end -}}
{{- $ds.prometheus -}}
{{- end }}

{{/*
pgwatch.isTrue
  Returns the string "true" when the input is either the native boolean true
  or the legacy string value "true". Returns an empty string otherwise.

  Usage:
    {{- if include "pgwatch.isTrue" .Values.some.path }}
*/}}
{{- define "pgwatch.isTrue" -}}
{{- $v := . -}}
{{- if kindIs "bool" $v -}}
  {{- if $v -}}
true
  {{- end -}}
{{- else if eq (toString $v) "true" -}}
true
{{- end -}}
{{- end }}

{{/*
pgwatch.isLegacyBoolString
  Returns the string "true" when the input is a legacy string boolean
  ("true" or "false"). Returns an empty string otherwise.
*/}}
{{- define "pgwatch.isLegacyBoolString" -}}
{{- $v := . -}}
{{- if and (kindIs "string" $v) (or (eq $v "true") (eq $v "false")) -}}
true
{{- end -}}
{{- end }}

{{/*
pgwatch.hasLegacyBoolValues
  Returns the string "true" when any supported boolean value is still passed as
  a legacy string ("true" / "false"). Used for deprecation notices.
*/}}
{{- define "pgwatch.hasLegacyBoolValues" -}}
{{- $pg := .Values.pgwatch.postgres -}}
{{- $prom := .Values.pgwatch.prometheus -}}
{{- $newProm := $prom.newPrometheus | default dict -}}
{{- if hasKey $prom "new_prometheus" -}}
  {{- $newProm = $prom.new_prometheus | default dict -}}
{{- end -}}
{{- $grafana := .Values.pgwatch.grafana -}}
{{- $ds := $grafana.enableDatasources | default dict -}}
{{- if hasKey $grafana "enable_datasources" -}}
  {{- $ds = $grafana.enable_datasources | default dict -}}
{{- end -}}
{{- $enablePgSink := $pg.enablePgSink -}}
{{- if hasKey $pg "enable_pg_sink" -}}{{- $enablePgSink = $pg.enable_pg_sink -}}{{- end -}}
{{- $createMetricDatabase := $pg.createMetricDatabase -}}
{{- if hasKey $pg "create_metric_database" -}}{{- $createMetricDatabase = $pg.create_metric_database -}}{{- end -}}
{{- $enablePromSink := $prom.enablePromSink -}}
{{- if hasKey $prom "enable_prom_sink" -}}{{- $enablePromSink = $prom.enable_prom_sink -}}{{- end -}}
{{- $createPrometheus := $newProm.createPrometheus -}}
{{- if hasKey $newProm "create_prometheus" -}}{{- $createPrometheus = $newProm.create_prometheus -}}{{- end -}}
{{- $enableGrafana := $grafana.enableGrafana -}}
{{- if hasKey $grafana "enable_grafana" -}}{{- $enableGrafana = $grafana.enable_grafana -}}{{- end -}}
{{- $values := list $enablePgSink $createMetricDatabase $enablePromSink $createPrometheus $enableGrafana $ds.postgres $ds.prometheus -}}
{{- $state := dict "hasLegacy" false -}}
{{- range $values -}}
  {{- if include "pgwatch.isLegacyBoolString" . -}}
    {{- $_ := set $state "hasLegacy" true -}}
  {{- end -}}
{{- end -}}
{{- if $state.hasLegacy -}}
true
{{- end -}}
{{- end }}

{{/*
pgwatch.credentialSecretName
  Name of the Secret that stores the pgwatch application user credentials.
*/}}
{{- define "pgwatch.credentialSecretName" -}}
{{- (.Values.pgwatch.postgres.credentials | default dict).existingSecret
    | default "pgwatch-postgresql-secret-pgwatch" -}}
{{- end }}

{{/*
pgwatch.credentialUsernameKey
  Key containing the pgwatch username in the credential secret.
*/}}
{{- define "pgwatch.credentialUsernameKey" -}}
{{- (.Values.pgwatch.postgres.credentials | default dict).usernameKey
    | default "username" -}}
{{- end }}

{{/*
pgwatch.credentialPasswordKey
  Key containing the pgwatch password in the credential secret.
*/}}
{{- define "pgwatch.credentialPasswordKey" -}}
{{- (.Values.pgwatch.postgres.credentials | default dict).passwordKey
    | default "password" -}}
{{- end }}

{{/*
pgwatch.adminCredentialSecretName
  Name of the Secret that stores the built-in postgres admin credentials.
*/}}
{{- define "pgwatch.adminCredentialSecretName" -}}
{{- (.Values.pgwatch.postgres.adminCredentials | default dict).existingSecret
    | default "pgwatch-postgresql-secret-postgres" -}}
{{- end }}

{{/*
pgwatch.adminCredentialPasswordKey
  Key containing the built-in postgres admin password.
*/}}
{{- define "pgwatch.adminCredentialPasswordKey" -}}
{{- (.Values.pgwatch.postgres.adminCredentials | default dict).passwordKey
    | default "password" -}}
{{- end }}

{{/*
pgwatch.timescaledbAdminPasswordKey
  Key containing the TimescaleDB postgres admin password.
*/}}
{{- define "pgwatch.timescaledbAdminPasswordKey" -}}
{{- ((.Values.timescaledb.auth | default dict).secretKeys | default dict).adminPasswordKey
    | default "postgres-password" -}}
{{- end }}

{{/*
pgwatch.hasLegacyExternalDbInlineCredentials
  True when deprecated external DB username/password fields are still used.
*/}}
{{- define "pgwatch.hasLegacyExternalDbInlineCredentials" -}}
{{- $pg := .Values.pgwatch.postgres -}}
{{- $existingDb := $pg.useExistingDatabase | default $pg.use_existing_database | default dict -}}
{{- if or $existingDb.username $existingDb.password -}}
true
{{- end -}}
{{- end }}

{{- define "pgwatch.hasLegacyRenamedValues" -}}
{{- $pg := .Values.pgwatch.postgres -}}
{{- $prom := .Values.pgwatch.prometheus -}}
{{- $newProm := $prom.new_prometheus | default dict -}}
{{- $grafana := .Values.pgwatch.grafana -}}
{{- $legacyDs := $grafana.enable_datasources | default dict -}}
{{- if or
  (hasKey $pg "enable_pg_sink")
  (hasKey ($pg.settings | default dict) "retention_days")
  (hasKey $pg "create_metric_database")
  (hasKey $pg "new_pg_database")
  (hasKey $pg "use_existing_database")
  (hasKey ($pg.useExistingDatabase | default $pg.use_existing_database | default dict) "grafana_database")
  (hasKey $prom "enable_prom_sink")
  (hasKey $prom "new_prometheus")
  (hasKey $newProm "create_prometheus")
  (hasKey (($newProm.settings | default dict)) "retention_days")
  (hasKey $grafana "enable_grafana")
  (hasKey $grafana "enable_datasources")
  (hasKey $legacyDs "postgres")
  (hasKey $legacyDs "prometheus")
-}}
true
{{- end -}}
{{- end }}
