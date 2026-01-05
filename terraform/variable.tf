variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}


variable "github_username" {
  type        = string
  description = "GitHub username or org"
  default     = "nitinbhardwaj297"
}

variable "github_repo_name" {
  type        = string
  description = "GitHub repository name"
  default     = "github-eks"
}

variable "k8s_cluster_name" {
  type        = string
  description = "GitHub repository name"
  default     = "thor-eks"
}

variable "k8s_namespace" {
  type        = string
  description = "GitHub repository name"
  default     = "asgard"
}

variable "ECR_REPO" {
  type        = string
  description = "aws repository name"
  default     = "thor"
}

variable "AWS_ACCOUNT_ID" {
  type = string
  default  = "867344428970"
}

variable "DEVELOPER_NAME" {
  type = string
  default = "nitin"
}
