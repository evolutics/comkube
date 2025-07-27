{{ include "comkube" . }}
{{/* TODO: Support custom labels, annotations. */}}
{{/* TODO: Use user namespace if service account not managed. */}}
{{ toYaml (.Values.rbac.create | ternary
  (dict
    "apiVersion" "rbac.authorization.k8s.io/v1"
    "kind" "ClusterRoleBinding"
    "metadata" (dict
      "name" .helpers.fullName
      "labels" .helpers.standardLabels
    )
    "subjects" (list
      (dict
        "kind" "ServiceAccount"
        "name" .helpers.serviceAccountName
        "namespace" .Release.Namespace
      )
    )
    "roleRef" (dict
      "kind" "ClusterRole"
      "name" .helpers.fullName
      "apiGroup" "rbac.authorization.k8s.io"
    )
  )
  nil
) }}
