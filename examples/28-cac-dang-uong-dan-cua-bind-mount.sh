# Đường dẫn tuyệt đối
docker run -v /home/son/project:/app my-app

# Đường dẫn tương đối so với thư mục hiện tại (khuyến nghị trong script)
docker run -v "$(pwd):/app" my-app

# Trong compose.yaml: "./" = thư mục chứa file compose.yaml
volumes:
  - ./:/app
  - ./src:/app/src:ro   # chỉ đọc source, container không ghi đè được
