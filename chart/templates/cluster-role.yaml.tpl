{{ include "comkube" . }}
{{/* TODO: Support custom labels, annotations. */}}
{{ $editVerbs := list "create" "delete" "list" "patch" "watch" }}
{{
(.Values.rbac.create | ternary
  (dict
    "apiVersion" "rbac.authorization.k8s.io/v1"
    "kind" "ClusterRole"
    "metadata" (dict
      "name" .helpers.fullName
      "labels" .helpers.standardLabels
    )
    "rules" (list
      (dict
        "apiGroups" (list "")
        "resources" (list
          "buildconfigs"
          "configmaps"
          "persistentvolumeclaims"
          "pods"
          "replicationcontrollers"
          "routes"
          "secrets"
          "services"
        )
        "verbs" $editVerbs
      )
      (dict
        "apiGroups" (list "apps")
        "resources" (list "daemonsets" "deployments" "statefulsets")
        "verbs" $editVerbs
      )
      (dict
        "apiGroups" (list "apps.openshift.io")
        "resources" (list "deploymentconfigs")
        "verbs" $editVerbs
      )
      (dict
        "apiGroups" (list "autoscaling")
        "resources" (list "horizontalpodautoscalers")
        "verbs" $editVerbs
      )
      (dict
        "apiGroups" (list "batch")
        "resources" (list "cronjobs")
        "verbs" $editVerbs
      )
      (dict
        "apiGroups" (list "image.openshift.io")
        "resources" (list "imagestreams")
        "verbs" $editVerbs
      )
      (dict
        "apiGroups" (list "networking.k8s.io")
        "resources" (list "ingresses" "networkpolicies")
        "verbs" $editVerbs
      )

      (dict
        "apiGroups" (list "evolutics.info")
        "resources" (list "composeapplications")
        "verbs" (list "get" "list" "watch")
      )
    )
  )
  nil
) | toYaml
}}
