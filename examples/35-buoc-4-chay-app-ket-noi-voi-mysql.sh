docker run -dp 127.0.0.1:3000:3000 \
  -w /app \
  -v "$(pwd):/app" \
  --network todo-network \
  -e MYSQL_HOST=mysql \
  -e MYSQL_USER=root \
  -e MYSQL_PASSWORD=secret \
  -e MYSQL_DB=todos \
  todo-image \
  sh -c "yarn install && yarn run dev"
