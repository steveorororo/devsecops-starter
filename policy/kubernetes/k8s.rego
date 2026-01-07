package kubernetes

# ----------------------------------
# Disallow :latest image tag
# ----------------------------------
deny[msg] {
  container := input.spec.template.spec.containers[_]
  endswith(container.image, ":latest")
  msg := "Kubernetes containers must not use :latest image tag"
}

# ----------------------------------
# Require resource limits
# ----------------------------------
deny[msg] {
  container := input.spec.template.spec.containers[_]
  not container.resources.limits
  msg := "Kubernetes containers must define resource limits"
}

# ----------------------------------
# Disallow privileged containers
# ----------------------------------
deny[msg] {
  container := input.spec.template.spec.containers[_]
  container.securityContext.privileged == true
  msg := "Privileged containers are forbidden"
}

# ----------------------------------
# Require runAsNonRoot
# ----------------------------------
deny[msg] {
  pod := input.spec.template.spec
  not pod.securityContext.runAsNonRoot
  msg := "Pods must set runAsNonRoot: true"
}
