#!/bin/bash

export AWS_DEFAULT_REGION**********
export AWS_ACCESS_KEY_ID=***********
export AWS_SECRET_ACCESS_KEY=****************************


# Backup folder path
BACKUP_DIR="/path/to/backups/"

# Current date
DATE=$(date +%Y%m%d%H%M%S)

# Create backup folder
BACKUP_FOLDER="$BACKUP_DIR/${DATE}_configuration_files_backup"
mkdir -p "$BACKUP_FOLDER"

# Directories to back up
SOURCE_DIRS=("/etc/pgbouncer" "/etc/postgresql")

# Copy each source directory into the backup folder
for DIR in "${SOURCE_DIRS[@]}"; do
    if [ -d "$DIR" ]; then
        cp -r "$DIR" "$BACKUP_FOLDER"
        echo "Backed up $DIR to $BACKUP_FOLDER"
    else
        echo "Warning: Directory $DIR does not exist and was skipped."
    fi
done

# Create a compressed archive of the backup folder
ARCHIVE_NAME="${DATE}_configuration_files_backup.tar.gz"
tar -czf "$BACKUP_DIR/$ARCHIVE_NAME" -C "$BACKUP_DIR" "${DATE}_configuration_files_backup"
echo "Compressed backup folder into $ARCHIVE_NAME"




# Upload to AWS S3
S3_BUCKET="s3://postgresql_configuration"
aws s3 cp "$BACKUP_DIR/$ARCHIVE_NAME" "$S3_BUCKET/$ARCHIVE_NAME"
echo "Backup uploaded to BS3 bucket $S3_BUCKET"

# Clean up backup folder after compression
rm -rf "$BACKUP_FOLDER"
echo "Local backup folder cleaned up"

echo "Backup process completed successfully."