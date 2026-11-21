# :ro (read-only) — container chỉ ĐỌC, không ghi được vào thư mục host
# Hữu ích khi mount config, static assets, hoặc khi muốn "đảm bảo" container không phá code
docker run -d -v "$(pwd)/config:/etc/app/config:ro" my-app

# :rw (read-write) — mặc định, có thể ghi lẫn nhau
docker run -d -v "$(pwd):/app:rw" my-app
