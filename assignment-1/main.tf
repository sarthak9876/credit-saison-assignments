resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 bucket encryption (Created by me for assignment)"
  deletion_window_in_days = 7

  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Id":"key-default-1",
  "Statement":[
    {
      "Sid":"Allow administrative actions",
      "Effect":"Allow",
      "Principal":{"AWS":"arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"},
      "Action":"kms:*",
      "Resource":"*"
    },
    {
      "Sid":"Allow S3 to use the key",
      "Effect":"Allow",
      "Principal":{"Service":"s3.amazonaws.com"},
      "Action":[
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ],
      "Resource":"*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "s3.${var.aws_region}.amazonaws.com"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/assign-s3-key"
  target_key_id = aws_kms_key.s3_key.key_id
}


# S3 Bucket part

resource "aws_s3_bucket" "assignment_bucket" {
  bucket = var.bucket_name
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.s3_key.arn
        sse_algorithm     = "aws:kms"
      }
      bucket_key_enabled = true
    }
  }

  tags = {
    Project = "InterviewAssignment"
    Owner   = "Sarthak"
  }
}

# Block all public access at bucket level
resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.assignment_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy restricting access to only a specific IP and requiring TLS
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "ip_restrict_policy" {
  bucket = aws_s3_bucket.assignment_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowGetPutFromMyIP"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.assignment_bucket.arn,
          "${aws_s3_bucket.assignment_bucket.arn}/*"
        ]
        Condition = {
          IpAddress = {
            "aws:SourceIp" = var.my_ip
          }
          Bool = {
            "aws:SecureTransport" = "true"
          }
        }
      },
      # deny all others explicitly (helps with explicit refusal)
      {
        Sid = "DenyAllExceptFromMyIP"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.assignment_bucket.arn,
          "${aws_s3_bucket.assignment_bucket.arn}/*"
        ]
        Condition = {
          NotIpAddress = {
            "aws:SourceIp" = var.my_ip
          }
        }
      }
    ]
  })
}
