#!/bin/bash

# Configuration
ContainerName="sql-server"
DBName="OverflowDB"
BackupDir="/home/albuadrian2412"  # Change to your desired backup directory
BackupFileName="${DBName}_$(date +'%Y%m%d%H%M%S').bak"
BackupFilePath="${BackupDir}/${BackupFileName}"
ContainerBackupPath="/var/opt/mssql/${BackupFileName}"

# Retrieve the SQL password from an environment variable or secure source
SAPassword="${SQL_PASSWD}"  # Ensure this variable is set in your environment

# Ensure the backup directory exists
if [ ! -d "$BackupDir" ]; then
    mkdir -p "$BackupDir"
    echo "Created backup directory at $BackupDir"
fi

# Step 1: Run the backup command inside the Docker container
echo "Running backup inside the container..."
docker exec $ContainerName /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U SA -P "$SAPassword" \
    -Q "BACKUP DATABASE [$DBName] TO DISK = N'$ContainerBackupPath' WITH NOFORMAT, INIT, NAME = '$DBName-full-backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

if [ $? -ne 0 ]; then
    echo "Backup command failed. Exiting."
    exit 1
fi

# Step 2: Copy the backup file from the container to the host
echo "Copying backup file from container to host..."
docker cp "${ContainerName}:${ContainerBackupPath}" "$BackupFilePath"

if [ $? -ne 0 ]; then
    echo "Failed to copy backup file from container to host. Exiting."
    exit 1
fi

# Step 3: Clean up the backup file inside the container (optional)
# echo "Cleaning up backup file inside the container..."
# docker exec $ContainerName rm "$ContainerBackupPath"

# Final message
echo "Backup completed successfully! Backup file saved to $BackupFilePath"