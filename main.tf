# developer 
resource "aws_iam_user_login_profile" "Developer_user" {
  count                   = length(var.developer)
  user                    = aws_iam_user.developer_eks_user[count.index].name
  password_reset_required = true
  pgp_key                 = "keybase:quadribello41"
}

resource "aws_iam_user" "developer_eks_user" {
  count         = length(var.developer)
  name          = element(var.developer, count.index)
  force_destroy = true

  tags = {
    Department = "developer_eks_user"
  }
}

# admins
resource "aws_iam_user_login_profile" "Admin_user" {
  count                   = length(var.admin)
  user                    = aws_iam_user.admin_eks_user[count.index].name
  password_reset_required = true
  pgp_key                 = "keybase:quadribello41"
}

resource "aws_iam_user" "admin_eks_user" {
  count         = length(var.admin)
  name          = element(var.admin, count.index)
  force_destroy = true

  tags = {
    Department = "admin_eks_user"
  }
}

# EKS Developer Group
resource "aws_iam_group" "eks_developer" {
  name = "Developer"
}

resource "aws_iam_group_policy" "developer_policy" {
  name   = "developer"
  group  = aws_iam_group.eks_developer.name
  policy = data.aws_iam_policy_document.developer.json
}

resource "aws_iam_group_membership" "db_team" {
  count = length(var.developer)
  name  = "dev-group-membership"
  users = [aws_iam_user.developer_eks_user[count.index].name]
  group = aws_iam_group.eks_developer.name
}

# EKS Admin Group
resource "aws_iam_group" "eks_masters" {
  name = "Masters"
}

resource "aws_iam_group_policy" "masters_policy" {
  name   = "masters"
  group  = aws_iam_group.eks_masters.name
  policy = data.aws_iam_policy_document.masters_role.json
}

resource "aws_iam_group_membership" "masters_team" {
  count = length(var.admin)
  name  = "masters-group-membership"
  users = [aws_iam_user.admin_eks_user[count.index].name]
  group = aws_iam_group.eks_masters.name
}

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 8
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
}

resource "aws_iam_role" "masters" {
  name               = "Masters-eks-Role"
  assume_role_policy = data.aws_iam_policy_document.masters_assume_role.json
}


resource "aws_iam_role_policy_attachment" "admin_policy" {
  role       = aws_iam_role.masters.name
  policy_arn = aws_iam_policy.eks_admin.arn
}

resource "aws_iam_policy" "eks_admin" {
  name   = "eks-masters"
  policy = data.aws_iam_policy_document.masters.json
}