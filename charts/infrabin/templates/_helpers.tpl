{{- define "infrabin.name" -}}
infrabin
{{- end -}}

{{- define "infrabin.fullname" -}}
{{- printf "%s" (include "infrabin.name" .) -}}
{{- end -}}
