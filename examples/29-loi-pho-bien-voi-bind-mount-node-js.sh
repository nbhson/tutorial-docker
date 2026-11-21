docker run -dp 127.0.0.1:3000:3000 \
  -v "$(pwd):/app" \
  -v /app/node_modules \
  node:22-alpine \
  sh -c "yarn install && yarn run dev"
