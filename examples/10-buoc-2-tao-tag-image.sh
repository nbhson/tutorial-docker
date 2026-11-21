# Build image với tên và tag
docker build -t todo-image:1.0 .

# Tag image với namespace Docker Hub
docker tag todo-image:1.0 <your-username>/docker-tutorial:1.0

# Tag nhiều tag khác nhau cho cùng 1 image
docker tag todo-image:1.0 <your-username>/docker-tutorial:latest
docker tag todo-image:1.0 <your-username>/docker-tutorial:1.0.1
