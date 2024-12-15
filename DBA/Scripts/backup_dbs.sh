dir="/path/to/backup/folder"
times=$(date +%Y%m%d%H%M%S)
user="postgres"

mkdir -p $dir
dbs=$(psql -U $user -lqt | cut -d \| -f 1 | grep -w -v template0 | grep -w -v template1 | grep -w -v postgres)


for DB in $dbs; do
    echo "Backing up $DB..."
    pg_dump -U $user -Fc $DB > "$dir/${DB}_$times_$user.backup"
done

