# Khởi động tất cả services (background mode)
docker compose up -d

# Xem logs tất cả services
docker compose logs -f

# Dừng tất cả services
docker compose down

# Dừng và xóa cả volumes (⚠️ xóa data!)
docker compose down -v

# Xem danh sách services đang chạy
docker compose ps

# Rebuild và restart service
docker compose up -d --build

# Chạy lệnh trong service
docker compose exec application sh

# Validate file compose.yaml (kiểm tra lỗi syntax)
docker compose config

# Xem cấu hình sau khi merge .env (compose v2.24+)
docker compose config --format json
