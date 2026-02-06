variable "organization" {
  description = "TFC organization name"
  type        = string
  default     = "grinwis-com"
}

variable "project" {
  description = "TFC project name to search workspaces in"
  type        = string
  default     = "mendix"
}

variable "tag_filter" {
  description = "Tag to filter workspaces (e.g., cert:cert-example)"
  type        = string
}
