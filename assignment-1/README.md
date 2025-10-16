🧩 Assignment 1 — S3 Bucket with IP Restriction and SSE-KMS Encryption

🧠 **Objective**
**Create a secure S3 bucket that:**

  1. Is private (no public access),
  
  2. Is only accessible from specific IP addresses,
  
  3. Uses SSE-KMS encryption with a customer-managed KMS key,
  
  4. Has enforced encryption through bucket policies.

⚙️ **Implementation Overview**

**Tools Used**: Terraform, AWS CLI, KMS, S3

Steps Performed:

  1. Created a customer-managed KMS key
  
     i. Type: Symmetric
      
     ii. Usage: ENCRYPT_DECRYPT
      
     iii. Key rotation enabled for best practices.
  
  2. Created an alias alias/s3encryptionkey for easier key reference.
  
  3. Created an S3 bucket using Terraform.
  
  4. Applied default bucket encryption using the KMS key (SSE-KMS).
  
  5. Added bucket policy to:
  
      i. Deny uploads without encryption headers,
      
      ii. Restrict access to specific IPs.
  
  6. Tested manually using AWS CLI:
```
aws s3 cp testfile.txt s3://<bucket-name>/ --sse aws:kms --sse-kms-key-id alias/s3encryptionkey
aws s3api head-object --bucket <bucket-name> --key testfile.txt --query ServerSideEncryption
```

Verified output: "aws:kms"

🧱 Terraform Structure
```
provider "aws" {
  region = "ap-south-1"
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "s3_encryption_key" {
  description             = "Key for S3 encryption"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation     = true
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/s3encryptionkey"
  target_key_id = aws_kms_key.s3_encryption_key.key_id
}

resource "aws_s3_bucket" "secure_bucket" {
  bucket = "s3-secure-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_encryption_key.arn
    }
  }
}

resource "aws_s3_bucket_policy" "enforce_encryption" {
  bucket = aws_s3_bucket.secure_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnEncryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.secure_bucket.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })
}

```

🧩 Verification

✅ Bucket created successfully
✅ File uploads encrypted automatically
✅ Access denied from non-whitelisted IPs
✅ Policy prevents unencrypted uploads

**Screenshots**

1. **When trying to list contents of S3 bucket from IP which is not allowed, it is throwing error of AccessDenied.**
<img width="1700" height="137" alt="Screenshot 2025-10-16 at 6 28 26 PM" src="https://github.com/user-attachments/assets/51ce42d7-b8bc-4fae-ac64-bc8ba993c34b" />

2. **When trying to list contents of S3 bucket from IP which is allowed, it is showing exit code 0 which is success. Bucket was empty when testing was done that's why exit code 0 was there.**
<img width="876" height="41" alt="Screenshot 2025-10-16 at 6 28 11 PM" src="https://github.com/user-attachments/assets/f8cb72c9-518a-44bd-8814-ee673d8f8ad5" />

3. **Confirmation of bucket encyption**
<img width="1047" height="242" alt="Screenshot 2025-10-16 at 6 27 58 PM" src="https://github.com/user-attachments/assets/51057c43-0c23-4a82-b9a7-556a3925e32d" />

4. **Bucket creation success check**

<img width="1002" height="41" alt="Screenshot 2025-10-16 at 6 27 45 PM" src="https://github.com/user-attachments/assets/ad9fff07-ad57-4fe4-b38e-dd4b949f1452" />
<img width="930" height="88" alt="Screenshot 2025-10-16 at 6 27 27 PM" src="https://github.com/user-attachments/assets/b1e42bb5-78b5-4573-8f06-13f38b402f25" />
