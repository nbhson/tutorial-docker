# syntax=docker/dockerfile:1

# 1. Chọn base image - Node.js 22 trên Alpine Linux (nhẹ). Node 18 đã EOL 04/2025.
FROM node:22-alpine

# 2. Đặt thư mục làm việc trong container
WORKDIR /app

# 3. Copy toàn bộ source code vào container
COPY . .

# 4. Cài đặt dependencies
RUN yarn install --production

# 5. Khởi chạy ứng dụng
CMD ["node", "src/index.js"]

# 6. Mở port 3000
EXPOSE 3000
