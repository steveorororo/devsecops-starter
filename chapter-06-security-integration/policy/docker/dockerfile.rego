package docker

import rego.v1

# Deny running as root (no USER instruction)
deny contains msg if {
    input[i].Cmd == "from"
    not has_user_instruction
    msg := "FAIL: Dockerfile must include a USER instruction to run as non-root"
}

has_user_instruction if {
    input[i].Cmd == "user"
}

# Deny use of latest tag
deny contains msg if {
    input[i].Cmd == "from"
    val := input[i].Value[0]
    contains(val, ":latest")
    msg := sprintf("FAIL: Do not use ':latest' tag. Pin image by digest. Found: %s", [val])
}

# Deny hardcoded secrets in ENV
deny contains msg if {
    input[i].Cmd == "env"
    val := input[i].Value[1]
    contains(lower(val), "password")
    msg := sprintf("FAIL: Possible secret in ENV instruction: %s", [input[i].Value[0]])
}

deny contains msg if {
    input[i].Cmd == "env"
    val := input[i].Value[0]
    contains(lower(val), "secret")
    msg := sprintf("FAIL: Possible secret in ENV instruction: %s", [val])
}

# Deny installing attack tools
deny contains msg if {
    input[i].Cmd == "run"
    val := input[i].Value[0]
    tools := ["nmap", "tcpdump", "strace", "netcat", "ssh ", "telnet"]
    tool := tools[_]
    contains(val, tool)
    msg := sprintf("FAIL: Prohibited tool installation detected: %s", [tool])
}
