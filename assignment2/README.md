README for assignment2

**Brief:**

For Task 2 I implemented a small Lambda (Python/boto3). It enumerates AMIs with tag CreatedBy=AMILifecycle, sorts by creation date, and deregisters older images while keeping the most recent two. I included a DRY_RUN mode and optional snapshot deletion behind a flag. I scheduled it with EventBridge to run every 24 hours and added CloudWatch logging so operations are auditable. The design focuses on safety (dry-run & logging), idempotency, and minimal permissions.
