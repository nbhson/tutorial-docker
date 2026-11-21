# Anonymous volume: không có tên bên trái dấu ":"
docker run -d -v /var/lib/mysql mysql:8.0

# Named volume: có tên bên trái
docker run -d -v todo-mysql-data:/var/lib/mysql mysql:8.0
