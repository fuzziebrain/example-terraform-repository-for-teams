terraform {
  backend "oci" {
    # Required
    bucket    = "tfstate-team"
    namespace = "ax3q1y7cvk2q"
    region    = "us-phoenix-1"

    # Optional
    # workspace_key_prefix = "workspaces/"
  }
}
