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
