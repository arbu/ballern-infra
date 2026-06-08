# TODO: configure GitLab HTTP backend details.
# Example usage:
#   tofu init -backend-config=backend.hcl

address        = "https://gitlab.example.com/api/v4/projects/<project-id>/terraform/state/ballern-event"
lock_address   = "https://gitlab.example.com/api/v4/projects/<project-id>/terraform/state/ballern-event/lock"
unlock_address = "https://gitlab.example.com/api/v4/projects/<project-id>/terraform/state/ballern-event/lock"
lock_method    = "POST"
unlock_method  = "DELETE"
retry_wait_min = 5
