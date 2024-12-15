### 1. Install auditd
Run the following commands to install and enable auditd:
```bash
sudo apt update
sudo apt install auditd -y
sudo systemctl enable auditd
sudo systemctl start auditd
```
### 2. Create an Audit Rule for pg_hba.conf
Audit rules specify which files or directories to monitor. Add a rule to monitor changes to the pg_hba.conf file.

Open the audit rules configuration file:
```bash
sudo nano /etc/audit/rules.d/audit.rules
```

Add the following line to audit the pg_hba.conf file:
```bash
-w /path/to/pg_hba.conf -p wa -k pg_hba_changes
```
- /path/to/pg_hba.conf: Replace this with the full path to your pg_hba.conf file (e.g., /var/lib/postgresql/15/main/pg_hba.conf for PostgreSQL 15).
- -p wa: This monitors write (w) and attribute (a) changes.
- -k pg_hba_changes: This is a custom key to easily filter audit logs.<br>

Save and close the file.
### 3. Restart auditd
Reload the rules by restarting the auditd service:
```bash
sudo systemctl restart auditd
```
<br>

### 4. Test the Audit Rule
Modify the pg_hba.conf file:
```bash
sudo nano /path/to/pg_hba.conf
```
Make a small change and save the file.

Check the audit logs for events related to pg_hba.conf:
```bash
sudo ausearch -k pg_hba_changes
```
You'll see output similar to:
```bash
type=SYSCALL msg=audit(1702626000.123:123): arch=c000003e syscall=2 success=yes ...
type=PATH msg=audit(1702626000.123:123): item=0 name="/path/to/pg_hba.conf" ...
