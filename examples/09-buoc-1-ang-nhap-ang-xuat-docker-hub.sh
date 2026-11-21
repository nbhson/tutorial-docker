# Đăng nhập Docker Hub
docker login

# Đăng nhập với username cụ thể
docker login -u <your-username>

# Đăng nhập bằng Access Token (an toàn hơn password)
echo "<your-access-token>" | docker login -u <your-username> --password-stdin

# Đăng xuất
docker logout
