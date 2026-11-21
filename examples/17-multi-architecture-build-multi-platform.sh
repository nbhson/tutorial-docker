# Tạo builder hỗ trợ buildx (multi-platform)
docker buildx create --name mybuilder --use
docker buildx inspect --bootstrap

# Build image cho nhiều platform cùng lúc
docker buildx build --platform linux/amd64,linux/arm64 \
  -t <your-username>/docker-tutorial:1.0 . --push

# Build và push
docker buildx build --platform linux/amd64,linux/arm64 \
  -t <your-username>/docker-tutorial:latest \
  --push .
