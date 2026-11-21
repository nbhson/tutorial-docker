# Xem anonymous volumes "rác" tích tụ theo thời gian
docker volume ls --filter dangling=true

# Dọn rác anonymous volumes
docker volume prune
