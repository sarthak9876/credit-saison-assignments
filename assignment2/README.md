**🧩 Assignment 2 — AMI Lifecycle Automation**

**🧠 Objective**

Automate the cleanup of AMIs created with tag **CreatedBy:AMILifecycle** — keeping only recent AMIs and deleting older ones.

⚙️ **Implementation Overview**

**Tools Used**: Python (boto3), AWS Lambda / EC2 testing, CloudWatch (optional)

**Goal:**
Deregister AMIs older than 60 minutes (for demo) and delete associated snapshots.

🧱 Python Script
```
import boto3
from datetime import datetime, timezone, timedelta

ec2 = boto3.client('ec2')

def lambda_handler(event=None, context=None):
    filters = [{'Name': 'tag:CreatedBy', 'Values': ['AMILifecycle']}]
    response = ec2.describe_images(Owners=['self'], Filters=filters)
    images = response['Images']

    if not images:
        print("No AMIs found with tag CreatedBy:AMILifecycle")
        return

    images.sort(key=lambda x: x['CreationDate'], reverse=True)
    now = datetime.now(timezone.utc)
    cutoff_time = now - timedelta(minutes=60)

    print(f"Current Time (UTC): {now}")
    print(f"Deleting AMIs older than: {cutoff_time}")

    for image in images:
        creation_time = datetime.strptime(image['CreationDate'], "%Y-%m-%dT%H:%M:%S.%fZ").replace(tzinfo=timezone.utc)
        image_id = image['ImageId']
        image_name = image.get('Name', 'Unnamed')

        if creation_time < cutoff_time:
            print(f"Deregistering AMI: {image_name} ({image_id}) | Created at: {creation_time}")
            ec2.deregister_image(ImageId=image_id)
            for mapping in image['BlockDeviceMappings']:
                if 'Ebs' in mapping:
                    snapshot_id = mapping['Ebs']['SnapshotId']
                    try:
                        ec2.delete_snapshot(SnapshotId=snapshot_id)
                        print(f"Deleted snapshot: {snapshot_id}")
                    except Exception as e:
                        print(f"Error deleting snapshot {snapshot_id}: {e}")
        else:
            print(f"Keeping AMI: {image_name} ({image_id}) | Created at: {creation_time}")

if __name__ == "__main__":
    lambda_handler()
```
🧪 Testing Steps

  1. Created test AMIs manually:
      ```
      aws ec2 create-image --instance-id i-0123456789abcdef \
        --name "Test-AMI-1" \
        --tag-specifications 'ResourceType=image,Tags=[{Key=CreatedBy,Value=AMILifecycle}]'
      ```
  
  2. Created 3 such AMIs spaced by 1–2 mins each.
  
      Executed script on EC2:
      ```
      python3 ami_cleanup.py
      ```
  
  3. Verified output:
  
      i. AMIs older than 60 minutes were deregistered.
      
      ii. Snapshots linked to those AMIs were deleted.
      
      iii.Logs confirmed remaining AMIs were newer.

🔄 **Optional: Schedule Automation**

To test automatic cleanup:
```
aws events put-rule --schedule-expression "rate(2 minutes)" --name "AMICleanupTest"

```

**Screenshots:**

1. Lambda Function
<img width="1722" height="1038" alt="Screenshot 2025-10-16 at 9 43 01 PM" src="https://github.com/user-attachments/assets/0f0a6091-dd42-4b79-ad3e-d85b8b3c46ab" />


2. Creation of CloudWatch Log group
<img width="1722" height="1038" alt="Screenshot 2025-10-16 at 9 42 00 PM" src="https://github.com/user-attachments/assets/1696dfde-3780-4bd4-8c9b-add26e2d375d" />

3. Logs showing in CloudWatch Log Group
<img width="1722" height="1038" alt="Screenshot 2025-10-16 at 10 10 04 PM" src="https://github.com/user-attachments/assets/321ed82f-9ee4-41bf-b4c6-bed2cdc43567" />
