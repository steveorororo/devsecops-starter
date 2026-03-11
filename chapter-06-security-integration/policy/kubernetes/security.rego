package main

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("FAIL: Container '%s' must not run as privileged", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not has_run_as_non_root(container)
    msg := sprintf("FAIL: Container '%s' must set runAsNonRoot: true", [container.name])
}

has_run_as_non_root(container) {
    container.securityContext.runAsNonRoot == true
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not has_resource_limits(container)
    msg := sprintf("FAIL: Container '%s' must define resource limits", [container.name])
}

has_resource_limits(container) {
    container.resources.limits
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not drops_all_caps(container)
    msg := sprintf("FAIL: Container '%s' must drop ALL capabilities", [container.name])
}

drops_all_caps(container) {
    container.securityContext.capabilities.drop[_] == "ALL"
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not has_readonly_root(container)
    msg := sprintf("FAIL: Container '%s' must use readOnlyRootFilesystem: true", [container.name])
}

has_readonly_root(container) {
    container.securityContext.readOnlyRootFilesystem == true
}
