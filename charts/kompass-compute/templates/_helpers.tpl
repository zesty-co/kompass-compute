{{/*
Expand the name of the chart.
To fit the longest name possible, we truncate at 38 chars and trim any trailing dashes.
Component: General
*/}}
{{- define "kompass-compute.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 38 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
To fit the longest name possible, we truncate at 38 chars and trim any trailing dashes.
Some Kubernetes name fields are limited to 63 chars (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
Component: General
*/}}
{{- define "kompass-compute.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 38 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 38 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 38 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
Component: General
*/}}
{{- define "kompass-compute.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
Component: General
*/}}
{{- define "kompass-compute.labels" -}}
helm.sh/chart: {{ include "kompass-compute.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
Component: General
*/}}
{{- define "kompass-compute.selectorLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "kompass-compute.annotations.qubexConfigChecksum" -}}
checksum/qubex-config: {{ include (print $.Template.BasePath "/qubex-config.yaml") . | sha256sum }}
{{- end -}}

{{/*
Creates default affinity rules.
Component: General
*/}}
{{- define "kompass-compute.affinity" -}}
{{- if .affinity -}}
affinity:
  {{- toYaml .affinity | nindent 2 }}
{{- else if .useDefaultAffinity -}}
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: qubex.ai/qscaler-node
              operator: NotIn
              values:
                - "true"
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
                - {{ .name }}
            - key: app.kubernetes.io/component
              operator: In
              values:
                - {{ .component }}
        topologyKey: kubernetes.io/hostname
{{- end -}}
{{- end -}}

{{/*
defaultBool returns the default value if the given value is not boolean true/false.
Otherwise, returns the given value.
Usage: {{ include "kompass-compute.defaultBool" (dict "value" .Values.foo "default" true) }}
*/}}
{{- define "kompass-compute.defaultBool" -}}
{{- $v := .value -}}
{{- $d := .default -}}
{{- if kindIs "bool" $v -}}
  {{- $v -}}
{{- else if eq (toString $v | lower) "true" -}}
  true
{{- else if eq (toString $v | lower) "false" -}}
  false
{{- else -}}
  {{- $d -}}
{{- end -}}
{{- end -}}

{{/*
Kompass Insight Secret name
Component: General
*/}}
{{- define "kompass-compute.insightSecretName" -}}
{{ .Values.kompassInsightSecret }}
{{- end }}

{{/*
Creates the short name of the Cache controller.
Component: Cache
*/}}
{{- define "kompass-compute.cache.shortName" -}}
cache
{{- end }}

{{/*
Creates the name of the Cache controller.
Some Kubernetes name fields are limited to 63 chars (by the DNS naming spec).
Component: Cache
*/}}
{{- define "kompass-compute.cache.name" -}}
{{ printf "%s-%s" (include "kompass-compute.fullname" .) (include "kompass-compute.cache.shortName" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Creates the image of the Cache controller.
Component: Cache
*/}}
{{- define "kompass-compute.cache.image" -}}
{{ .Values.cache.image.repository }}:{{ (include "kompass-compute.cache.imageTag" .) }}
{{- end }}

{{/*
Creates the image tag of the Cache controller.
Component: Cache
*/}}
{{- define "kompass-compute.cache.imageTag" -}}
{{ coalesce .Values.cache.image.tag .Values.tag .Chart.AppVersion }}
{{- end }}

{{/*
Cache labels
Component: Cache
*/}}
{{- define "kompass-compute.cache.labels" -}}
{{ include "kompass-compute.cache.selectorLabels" . }}
{{ include "kompass-compute.labels" . }}
{{- end }}

{{/*
Cache selector labels
Component: Cache
*/}}
{{- define "kompass-compute.cache.selectorLabels" -}}
app.kubernetes.io/name: {{include "kompass-compute.cache.shortName" . }}
app.kubernetes.io/component: controller
{{ include "kompass-compute.selectorLabels" . }}
{{- end }}

{{/*
Create the name of the service account to use for Cache.
Component: Cache
*/}}
{{- define "kompass-compute.cache.serviceAccountName" -}}
{{- if .Values.cache.serviceAccount.create }}
{{- default (include "kompass-compute.cache.name" .) .Values.cache.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.cache.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Creates default affinity rules for Cache.
Component: Cache
*/}}
{{- define "kompass-compute.cache.affinity" -}}
{{ include "kompass-compute.affinity" (dict "affinity" .Values.cache.affinity "useDefaultAffinity" .Values.cache.useDefaultAffinity "name" (include "kompass-compute.cache.shortName" .) "component" "controller") -}}
{{- end }}

{{/*
Creates the short name of the Hiberscaler controller.
Component: Hiberscaler
*/}}
{{- define "kompass-compute.hiberscaler.shortName" -}}
hiberscaler
{{- end }}

{{/*
Creates the name of the Hiberscaler controller.
Some Kubernetes name fields are limited to 63 chars (by the DNS naming spec).
To fit the longest name possible, we truncate at 50 chars and trim any trailing dashes.
Component: Hiberscaler
*/}}
{{- define "kompass-compute.hiberscaler.name" -}}
{{ printf "%s-%s" (include "kompass-compute.fullname" .) (include "kompass-compute.hiberscaler.shortName" .) | trunc 50 | trimSuffix "-" }}
{{- end }}

{{/*
Creates the image of the Hiberscaler controller.
Component: Hiberscaler
*/}}
{{- define "kompass-compute.hiberscaler.image" -}}
{{ .Values.hiberscaler.image.repository }}:{{ (include "kompass-compute.hiberscaler.imageTag" .) }}
{{- end }}

{{/*
Creates the image tag of the Hiberscaler controller.
Component: Hiberscaler
*/}}
{{- define "kompass-compute.hiberscaler.imageTag" -}}
{{ coalesce .Values.hiberscaler.image.tag .Values.tag .Chart.AppVersion }}
{{- end }}

{{/*
Hiberscaler labels
Component: Hiberscaler
*/}}
{{- define "kompass-compute.hiberscaler.labels" -}}
{{ include "kompass-compute.hiberscaler.selectorLabels" . }}
{{ include "kompass-compute.labels" . }}
{{- end }}

{{/*
Hiberscaler selector labels
Component: Hiberscaler
*/}}
{{- define "kompass-compute.hiberscaler.selectorLabels" -}}
app.kubernetes.io/name: {{include "kompass-compute.hiberscaler.shortName" . }}
app.kubernetes.io/component: controller
{{ include "kompass-compute.selectorLabels" . }}
{{- end }}

{{/*
Create the name of the service account to use for Hiberscaler.
Component: Hiberscaler
*/}}
{{- define "kompass-compute.hiberscaler.serviceAccountName" -}}
{{- if .Values.hiberscaler.serviceAccount.create }}
{{- default (include "kompass-compute.hiberscaler.name" .) .Values.hiberscaler.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.hiberscaler.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the webhook certificate secret to use for Hiberscaler.
Component: Hiberscaler
*/}}
{{- define "kompass-compute.hiberscaler.webhookCertSecretName" -}}
{{include "kompass-compute.hiberscaler.name" . }}-webhook-cert
{{- end }}

{{/*
Create the name of the webhook service to use for Hiberscaler.
Component: Hiberscaler
*/}}
{{- define "kompass-compute.hiberscaler.webhookServiceName" -}}
{{include "kompass-compute.hiberscaler.name" . }}-webhook
{{- end }}

{{/*
Creates default affinity rules for Hiberscaler.
Component: Hiberscaler
*/}}
{{- define "kompass-compute.hiberscaler.affinity" -}}
{{ include "kompass-compute.affinity" (dict "affinity" .Values.hiberscaler.affinity "useDefaultAffinity" .Values.hiberscaler.useDefaultAffinity "name" (include "kompass-compute.hiberscaler.shortName" .) "component" "controller") -}}
{{- end }}

{{/*
Creates the short name of the Image Size Calculator controller.
Component: ImageSizeCalculator
*/}}
{{- define "kompass-compute.imageSizeCalculator.shortName" -}}
image-size-calculator
{{- end }}

{{/*
Creates the name of the Image Size Calculator controller.
Some Kubernetes name fields are limited to 63 chars (by the DNS naming spec).
Component: ImageSizeCalculator
*/}}
{{- define "kompass-compute.imageSizeCalculator.name" -}}
{{ printf "%s-%s" (include "kompass-compute.fullname" .) (include "kompass-compute.imageSizeCalculator.shortName" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Creates the image of the Image Size Calculator controller.
Component: ImageSizeCalculator
*/}}
{{- define "kompass-compute.imageSizeCalculator.image" -}}
{{ .Values.imageSizeCalculator.image.repository }}:{{ (include "kompass-compute.imageSizeCalculator.imageTag" .) }}
{{- end }}

{{/*
Creates the image tag of the Image Size Calculator controller.
Component: ImageSizeCalculator
*/}}
{{- define "kompass-compute.imageSizeCalculator.imageTag" -}}
{{ coalesce .Values.imageSizeCalculator.image.tag .Values.tag .Chart.AppVersion }}
{{- end }}

{{/*
Image Size Calculator labels
Component: ImageSizeCalculator
*/}}
{{- define "kompass-compute.imageSizeCalculator.labels" -}}
{{ include "kompass-compute.imageSizeCalculator.selectorLabels" . }}
{{ include "kompass-compute.labels" . }}
{{- end }}

{{/*
ImageSizeCalculator selector labels
Component: ImageSizeCalculator
*/}}
{{- define "kompass-compute.imageSizeCalculator.selectorLabels" -}}
app.kubernetes.io/name: {{include "kompass-compute.imageSizeCalculator.shortName" . }}
app.kubernetes.io/component: controller
{{ include "kompass-compute.selectorLabels" . }}
{{- end }}

{{/*
Create the name of the service account to use for ImageSizeCalculator.
Component: ImageSizeCalculator
*/}}
{{- define "kompass-compute.imageSizeCalculator.serviceAccountName" -}}
{{- if .Values.imageSizeCalculator.serviceAccount.create }}
{{- default (include "kompass-compute.imageSizeCalculator.name" .) .Values.imageSizeCalculator.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.imageSizeCalculator.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Creates default affinity rules for ImageSizeCalculator.
Component: ImageSizeCalculator
*/}}
{{- define "kompass-compute.imageSizeCalculator.affinity" -}}
{{ include "kompass-compute.affinity" (dict "affinity" .Values.imageSizeCalculator.affinity "useDefaultAffinity" .Values.imageSizeCalculator.useDefaultAffinity "name" (include "kompass-compute.imageSizeCalculator.shortName" .) "component" "controller") -}}
{{- end }}


{{/*
Creates the short name of the OTEL controller.
Component: OTEL
*/}}
{{- define "kompass-compute.otel.shortName" -}}
otel
{{- end }}

{{/*
Creates the name of the OTEL controller.
Some Kubernetes name fields are limited to 63 chars (by the DNS naming spec).
To fit the longest name possible, we truncate at 59 chars and trim any trailing dashes.
Component: OTEL
*/}}
{{- define "kompass-compute.otel.name" -}}
{{ printf "%s-%s" (include "kompass-compute.fullname" .) (include "kompass-compute.otel.shortName" .) | trunc 59 | trimSuffix "-" }}
{{- end }}

{{/*
Creates the image of the OTEL controller.
Component: OTEL
*/}}
{{- define "kompass-compute.otel.image" -}}
{{ .Values.otel.image.repository }}:{{ (include "kompass-compute.otel.imageTag" .) }}
{{- end }}

{{/*
Creates the image tag of the OTEL controller.
Component: OTEL
*/}}
{{- define "kompass-compute.otel.imageTag" -}}
{{ coalesce .Values.otel.image.tag .Values.tag .Chart.AppVersion }}
{{- end }}

{{/*
OTEL labels
Component: OTEL
*/}}
{{- define "kompass-compute.otel.labels" -}}
{{ include "kompass-compute.otel.selectorLabels" . }}
{{ include "kompass-compute.labels" . }}
{{- end }}

{{/*
OTEL selector labels
Component: OTEL
*/}}
{{- define "kompass-compute.otel.selectorLabels" -}}
app.kubernetes.io/name: {{include "kompass-compute.otel.shortName" . }}
app.kubernetes.io/component: monitoring
{{ include "kompass-compute.selectorLabels" . }}
{{- end }}

{{/*
Create the name of the service account to use for OTEL.
Component: OTEL
*/}}
{{- define "kompass-compute.otel.serviceAccountName" -}}
{{- if .Values.otel.serviceAccount.create }}
{{- default (include "kompass-compute.otel.name" .) .Values.otel.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.otel.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Creates default affinity rules for OTEL.
Component: OTEL
*/}}
{{- define "kompass-compute.otel.affinity" -}}
{{ include "kompass-compute.affinity" (dict "affinity" .Values.otel.affinity "useDefaultAffinity" .Values.otel.useDefaultAffinity "name" (include "kompass-compute.otel.shortName" .) "component" "monitoring") -}}
{{- end }}

{{/*
Create the name of the OTEL config to use.
Component: OTEL
*/}}
{{- define "kompass-compute.otel.configName" -}}
{{include "kompass-compute.otel.name" . }}-cfg
{{- end }}

{{/*
Create the metrics exporter value for OTEL.
Component: OTEL
*/}}
{{- define "kompass-compute.otel.metricsExporter" -}}
{{- $monitorRemote := default .Values.monitorRemote .Values.otel.monitorRemote -}}
{{- if eq ($monitorRemote | toString | lower) "true" -}}
coralogix
{{- else -}}
debug
{{- end -}}
{{- end -}}

{{/*
Creates the short name of the Snapshooter controller.
Component: Snapshooter
*/}}
{{- define "kompass-compute.snapshooter.shortName" -}}
snapshooter
{{- end }}

{{/*
Creates the name of the Snapshooter controller.
Some Kubernetes name fields are limited to 63 chars (by the DNS naming spec).
Component: Snapshooter
*/}}
{{- define "kompass-compute.snapshooter.name" -}}
{{ printf "%s-%s" (include "kompass-compute.fullname" .) (include "kompass-compute.snapshooter.shortName" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Creates the image of the Snapshooter controller.
Component: Snapshooter
*/}}
{{- define "kompass-compute.snapshooter.image" -}}
{{ .Values.snapshooter.image.repository }}:{{ (include "kompass-compute.snapshooter.imageTag" .) }}
{{- end }}

{{/*
Creates the image tag of the Snapshooter controller.
Component: Snapshooter
*/}}
{{- define "kompass-compute.snapshooter.imageTag" -}}
{{ coalesce .Values.snapshooter.image.tag .Values.tag .Chart.AppVersion }}
{{- end }}

{{/*
Snapshooter labels
Component: Snapshooter
*/}}
{{- define "kompass-compute.snapshooter.labels" -}}
{{ include "kompass-compute.snapshooter.selectorLabels" . }}
{{ include "kompass-compute.labels" . }}
{{- end }}

{{/*
Snapshooter selector labels
Component: Snapshooter
*/}}
{{- define "kompass-compute.snapshooter.selectorLabels" -}}
app.kubernetes.io/name: {{include "kompass-compute.snapshooter.shortName" . }}
app.kubernetes.io/component: monitoring
{{ include "kompass-compute.selectorLabels" . }}
{{- end }}

{{/*
Create the name of the service account to use for Snapshooter.
Component: Snapshooter
*/}}
{{- define "kompass-compute.snapshooter.serviceAccountName" -}}
{{- if .Values.snapshooter.serviceAccount.create }}
{{- default (include "kompass-compute.snapshooter.name" .) .Values.snapshooter.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.snapshooter.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Creates default affinity rules for Snapshooter.
Component: Snapshooter
*/}}
{{- define "kompass-compute.snapshooter.affinity" -}}
{{ include "kompass-compute.affinity" (dict "affinity" .Values.snapshooter.affinity "useDefaultAffinity" .Values.snapshooter.useDefaultAffinity "name" (include "kompass-compute.snapshooter.shortName" .) "component" "monitoring") -}}
{{- end }}

{{/*
Creates the short name of the Telemetry Manager controller.
Component: TelemetryManager
*/}}
{{- define "kompass-compute.telemetryManager.shortName" -}}
telemetry-manager
{{- end }}

{{/*
Creates the name of the Telemetry Manager controller.
Some Kubernetes name fields are limited to 63 chars (by the DNS naming spec).
Component: TelemetryManager
*/}}
{{- define "kompass-compute.telemetryManager.name" -}}
{{ printf "%s-%s" (include "kompass-compute.fullname" .) (include "kompass-compute.telemetryManager.shortName" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Creates the image of the Telemetry Manager controller.
Component: TelemetryManager
*/}}
{{- define "kompass-compute.telemetryManager.image" -}}
{{ .Values.telemetryManager.image.repository }}:{{ (include "kompass-compute.telemetryManager.imageTag" .) }}
{{- end }}

{{/*
Creates the image tag of the Telemetry Manager controller.
Component: TelemetryManager
*/}}
{{- define "kompass-compute.telemetryManager.imageTag" -}}
{{ coalesce .Values.telemetryManager.image.tag .Values.tag .Chart.AppVersion }}
{{- end }}

{{/*
Telemetry Manager labels
Component: TelemetryManager
*/}}
{{- define "kompass-compute.telemetryManager.labels" -}}
{{ include "kompass-compute.telemetryManager.selectorLabels" . }}
{{ include "kompass-compute.labels" . }}
{{- end }}

{{/*
Telemetry Manager selector labels
Component: TelemetryManager
*/}}
{{- define "kompass-compute.telemetryManager.selectorLabels" -}}
app.kubernetes.io/name: {{include "kompass-compute.telemetryManager.shortName" . }}
app.kubernetes.io/component: monitoring
{{ include "kompass-compute.selectorLabels" . }}
{{- end }}

{{/*
Create the name of the service account to use for TelemetryManager.
Component: TelemetryManager
*/}}
{{- define "kompass-compute.telemetryManager.serviceAccountName" -}}
{{- if .Values.telemetryManager.serviceAccount.create }}
{{- default (include "kompass-compute.telemetryManager.name" .) .Values.telemetryManager.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.telemetryManager.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Creates default affinity rules for TelemetryManager.
Component: TelemetryManager
*/}}
{{- define "kompass-compute.telemetryManager.affinity" -}}
{{ include "kompass-compute.affinity" (dict "affinity" .Values.telemetryManager.affinity "useDefaultAffinity" .Values.telemetryManager.useDefaultAffinity "name" (include "kompass-compute.telemetryManager.shortName" .) "component" "monitoring") -}}
{{- end }}

{{/*
Creates the short name of the Vector controller.
Component: Vector
*/}}
{{- define "kompass-compute.vector.shortName" -}}
vector
{{- end }}

{{/*
Creates the name of the Vector controller.
Some Kubernetes name fields are limited to 63 chars (by the DNS naming spec).
To fit the longest name possible, we truncate at 56 chars and trim any trailing dashes.
Component: Vector
*/}}
{{- define "kompass-compute.vector.name" -}}
{{ printf "%s-%s" (include "kompass-compute.fullname" .) (include "kompass-compute.vector.shortName" .) | trunc 56 | trimSuffix "-" }}
{{- end }}

{{/*
Creates the image of the Vector controller.
Component: Vector
*/}}
{{- define "kompass-compute.vector.image" -}}
{{ .Values.vector.image.repository }}:{{ (include "kompass-compute.vector.imageTag" .) }}
{{- end }}

{{/*
Creates the image tag of the Vector controller.
Vector is using it's own tag version.
Component: Vector
*/}}
{{- define "kompass-compute.vector.imageTag" -}}
{{ coalesce .Values.vector.image.tag .Values.tag .Chart.AppVersion }}
{{- end }}

{{/*
Creates the name of the Vector controller for normal nodes.
Some Kubernetes name fields are limited to 63 chars (by the DNS naming spec).
Component: Vector
*/}}
{{- define "kompass-compute.vector.normal.name" -}}
{{ printf "%s-normal" (include "kompass-compute.vector.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Creates the name of the Vector controller for QNode nodes.
Some Kubernetes name fields are limited to 63 chars (by the DNS naming spec).
Component: Vector
*/}}
{{- define "kompass-compute.vector.qNode.name" -}}
{{ printf "%s-qnode" (include "kompass-compute.vector.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Vector labels
Component: Vector
*/}}
{{- define "kompass-compute.vector.labels" -}}
{{ include "kompass-compute.vector.selectorLabels" . }}
{{ include "kompass-compute.labels" . }}
{{- end }}

{{/*
Vector selector labels
Component: Vector
*/}}
{{- define "kompass-compute.vector.selectorLabels" -}}
app.kubernetes.io/name: {{include "kompass-compute.vector.shortName" . }}
app.kubernetes.io/component: monitoring
{{ include "kompass-compute.selectorLabels" . }}
{{- end }}

{{/*
Create the name of the service account to use for Vector.
Component: Vector
*/}}
{{- define "kompass-compute.vector.serviceAccountName" -}}
{{- if .Values.vector.serviceAccount.create }}
{{- default (include "kompass-compute.vector.name" .) .Values.vector.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.vector.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Creates default affinity rules for Vector (normal nodes).
Component: Vector
*/}}
{{- define "kompass-compute.vector.normal.affinity" -}}
{{- if .Values.vector.normal.affinity -}}
affinity:
  {{- toYaml .Values.vector.normal.affinity | nindent 2 }}
{{- else if .Values.vector.normal.useDefaultAffinity -}}
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: qubex.ai/qscaler-node
              operator: NotIn
              values:
                - "true"
            - key: eks.amazonaws.com/compute-type
              operator: NotIn
              values:
                - fargate
{{- end -}}
{{- end -}}

{{/*
Creates default affinity rules for Vector (QNode nodes).
Component: Vector
*/}}
{{- define "kompass-compute.vector.qNode.affinity" -}}
{{- if .Values.vector.qNode.affinity -}}
affinity:
  {{- toYaml .Values.vector.qNode.affinity | nindent 2 }}
{{- else if .Values.vector.qNode.useDefaultAffinity -}}
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: qubex.ai/qscaler-node
              operator: In
              values:
                - "true"
{{- end -}}
{{- end -}}

{{/*
Create the name of the Vector configMap to use for normal nodes.
Some Kubernetes name fields are limited to 63 chars (by the DNS naming spec).
Component: Vector
*/}}
{{- define "kompass-compute.vector.normal.configMapName" -}}
{{ printf "%s-normal" (include "kompass-compute.vector.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the Vector configMap to use for QNode nodes.
Some Kubernetes name fields are limited to 63 chars (by the DNS naming spec).
Component: Vector
*/}}
{{- define "kompass-compute.vector.qNode.configMapName" -}}
{{ printf "%s-qnode" (include "kompass-compute.vector.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the short name of the Uninstaller.
Component: Uninstaller
*/}}
{{- define "kompass-compute.uninstaller.shortName" -}}
uninstaller
{{- end }}

{{/*
Create the name of the Uninstaller.
Some Kubernetes name fields are limited to 63 chars (by the DNS naming spec).
Component: Uninstaller
*/}}
{{- define "kompass-compute.uninstaller.name" -}}
{{ printf "%s-%s" (include "kompass-compute.fullname" .) (include "kompass-compute.uninstaller.shortName" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Creates the image of the Uninstaller.
Component: Uninstaller
*/}}
{{- define "kompass-compute.uninstaller.image" -}}
{{ .Values.uninstaller.image.repository }}:{{ (include "kompass-compute.uninstaller.imageTag" .) }}
{{- end }}

{{/*
Creates the image tag of the Uninstaller.
Component: Uninstaller
*/}}
{{- define "kompass-compute.uninstaller.imageTag" -}}
{{ coalesce .Values.uninstaller.image.tag .Values.tag .Chart.AppVersion }}
{{- end }}

{{/*
Uninstaller labels
Component: Uninstaller
*/}}
{{- define "kompass-compute.uninstaller.labels" -}}
{{ include "kompass-compute.uninstaller.selectorLabels" . }}
{{ include "kompass-compute.labels" . }}
{{- end }}

{{/*
Uninstaller selector labels
Component: Uninstaller
*/}}
{{- define "kompass-compute.uninstaller.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kompass-compute.uninstaller.shortName" . }}
app.kubernetes.io/component: uninstaller
{{ include "kompass-compute.selectorLabels" . }}
{{- end }}

{{/*
Create the name of the service account to use for Uninstaller.
Component: Uninstaller
*/}}
{{- define "kompass-compute.uninstaller.serviceAccountName" -}}
{{- if .Values.uninstaller.serviceAccount.create }}
{{- default (include "kompass-compute.uninstaller.name" .) .Values.uninstaller.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.uninstaller.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Creates default affinity rules for Uninstaller.
Component: Uninstaller
*/}}
{{- define "kompass-compute.uninstaller.affinity" -}}
{{- if .Values.uninstaller.affinity -}}
affinity:
  {{- toYaml .Values.uninstaller.affinity | nindent 2 }}
{{- end -}}
{{- end -}}


{{/*
Create the short name of the Secret Validator.
Component: SecretValidator
*/}}
{{- define "kompass-compute.secretValidator.shortName" -}}
secret-validator
{{- end }}

{{/*
Create the name of the Secret Validator.
Some Kubernetes name fields are limited to 63 chars (by the DNS naming spec).
Component: SecretValidator
*/}}
{{- define "kompass-compute.secretValidator.name" -}}
{{ printf "%s-%s" (include "kompass-compute.fullname" .) (include "kompass-compute.secretValidator.shortName" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Creates the image of the Secret Validator.
Component: SecretValidator
*/}}
{{- define "kompass-compute.secretValidator.image" -}}
{{ .Values.secretValidator.image.repository }}:{{ .Values.secretValidator.image.tag }}
{{- end }}

{{/*
Secret Validator labels
Component: SecretValidator
*/}}
{{- define "kompass-compute.secretValidator.labels" -}}
{{ include "kompass-compute.secretValidator.selectorLabels" . }}
{{ include "kompass-compute.labels" . }}
{{- end }}

{{/*
Secret Validator selector labels
Component: SecretValidator
*/}}
{{- define "kompass-compute.secretValidator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kompass-compute.secretValidator.shortName" . }}
app.kubernetes.io/component: pre-install-hook
{{ include "kompass-compute.selectorLabels" . }}
{{- end }}

{{/*
Create the name of the service account to use for Secret Validator.
Component: SecretValidator
*/}}
{{- define "kompass-compute.secretValidator.serviceAccountName" -}}
{{- if .Values.secretValidator.serviceAccount.create }}
{{- default (include "kompass-compute.secretValidator.name" .) .Values.secretValidator.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.secretValidator.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Creates default affinity rules for Secret Validator.
Component: SecretValidator
*/}}
{{- define "kompass-compute.secretValidator.affinity" -}}
{{- if .Values.secretValidator.affinity -}}
affinity:
  {{- toYaml .Values.secretValidator.affinity | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the QNode.
Some Kubernetes name fields are limited to 63 chars (by the DNS naming spec).
Component: QNode
*/}}
{{- define "kompass-compute.qNode.name" -}}
{{ printf "%s-qnode" (include "kompass-compute.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
QNode labels
Component: QNode
*/}}
{{- define "kompass-compute.qNode.labels" -}}
{{ include "kompass-compute.qNode.selectorLabels" . }}
{{ include "kompass-compute.labels" . }}
{{- end }}

{{/*
QNode selector labels
Component: QNode
*/}}
{{- define "kompass-compute.qNode.selectorLabels" -}}
app.kubernetes.io/name: qnode
app.kubernetes.io/component: node
{{ include "kompass-compute.selectorLabels" . }}
{{- end }}

{{/*
Create the short name of the Qubex Config.
Component: QubexConfig
*/}}
{{- define "kompass-compute.qubexConfig.shortName" -}}
qubex-config
{{- end }}

{{/*
Create the name of the Qubex Config.
Component: QubexConfig
*/}}
{{- define "kompass-compute.qubexConfig.name" -}}
qubex-config
{{- end }}

{{/*
Qubex Config labels
Component: QubexConfig
*/}}
{{- define "kompass-compute.qubexConfig.labels" -}}
{{ include "kompass-compute.qubexConfig.selectorLabels" . }}
{{ include "kompass-compute.labels" . }}
{{- end }}

{{/*
Qubex Config selector labels
Component: QubexConfig
*/}}
{{- define "kompass-compute.qubexConfig.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kompass-compute.qubexConfig.shortName" . }}
app.kubernetes.io/component: config
{{ include "kompass-compute.selectorLabels" . }}
{{- end }}

{{/*
Qubex Config
Component: QubexConfig
*/}}
{{- define "kompass-compute.qubexConfig.config" -}}
{{- $defaultConfig := dict
"nodeAgentHTTPAddressPrefix" (printf "https://kompass-compute.s3.eu-west-1.amazonaws.com/%s" (include "kompass-compute.hiberscaler.imageTag" .))
"cacheConfig" (dict
    "imageSizeCalculatorConfig" (dict
        "image" (include "kompass-compute.imageSizeCalculator.image" .)
        "serviceAccountName" (include "kompass-compute.imageSizeCalculator.serviceAccountName" .)
        "labels" ((include "kompass-compute.imageSizeCalculator.labels" . | default "{}") | fromYaml | merge (.Values.imageSizeCalculator.podLabels | default dict))
        "annotations" (.Values.imageSizeCalculator.podAnnotations | default dict)
        "pullSecrets" (.Values.imagePullSecrets | default list )
        "extraEnv" (.Values.imageSizeCalculator.extraEnv | default list )
        "podSecurityContext" (.Values.imageSizeCalculator.podSecurityContext | default dict)
        "securityContext" (.Values.imageSizeCalculator.securityContext | default dict)
        "resources" (.Values.imageSizeCalculator.resources | default dict)
        "nodeSelector" (.Values.imageSizeCalculator.nodeSelector | default dict)
        "tolerations" (.Values.imageSizeCalculator.tolerations | default list )
        "affinity" (get ((include "kompass-compute.imageSizeCalculator.affinity" . | default "affinity: {}") | fromYaml) "affinity")
    )
)
-}}
{{- $config := deepCopy .Values.qubexConfig -}}
{{- $config = merge $config $defaultConfig -}}
{{ toYaml $config }}
{{- end }}

{{/*
Create the name of the CachePullMapping.
Some Kubernetes name fields are limited to 63 chars (by the DNS naming spec).
To fit the longest name possible, we truncate at 50 chars and trim any trailing dashes.
Component: CachePullMapping
*/}}
{{- define "kompass-compute.cachePullMapping.name" -}}
{{ printf "%s-mapping" (include "kompass-compute.fullname" .) | trunc 50 | trimSuffix "-" }}
{{- end }}

{{/*
CachePullMapping labels
Component: CachePullMapping
*/}}
{{- define "kompass-compute.cachePullMapping.labels" -}}
{{ include "kompass-compute.cachePullMapping.selectorLabels" . }}
{{ include "kompass-compute.labels" . }}
{{- end }}

{{/*
CachePullMapping selector labels
Component: CachePullMapping
*/}}
{{- define "kompass-compute.cachePullMapping.selectorLabels" -}}
app.kubernetes.io/name: cache-pulling-mapping
app.kubernetes.io/component: cache
{{ include "kompass-compute.selectorLabels" . }}
{{- end }}
