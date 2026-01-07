package helm

# Disallow latest images
deny[msg] {
  container := input.spec.template.spec.containers[_]
  endswith(container.image, ":latest")
  msg := "Helm charts must not use :latest image tags"
}

# Require resource limits
deny[msg] {
  container := input.spec.template.spec.containers[_]
  not container.resources.limits
  msg := "Helm containers must define resource limits"
}
