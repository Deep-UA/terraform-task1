terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

variable "github_owner" {
  type    = string
  default = "Deep-UA"
}

variable "repository" {
  type    = string
  default = "terraform-task1"
}

# Classic PAT (ghp_...). Used for the provider and stored as the PAT actions secret.
# Pass it with: export TF_VAR_github_token=ghp_...
variable "github_token" {
  type      = string
  sensitive = true
  default   = ""
}

# Discord channel webhook URL (Server Settings -> Integrations -> Webhooks).
# Leave empty to skip the webhook. Not sensitive because it drives count.
variable "discord_webhook_url" {
  type    = string
  default = ""
}

variable "pull_request_template" {
  type    = string
  default = <<-EOT
    ## Describe your changes

    ## Issue ticket number and link

    ## Checklist before requesting a review
    - [ ] I have performed a self-review of my code
    - [ ] If it is a core feature, I have added thorough tests
    - [ ] Do we need to implement analytics?
    - [ ] Will this be part of a product update? If yes, please write one phrase about this update
  EOT
}

provider "github" {
  owner = var.github_owner
  token = var.github_token
}

# 1. Collaborator
resource "github_repository_collaborator" "softservedata" {
  repository = var.repository
  username   = "softservedata"
  permission = "push"
}

# 2. develop branch as default
resource "github_branch" "develop" {
  repository    = var.repository
  branch        = "develop"
  source_branch = "main"
}

resource "github_branch_default" "default" {
  repository = var.repository
  branch     = github_branch.develop.branch
}

# 3. Code owner and 4. PR template, committed to main after develop is cut,
# so CODEOWNERS exists only on main.
resource "github_repository_file" "codeowners" {
  repository          = var.repository
  branch              = "main"
  file                = ".github/CODEOWNERS"
  content             = "* @softservedata\n"
  commit_message      = "Add CODEOWNERS"
  overwrite_on_create = true

  depends_on = [github_branch.develop]
}

resource "github_repository_file" "pull_request_template" {
  repository          = var.repository
  branch              = "main"
  file                = ".github/pull_request_template.md"
  commit_message      = "Add pull request template"
  overwrite_on_create = true
  content             = var.pull_request_template

  depends_on = [github_branch.develop]
}

# 3. Branch protection
resource "github_branch_protection" "main" {
  repository_id = var.repository
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 0
    require_code_owner_reviews      = true
  }

  depends_on = [
    github_repository_file.codeowners,
    github_repository_file.pull_request_template,
  ]
}

resource "github_branch_protection" "develop" {
  repository_id = var.repository
  pattern       = "develop"

  required_pull_request_reviews {
    required_approving_review_count = 2
  }

  depends_on = [github_branch.develop]
}

# 5. Deploy key
resource "tls_private_key" "deploy_key" {
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "deploy_key" {
  repository = var.repository
  title      = "DEPLOY_KEY"
  key        = tls_private_key.deploy_key.public_key_openssh
  read_only  = false
}

# 6. Discord notifications on pull requests
resource "github_repository_webhook" "discord" {
  count = var.discord_webhook_url == "" ? 0 : 1

  repository = var.repository
  events     = ["pull_request"]

  configuration {
    # format() instead of string interpolation: CI writes this file through an unquoted bash heredoc
    url          = format("%s/github", var.discord_webhook_url)
    content_type = "json"
  }
}

# 7. PAT as actions secret
resource "github_actions_secret" "pat" {
  repository      = var.repository
  secret_name     = "PAT"
  plaintext_value = var.github_token
}
