terraform {
  backend "oci" {
    # Required
    bucket    = "tfstate-team"
    namespace = "***"
    region    = "us-phoenix-1"

    # Optional
    # workspace_key_prefix = "workspaces/"
  }
}
