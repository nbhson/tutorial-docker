# Phải chạy 3 lệnh riêng lẻ, mỗi lệnh tạo 1 container
docker network create my-network

docker run -d --name database --network my-network \
  -e POSTGRES_DB=myapp -e POSTGRES_PASSWORD=secret \
  postgres:15

docker run -d --name backend --network my-network \
  -e DB_HOST=database \
  node-app

docker run -d --name frontend --network my-network \
  -p 80:80 nginx:alpine
