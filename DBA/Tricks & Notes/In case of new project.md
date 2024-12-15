
***
CREATING NEW USER :
```bash
 create user newuser with password 'admin';
```

CREATING NEW DATABASE :
```bash
create database dbtest_sg;
alter database dbtest_sg owner to test_sg;
```

GRANT PRIVILEGES :
```bash
grant all privileges on schema public to newuser;
grant select , update, delete, select on all tables in schema public to newuser;
```

RETREIVE ENCRYPTED PASSWORD :
```bash
select rolname, rolpassword from pg_authid ;
```
***

CHANGING THE pg_hba.conf FILE :
```bash
sudo nano /etc/postgresql/14/main/pg_hba.conf
host    db         user                  host            md5
```

CHANGING THE PGPOUNCER FILES:
```bash
sudo nano /etc/pgbouncer/pgbouncer.ini
db     = host=host port=5789 dbname=db
sudo nano /etc/pgbouncer/userlist.txt
 "user" "md.........................."
```

RESTARTING POSTGRESQL :
```bash
sudo systemctl restart postgresql
```

RESTARTING PGBOUNCER :
```bash
sudo systemctl restart pgbouncer.service
```