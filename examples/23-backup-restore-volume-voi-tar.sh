# Mount volume vào /data (ro) và thư mục hiện tại vào /backup, rồi nén tar
docker run --rm \
  -v todo-mysql-data:/data:ro \
  -v "$(pwd)":/backup \
  alpine \
  tar czf /backup/todo-mysql-data-backup.tar.gz -C /data .

# Kết quả: file todo-mysql-data-backup.tar.gz trong thư mục hiện tại
ls -lh todo-mysql-data-backup.tar.gz
