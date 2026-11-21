# Xem chi tiết image (bao gồm size, layers, tags)
docker image inspect <your-username>/docker-tutorial:1.0

# Xem history (các layers) của image
docker history <your-username>/docker-tutorial:1.0

# Xóa local image sau khi push
docker image rm <your-username>/docker-tutorial:1.0

# Dọn dẹp các image không sử dụng (dangling images)
docker image prune

# Dọn dẹp TẤT CẢ image không sử dụng
docker image prune -a

# Xóa image local theo ID
docker image rm <image-id>
