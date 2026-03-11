# Workstream Infrastructure - HARDENED

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

# --- S3: Encrypted, private, versioned, logged ---
resource "aws_s3_bucket" "payroll_reports" {
  bucket = "workstream-payroll-reports-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "payroll_reports" {
  bucket = aws_s3_bucket.payroll_reports.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "payroll_reports" {
  bucket = aws_s3_bucket.payroll_reports.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.payroll.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "payroll_reports" {
  bucket = aws_s3_bucket.payroll_reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "payroll_reports" {
  bucket = aws_s3_bucket.payroll_reports.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "payroll-reports/"
}

resource "aws_s3_bucket" "access_logs" {
  bucket = "workstream-access-logs-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_policy" "payroll_tls_only" {
  bucket = aws_s3_bucket.payroll_reports.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "EnforceTLS"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.payroll_reports.arn,
        "${aws_s3_bucket.payroll_reports.arn}/*"
      ]
      Condition = {
        Bool = {
          "aws:SecureTransport" = "false"
        }
      }
    }]
  })
}

# --- KMS key for encryption ---
resource "aws_kms_key" "payroll" {
  description             = "Workstream payroll data encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# --- RDS: Encrypted, private, backed up ---
resource "aws_db_instance" "payroll_db" {
  identifier     = "workstream-payroll-db"
  engine         = "postgres"
  engine_version = "14.9"
  instance_class = "db.t3.medium"
  
  allocated_storage = 100
  storage_encrypted = true
  kms_key_id        = aws_kms_key.payroll.arn
  
  publicly_accessible     = false
  skip_final_snapshot     = false
  backup_retention_period = 30
  
  db_subnet_group_name   = "workstream-private"
  vpc_security_group_ids = [aws_security_group.db_access.id]
}

# --- Security Group: Restricted to VPC CIDR ---
resource "aws_security_group" "db_access" {
  name        = "workstream-db-access"
  description = "Database access - restricted to internal services"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "PostgreSQL from VPC only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Outbound to VPC only"
  }
}

# --- IAM: Least privilege ---
resource "aws_iam_role" "app_role" {
  name = "workstream-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
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
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      Resource = "${aws_s3_bucket.payroll_reports.arn}/*"
    }]
  })
}

# --- EKS: Private endpoint ---
resource "aws_eks_cluster" "workstream" {
  name     = "workstream-production"
  role_arn = aws_iam_role.app_role.arn

  vpc_config {
    endpoint_public_access  = false
    endpoint_private_access = true
    subnet_ids              = ["subnet-12345", "subnet-67890"]
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.payroll.arn
    }
    resources = ["secrets"]
  }
}

# --- CloudWatch: Encrypted, long retention ---
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/workstream/app"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.payroll.arn
}

# --- ECR: Immutable, scanned ---
resource "aws_ecr_repository" "app" {
  name                 = "workstream-api"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.payroll.arn
  }
}
