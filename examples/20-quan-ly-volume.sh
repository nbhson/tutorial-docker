# Liệt kê tất cả volumes
docker volume ls

# Xem chi tiết volume (mountpoint, driver, size...)
docker volume inspect todo-mysql-data

# Xóa volume (chỉ khi chắc chắn không cần data)
docker volume rm todo-mysql-data

# Xóa các volume không còn được container nào dùng
docker volume prune

# Xóa MỌI volume không dùng (⚠️ bao gồm cả data cũ, không hỏi lại)
docker volume prune -a

# Xóa volume khi dừng compose stack (⚠️ mất data!)
docker compose down -v
