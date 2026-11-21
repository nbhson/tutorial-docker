# Tải image từ Docker Hub Registry API
curl -s "https://hub.docker.com/v2/repositories/<your-username>/docker-tutorial/tags/" | jq

# Xem thông tin repo
curl -s "https://hub.docker.com/v2/repositories/<your-username>/docker-tutorial/" | jq
