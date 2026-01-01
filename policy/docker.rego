package main

# ----------------------------------
# Rule: Do not use :latest images
# ----------------------------------
deny[msg] {
  some i
  input[i].Cmd == "FROM"
  contains(input[i].Value[0], ":latest")
  msg := "Using Docker :latest tag is forbidden"
}

# ----------------------------------
# Rule: Container must not run as root
# ----------------------------------
deny[msg] {
  not has_user
  msg := "USER must be explicitly set (do not run as root)"
}

has_user {
  some i
  lower(input[i].Cmd) == "user"
}

# ----------------------------------
# Rule: Do not expose SSH
# ----------------------------------
deny[msg] {
  some i
  input[i].Cmd == "EXPOSE"
  input[i].Value[_] == "22"
  msg := "Exposing SSH port 22 is forbidden"
}

# ----------------------------------
# Rule: Must use slim base images
# ----------------------------------
deny[msg] {
  some i
  input[i].Cmd == "FROM"
  not contains(input[i].Value[0], "slim")
  msg := "Base image must be a slim variant"
}

