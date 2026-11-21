# 1. Dừng và xóa container cũ
docker stop todo-app
docker rm todo-app

# 2. Rebuild image
docker build -t todo-image .

# 3. Tạo container mới
docker run -dp 3000:3000 --name todo-app todo-image
