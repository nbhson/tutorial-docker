# Xem tất cả image của bạn
docker image ls

# Filter image theo repository
docker image ls <your-username>/docker-tutorial

# Filter theo tag
docker image ls --filter reference=<your-username>/docker-tutorial:*

# Format output
docker image ls --format "{{.Repository}}:{{.Tag}} - {{.Size}}"
