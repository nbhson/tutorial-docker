# Tìm image theo tên
docker search nginx

# Tìm image và giới hạn kết quả
docker search --limit 5 nginx

# Tìm image theo số stars
docker search --filter stars=100 nginx

# Tìm official image only
docker search --filter is-official=true nginx

# Tìm image có Automated build
docker search --filter is-automated=true nginx
