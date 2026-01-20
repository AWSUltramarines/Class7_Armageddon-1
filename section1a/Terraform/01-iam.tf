# IAM Role for EC2 instances
resource "aws_iam_role" "armageddon-ec2-db-role" {
    name = "armageddon-ec2-db-role"

    # Trust Policy - EC2 can assume this role
    assume_role_policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "ec2.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    })
    
    tags = {
        Name = "armageddon-ec2-db-role"
    }
}

# IAM Policy for accessing the application secret
resource "aws_iam_role_policy" "armageddon-ec2-db-policy" {
    name = "armageddon-ec2-db-policy"
    role = aws_iam_role.armageddon-ec2-db-role.id

    # Permissions Policy - What the role can do
    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "ReadApplicationSecret",
                "Effect": "Allow",
                "Action": [
                    "secretsmanager:GetSecretValue",
                    "secretsmanager:DescribeSecret"
                ],
                # Reference the Terraform-managed secret
                "Resource": aws_secretsmanager_secret.app_db_secret.arn
            },
            {
                "Sid": "KMSDecryptKey",
                "Effect": "Allow",
                "Action": [
                    "kms:Decrypt"
                ],
                "Resource": "arn:aws:kms:*:*:key/*",
                "Condition": {
                    "StringLike": {
                        "kms:EncryptionContext:SecretARN": aws_secretsmanager_secret.app_db_secret.arn,
                        "kms:ViaService": "secretsmanager.us-east-1.amazonaws.com"
                    }
                }
            }
        ]
    })
}

# Instance Profile to attach role to EC2
resource "aws_iam_instance_profile" "armageddon-ec2-db-profile" {
    name = "armageddon-ec2-db-profile"
    role = aws_iam_role.armageddon-ec2-db-role.name
}
