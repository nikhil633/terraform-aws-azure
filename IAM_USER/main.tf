resource "aws_iam_user" "users" {
  for_each = {for user in local.users: user.first_name => user}

  name = lower("${substr(each.value.first_name,0,1)}${each.value.last_name}")
  path = "/users/"

}

resource "aws_iam_user_login_profile" "user" {
  for_each = aws_iam_user.users
  user = each.value.name
  password_reset_required = false

  lifecycle {
    ignore_changes = [ password_reset_required,password_length ]
  }
}