# Đăng ký organization với Docker Scout
docker scout enroll <ORG_NAME>

# Bật Docker Scout cho repository trên Docker Hub
docker scout repo enable --org <ORG_NAME> <ORG_NAME>/docker-tutorial

# Push image → Scout tự phân tích, cập nhật real-time khi có CVE mới
docker push <your-username>/docker-tutorial:latest
