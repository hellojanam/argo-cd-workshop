{{/*
Expand the name of the chart.
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
short name for cluster, without spaceship suffix
*/}}
{{- define "app.ShortName" -}}
{{- .Values.ShortName }}
{{- end }}

{{/*
common sync options
*/}}
{{- define "app.commonSyncOptions" -}}
- CreateNamespace=true
- PruneLast=true
{{- end }}

