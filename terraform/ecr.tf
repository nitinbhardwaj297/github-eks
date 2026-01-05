resource "aws_ecr_repository" "thor_ecr" {
  name                 = var.ECR_REPO
  image_tag_mutability = "MUTABLE"
  force_delete = true
}
