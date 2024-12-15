#!/bin/bash

LOGFILE="/home/sysadm/scripts/postgresql_health.log"
EMAIL="example@gmail.com"
SUBJECT="Node's Health Report"

#create the log file (create if not exists, or update if exists)
touch $LOGFILE

# Pgbouncer service status
echo "Pgbouncer Service Status:" >> $LOGFILE  # Use >> to append
systemctl status pgbouncer.service | head -n 3 >> $LOGFILE 2>&1

# PostgreSQL service status
echo -e "\nPostgreSQL14 Service Status:" >> $LOGFILE  # Use >> to append
systemctl status postgresql@14-main.service | head -n 3 >> $LOGFILE 2>&1

# Disk space
echo -e "\nDisk Usage:" >> $LOGFILE
df -h >> $LOGFILE

# Memory usage
echo -e "\nMemory Usage:" >> $LOGFILE
free -h >> $LOGFILE

# CPU load
echo -e "\nCPU Load:" >> $LOGFILE
uptime >> $LOGFILE

# Email the log file with the subject
{
  echo "Subject: $SUBJECT"
  echo ""
  cat "$LOGFILE"
} | ssmtp "$EMAIL"

# Remove the log file after sending the mail
rm "$LOGFILE"
