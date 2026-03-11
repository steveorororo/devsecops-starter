# Workstream Infrastructure - DELIBERATELY VULNERABLE FOR TRAINING

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# --- VULNERABILITY 1: Public S3 bucket for payroll reports ---
resource "aws_s3_bucket" "payroll_reports" {
  bucket = "workstream-payroll-reports"
}

resource "aws_s3_bucket_policy" "payroll_public" {
  bucket = aws_s3_bucket.payroll_reports.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.payroll_reports.arn}/*"
    }]
  })
}

# --- VULNERABILITY 2: RDS without encryption ---
resource "aws_db_instance" "payroll_db" {
  identifier     = "workstream-payroll-db"
  engine         = "postgres"
  engine_version = "14.9"
  instance_class = "db.t3.medium"
  username       = "admin"
  password       = "SuperSecret123!"
  
  allocated_storage = 100
  storage_encrypted = false
  
  publicly_accessible    = true
  skip_final_snapshot    = true
  backup_retention_period = 0
}

# --- VULNERABILITY 3: Wide-open security group ---
resource "aws_security_group" "db_access" {
  name        = "workstream-db-access"
  description = "Database access"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- VULNERABILITY 4: Overprivileged IAM role ---
resource "aws_iam_role" "app_role" {
  name = "workstream-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "app_policy" {
  name = "workstream-app-policy"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  })
}

# --- VULNERABILITY 5: EKS with public endpoint ---
resource "aws_eks_cluster" "workstream" {
  name     = "workstream-production"
  role_arn = aws_iam_role.app_role.arn

  vpc_config {
    endpoint_public_access  = true
    endpoint_private_access = false
    subnet_ids              = ["subnet-12345", "subnet-67890"]
  }
}

# --- VULNERABILITY 6: CloudWatch logs without encryption ---
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/workstream/app"
  retention_in_days = 7
}

# --- VULNERABILITY 7: ECR without image scanning ---
resource "aws_ecr_repository" "app" {
  name                 = "workstream-api"
  image_tag_mutability = "MUTABLE"
}
