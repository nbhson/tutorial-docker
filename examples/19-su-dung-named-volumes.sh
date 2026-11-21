# Bước 1: Tạo volume
docker volume create todo-mysql-data

# Bước 2: Chạy container với volume được mount
docker run -dp 3000:3000 \
  --mount type=volume,src=todo-mysql-data,target=/var/lib/mysql \
  todo-image

# Bước 3: Kiểm tra thông tin volume
docker volume inspect todo-mysql-data
