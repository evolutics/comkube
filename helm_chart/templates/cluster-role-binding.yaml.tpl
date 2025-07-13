{{ include "comkube" . }}
{{/* TODO: Follow Helm recommendations regarding RBAC. */}}
{{/* TODO: Support custom labels, annotations. */}}
{{/* TODO: Use fine-grained role instead. */}}
{{/* TODO: Use user namespace if service account not managed. */}}
{{
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
    "name" "cluster-admin"
    "apiGroup" "rbac.authorization.k8s.io"
  )
) | toYaml
}}
