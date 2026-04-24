{{/*
==============================================================================
  pgwatch Helm Chart – Template Helpers
==============================================================================
*/}}

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
    - use_existing_database configured   -> use_existing_database.endpoint                 (external instance)
    - otherwise                          -> "postgres-svc"                                 (built-in StatefulSet)

  Usage:
    {{ include "pgwatch.dbHost" . }}
*/}}
{{- define "pgwatch.dbHost" -}}
{{- if .Values.timescaledb.enabled -}}
{{ .Release.Name }}-timescaledb
{{- else if .Values.pgwatch.postgres.use_existing_database -}}
{{ .Values.pgwatch.postgres.use_existing_database.endpoint }}
{{- else -}}
postgres-svc
{{- end -}}
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
{{- $values := list
  .Values.pgwatch.postgres.enable_pg_sink
  .Values.pgwatch.postgres.create_metric_database
  .Values.pgwatch.prometheus.enable_prom_sink
  .Values.pgwatch.prometheus.new_prometheus.create_prometheus
  .Values.pgwatch.grafana.enable_grafana
  .Values.pgwatch.grafana.enable_datasources.postgres
  .Values.pgwatch.grafana.enable_datasources.prometheus
-}}
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
