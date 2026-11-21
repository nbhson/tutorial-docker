docker run -dp 127.0.0.1:3000:3000 \
  -w /app \
  -v "$(pwd):/app" \
  node:22-alpine \
  sh -c "yarn install && yarn run dev"
