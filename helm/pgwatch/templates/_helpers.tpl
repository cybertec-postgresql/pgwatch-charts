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
{{- else if .Values.pgwatch.postgres.useExistingDatabase -}}
{{ .Values.pgwatch.postgres.useExistingDatabase.endpoint }}
{{- else -}}
postgres-svc
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
