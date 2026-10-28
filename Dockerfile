# syntax=docker/dockerfile:1

# ===== Stage 1: build =====
FROM node:22-alpine AS build
WORKDIR /app

# Copy file manifest trước để tận dụng build cache
COPY package.json package-lock.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY . .

# ===== Stage 2: production (chỉ chứa những gì cần để chạy) =====
FROM node:22-alpine AS production
WORKDIR /app

ENV NODE_ENV=production

# Chỉ copy node_modules production từ stage build
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/src ./src
COPY package.json ./

# Chạy bằng user non-root (bảo mật)
USER node

EXPOSE 3000
CMD ["node", "src/index.js"]
