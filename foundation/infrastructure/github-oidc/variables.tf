variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "allowed_branch" {
  description = "Main branch only"
  type        = string
  default     = "main"
}
