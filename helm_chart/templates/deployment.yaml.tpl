{{ include "comkube" . }}
{{/* TODO: Consider using readiness probe. */}}
{{
(dict
  "apiVersion" "apps/v1"
  "kind" "Deployment"
  "metadata" (dict
    "name" .helpers.fullName
    "labels" (merge
      (deepCopy .helpers.standardLabels)
      (deepCopy .Values.extraDeploymentLabels)
    )
    "annotations" .Values.deploymentAnnotations
  )
  "spec" (dict
    "replicas" .Values.replicas
    "selector" (dict
      "matchLabels" .helpers.selectorLabels
    )
    "template" (dict
      "metadata" (dict
        "labels" (merge
          (deepCopy .helpers.standardLabels)
          (deepCopy .Values.extraPodLabels)
        )
        "annotations" .Values.podAnnotations
      )
      "spec" (dict
        "affinity" .Values.affinity
        "imagePullSecrets" .Values.imagePullSecrets
        "nodeSelector" .Values.nodeSelector
        "securityContext" .Values.podSecurityContext
        "serviceAccountName" .helpers.serviceAccountName
        "tolerations" .Values.tolerations
        "containers" (list
          (dict
            "name" .Chart.Name
            "image" (printf "%v:%v" .Values.image.repository .Chart.AppVersion)
            "imagePullPolicy" .Values.image.pullPolicy
            "resources" .Values.resources
            "securityContext" .Values.securityContext
            "env" (list
              (dict
                "name" "RUST_LOG"
                "value" "info,kube=debug,comkube=trace"
              )
            )
          )
        )
      )
    )
  )
) | toYaml
}}
