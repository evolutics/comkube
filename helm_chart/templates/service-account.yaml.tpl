{{ include "comkube" . }}
{{
(.Values.serviceAccount.create | ternary
  (dict
    "apiVersion" "v1"
    "kind" "ServiceAccount"
    "metadata" (dict
      "name" .helpers.serviceAccountName
      "labels" (merge .helpers.standardLabels .Values.serviceAccount.extraLabels)
      "annotations" .Values.serviceAccount.annotations
    )
    "automountServiceAccountToken" .Values.serviceAccount.automount
  )
  dict
) | toYaml
}}
