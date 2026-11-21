# Build đến stage cuối (production)
docker build -t todo-image:multi-stage .

# Chỉ build đến stage "build" (dùng để debug / chạy test)
docker build --target build -t todo-image:debug .

# Kiểm tra build config theo best practices (BuildKit checks)
docker build --check .
