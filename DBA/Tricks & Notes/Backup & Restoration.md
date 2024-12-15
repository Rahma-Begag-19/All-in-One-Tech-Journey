***
CREATING A BACKUP :
```bash
pg_dump -U postgres -d dbname -f file.sql
pg_dump -U postgres -d dbname > file.dmp
```

RESTORING A DATABASE FROM FILES :
```bash
pg_restore -U postgres -d db file.dmp
pg_restore -U postgres -d db -f file.sql
```

***
COPYING FILE FROM SERVER TO LOCAL :
```bash
scp user@ip:path/file.sql /home/BACKUP_FILE.sql
```

COPYING FILE FROM LOCAL TO SERVER :
```bash
scp /home/BACKUP_FILE.sql  user@ip:path/file.sql
```
