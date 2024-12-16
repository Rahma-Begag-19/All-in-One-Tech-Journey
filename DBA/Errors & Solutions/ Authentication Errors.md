**Error Message:** no such user or password authentication failed for user ...<br>
**Cause:**
- Incorrect username or password<br>
- User is not defined in pgbouncer.ini or pg_hba.conf.
- Misconfiguration of the auth_file (typically userlist.txt).<br>

**Solution:**
- Verify the auth_file path and ensure it includes the correct username and password hash.
- Ensure pg_hba.conf allows the connection.
- alter the user with the same password, add it to the userlist.txt and then restart pgbouncer service.
