{{/* Expand the name of the chart. */}}
{{- define "chirpstack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Create a default fully qualified app name. */}}
{{- define "chirpstack.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/* Create chart name and version as used by the chart label. */}}
{{- define "chirpstack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Common labels */}}
{{- define "chirpstack.labels" -}}
helm.sh/chart: {{ include "chirpstack.chart" . }}
{{ include "chirpstack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels */}}
{{- define "chirpstack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chirpstack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Service account name */}}
{{- define "chirpstack.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "chirpstack.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}



{{/* Gateway Bridge fullname */}}                                                                                               
{{- define "gatewaybridge.fullname" -}}                                                                                         
{{- printf "%s-gateway-bridge" (include "chirpstack.fullname" .) | trunc 63 | trimSuffix "-" }}                                 
{{- end }}                                                                                                                      
                                                                                                                                
{{/* Gateway Bridge Basicstation fullname */}}                                                                                  
{{- define "gatewaybridgebasicstation.fullname" -}}                                                                             
{{- printf "%s-gateway-bridge-basicstation" (include "chirpstack.fullname" .) | trunc 63 | trimSuffix "-" }}                    
{{- end }}                                                                                                                      
                                                                                                                                
{{/* Rest API fullname */}}                                                                                                     
{{- define "restapi.fullname" -}}                                                                                               
{{- printf "%s-rest-api" (include "chirpstack.fullname" .) | trunc 63 | trimSuffix "-" }}                                       
{{- end }}      




{{/* Gateway Bridge selector labels */}}                                                                                        
{{- define "gatewaybridge.selectorLabels" -}}                                                                                   
{{ include "chirpstack.selectorLabels" . }}                                                                                     
app.kubernetes.io/component: gateway-bridge                                                                                     
{{- end }}                                                                                                                      
                                                                                                                                
{{/* Gateway Bridge Basicstation selector labels */}}                                                                           
{{- define "gatewaybridgebasicstation.selectorLabels" -}}                                                                       
{{ include "chirpstack.selectorLabels" . }}                                                                                     
app.kubernetes.io/component: gateway-bridge-basicstation                                                                        
{{- end }}                                                                                                                      
                                                                                                                                
{{/* Rest API selector labels */}}                                                                                              
{{- define "restapi.selectorLabels" -}}                                                                                         
{{ include "chirpstack.selectorLabels" . }}                                                                                     
app.kubernetes.io/component: rest-api                                                                                           
{{- end }}  


