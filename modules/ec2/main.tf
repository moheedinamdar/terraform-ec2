data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]
  filter{
  name = "name"
  values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  #root-device-type    = "ebs"
  filter{
    name = "virtualization-type"
    values = ["hvm"]
    }
  
  filter {
  name = "architecture"
  values = ["x86_64"]
  }
}
resource "aws_key_pair" "key" {
  key_name   = "terraform_aws_key"
  public_key = file("./modules/ec2/aws-key.pub")
}

resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.key.key_name
  subnet_id                   = var.subnet
  vpc_security_group_ids      = [var.sg]
  associate_public_ip_address = true
  user_data                   = file("./modules/ec2/user_data.sh")
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "Terraform Web EC2 Instance"
  }
}

resource "aws_iam_role_policy" "secret_policy" {
  name = "TerraformReadSecretsInlinePolicy"
  role = aws_iam_role.ec2_secret.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action : "secretsmanager:GetSecretValue",
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "ec2_secret" {
  name = "TerraformEc2Secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "secretsmanager_ec2_profile"
  role = aws_iam_role.ec2_secret.name
}