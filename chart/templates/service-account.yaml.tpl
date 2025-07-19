{{ include "comkube" . }}
{{
(.Values.serviceAccount.create | ternary
  (dict
    "apiVersion" "v1"
    "kind" "ServiceAccount"
    "metadata" (dict
      "name" .helpers.serviceAccountName
      "labels" (merge
        (deepCopy .helpers.standardLabels)
        (deepCopy .Values.serviceAccount.extraLabels)
      )
      "annotations" .Values.serviceAccount.annotations
    )
    "automountServiceAccountToken" true
  )
  nil
) | toYaml
}}
