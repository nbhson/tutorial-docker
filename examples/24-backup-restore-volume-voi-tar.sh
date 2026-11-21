# Tạo volume trống rồi giải nén backup vào
docker run --rm \
  -v todo-mysql-data:/data \
  -v "$(pwd)":/backup:ro \
  alpine \
  tar xzf /backup/todo-mysql-data-backup.tar.gz -C /data
