output "ecr_repo" {
    value = aws_ecr_repository.this
}
output "name" {
    value = var.name
}
output "arn" {
    value = aws_ecr_repository.this.arn
}
output "registry_id" {
    value = aws_ecr_repository.this.registry_id
}
output "repository_url" {
    value = aws_ecr_repository.this.repository_url
}