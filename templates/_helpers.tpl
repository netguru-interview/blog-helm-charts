{{/* vim: set filetype=mustache: */}}
List the environmental variables related to the project
*/}}

{{- define "env.project" -}}
- name: FLASK_APP
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-configuration
      key: FLASK_APP
- name: FLASK_ENV
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-configuration
      key: FLASK_ENV
- name: PROJECT_NAME
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-configuration
      key: PROJECT_NAME
{{- end -}}


{{/*
List the environmental variables related to postgresql
*/}}

{{- define "env.postgresql" -}}
- name: POSTGRESQL_DATABASE
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-configuration
      key: POSTGRESQL_DATABASE
- name: POSTGRESQL_USER
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-configuration
      key: POSTGRESQL_USER
- name: POSTGRESQL_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-postgresql
      key: postgresql-password
{{- end -}}
