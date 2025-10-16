This is README for assignment1 along with success screenshots.

**Brief**:
For Task 1 I used Terraform to create a private S3 bucket and a customer-managed KMS key. I enforced encryption with SSE-KMS and enabled S3 Bucket Keys for lower KMS cost. I added a bucket policy that only allows access from my instance public IP (checked using curl ifconfig.me and added in variables.tf file or can be passed during terraform apply with -var tag) and explicitly denied other IPs. I also set the S3 Public Access Block to prevent accidental public exposure. To verify, I ran aws s3api get-bucket-encryption and attempted access from another machine to demonstrate AccessDenied.

1. **When trying to list contents of S3 bucket from IP which is not allowed, it is throwing error of AccessDenied.**
<img width="1700" height="137" alt="Screenshot 2025-10-16 at 6 28 26 PM" src="https://github.com/user-attachments/assets/51ce42d7-b8bc-4fae-ac64-bc8ba993c34b" />

2. **When trying to list contents of S3 bucket from IP which is allowed, it is showing exit code 0 which is success. Bucket was empty when testing was done that's why exit code 0 was there.**
<img width="876" height="41" alt="Screenshot 2025-10-16 at 6 28 11 PM" src="https://github.com/user-attachments/assets/f8cb72c9-518a-44bd-8814-ee673d8f8ad5" />

3. **Confirmation of bucket encyption**
<img width="1047" height="242" alt="Screenshot 2025-10-16 at 6 27 58 PM" src="https://github.com/user-attachments/assets/51057c43-0c23-4a82-b9a7-556a3925e32d" />

4. **Bucket creation success check**

<img width="1002" height="41" alt="Screenshot 2025-10-16 at 6 27 45 PM" src="https://github.com/user-attachments/assets/ad9fff07-ad57-4fe4-b38e-dd4b949f1452" />
<img width="930" height="88" alt="Screenshot 2025-10-16 at 6 27 27 PM" src="https://github.com/user-attachments/assets/b1e42bb5-78b5-4573-8f06-13f38b402f25" />
