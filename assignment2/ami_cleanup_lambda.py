import boto3
import logging
import os
from datetime import datetime, timezone

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
DRY_RUN = os.getenv("DRY_RUN", "true").lower() in ("1","true","yes")
DELETE_SNAPSHOTS = os.getenv("DELETE_SNAPSHOTS", "false").lower() in ("1","true","yes")
TAG_KEY = os.getenv("TAG_KEY", "CreatedBy")
TAG_VALUE = os.getenv("TAG_VALUE", "AMILifecycle")
RETAIN = int(os.getenv("RETAIN", "2"))

logger = logging.getLogger()
logger.setLevel(LOG_LEVEL)

ec2 = boto3.client("ec2")

def lambda_handler(event, context):
    logger.info(f"Starting AMI cleanup. DRY_RUN={DRY_RUN}, DELETE_SNAPSHOTS={DELETE_SNAPSHOTS}")

    # 1) Describe images with the tag
    filters = [
        {"Name": f"tag:{TAG_KEY}", "Values": [TAG_VALUE]},
        {"Name": "state", "Values": ["available"]}
    ]
    resp = ec2.describe_images(Owners=["self"], Filters=filters)
    images = resp.get("Images", [])
    logger.info(f"Found {len(images)} images tagged {TAG_KEY}:{TAG_VALUE}")

    # 2) Sort by CreationDate (newest first)
    images_sorted = sorted(images, key=lambda i: i['CreationDate'], reverse=True)

    # 3) Keep the first RETAIN images, deregister the rest
    to_keep = images_sorted[:RETAIN]
    to_delete = images_sorted[RETAIN:]

    logger.info(f"Keeping {len(to_keep)} images: {[i['ImageId'] for i in to_keep]}")
    logger.info(f"Will deregister {len(to_delete)} images: {[i['ImageId'] for i in to_delete]}")

    for img in to_delete:
        image_id = img["ImageId"]
        logger.info(f"Processing image {image_id} created {img['CreationDate']}")
        if DRY_RUN:
            logger.info(f"DRY_RUN enabled - skipping deregister for {image_id}")
            continue

        # Deregister image
        try:
            ec2.deregister_image(ImageId=image_id)
            logger.info(f"Deregistered {image_id}")
        except Exception as e:
            logger.exception(f"Error deregistering {image_id}: {e}")
            continue

        # Optionally delete associated EBS snapshots
        if DELETE_SNAPSHOTS:
            # AMI block device mappings may contain EBS snapshots
            block_mappings = img.get("BlockDeviceMappings", [])
            for bdm in block_mappings:
                ebs = bdm.get("Ebs")
                if not ebs:
                    continue
                snap_id = ebs.get("SnapshotId")
                if snap_id:
                    try:
                        ec2.delete_snapshot(SnapshotId=snap_id)
                        logger.info(f"Deleted snapshot {snap_id} for image {image_id}")
                    except Exception as e:
                        logger.exception(f"Failed to delete snapshot {snap_id}: {e}")

    logger.info("AMI cleanup completed")
    return {"status": "done", "kept": [i['ImageId'] for i in to_keep], "deleted": [i['ImageId'] for i in to_delete]}
