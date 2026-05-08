data "aws_caller_identity" "name" {} 

output "account_id" {
  value = data.aws_caller_identity.name.account_id
}

data "aws_iam_users" "users" {}

output "users_list" {
  value = data.aws_iam_users.users
}