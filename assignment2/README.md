README for assignment2

**Brief:**

For Task 2 I implemented a small Lambda (Python/boto3). It enumerates AMIs with tag CreatedBy=AMILifecycle, sorts by creation date, and deregisters older images while keeping the most recent two. I included a DRY_RUN mode and optional snapshot deletion behind a flag. I scheduled it with EventBridge to run every 24 hours and added CloudWatch logging so operations are auditable. The design focuses on safety (dry-run & logging), idempotency, and minimal permissions.


1. Lambda Function
<img width="1722" height="1038" alt="Screenshot 2025-10-16 at 9 43 01 PM" src="https://github.com/user-attachments/assets/0f0a6091-dd42-4b79-ad3e-d85b8b3c46ab" />


2. Creation of CloudWatch Log group
<img width="1722" height="1038" alt="Screenshot 2025-10-16 at 9 42 00 PM" src="https://github.com/user-attachments/assets/1696dfde-3780-4bd4-8c9b-add26e2d375d" />

3. Logs showing in CloudWatch Log Group
<img width="1722" height="1038" alt="Screenshot 2025-10-16 at 10 10 04 PM" src="https://github.com/user-attachments/assets/321ed82f-9ee4-41bf-b4c6-bed2cdc43567" />
