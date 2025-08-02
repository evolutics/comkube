{{ define "comkube" }}

{{ $fullName := contains .Chart.Name .Release.Name | ternary
  .Release.Name
  (printf "%v-%v" .Release.Name .Chart.Name)
}}
{{ $selectorLabels := dict
  "app.kubernetes.io/name" .Chart.Name
  "app.kubernetes.io/instance" .Release.Name
}}
{{ $serviceAccountName := default
  (.Values.serviceAccount.create | ternary $fullName "default")
  .Values.serviceAccount.name
}}
{{ $standardLabels := merge
  (deepCopy $selectorLabels)
  (dict
    "helm.sh/chart" (printf "%v-%v" .Chart.Name .Chart.Version)
    "app.kubernetes.io/version" .Chart.AppVersion
    "app.kubernetes.io/managed-by" .Release.Service
  )
}}

{{ $_ := set . "helpers" (dict
  "fullName" $fullName
  "selectorLabels" $selectorLabels
  "serviceAccountName" $serviceAccountName
  "standardLabels" $standardLabels
) }}

{{ end }}
