### Install ssmtp
To install ssmtp, run the following command:
```bash
sudo apt update
sudo apt install ssmtp
```

### Configuration of ssmtp
The main configuration file for ssmtp is located at /etc/ssmtp/ssmtp.conf.

Edit the ssmtp.conf file:
```bash
sudo nano /etc/ssmtp/ssmtp.conf
```


```bash
#
# Config file for sSMTP sendmail
#
# The person who gets all mail for userids < 1000
# Make this empty to disable rewriting.
root=example.sender@gmail.com

# The place where the mail goes. The actual machine name is required no 
# MX records are consulted. Commonly mailhosts are named mail.domain.com
mailhub=smtp.office365.com:587
AuthUser=example.sender@gmail.com
AuthPass=***********
UseTLS=YES
UseSTARTTLS=YES

# Where will the mail seem to come from?
rewriteDomain=gmail.com

# The full hostname
hostname=yourhost

# Are users allowed to set their own From: address?
# YES - Allow the user to specify their own From: address
# NO - Use the system generated From: address
FromLineOverride=YES
```

### Sending a Test Email
To test the configuration, use the following command:

```bash
echo "Subject: Test Email" | ssmtp recipient@example.com
```