# Docker Tutorial - Xây dựng Todo App với Docker

> Tutorial hướng dẫn sử dụng Docker từ cơ bản đến nâng cao thông qua việc xây dựng một ứng dụng **Todo CRUD API** sử dụng Node.js, Express và MySQL.

---

## Mục lục

1. [Giới thiệu](#1-giới-thiệu)
2. [Các khái niệm cơ bản](#2-các-khái-niệm-cơ-bản)
3. [Part 1: Viết Dockerfile & Build Image](#part-1-viết-dockerfile--build-image)
4. [Part 2: Quản lý Container](#part-2-quản-lý-container)
5. [Part 3: Chia sẻ Image lên Docker Hub](#part-3-chia-sẻ-image-lên-docker-hub)
6. [Part 4: Persist Data với Volumes](#part-4-persist-data-volumes)
7. [Part 5: Dev Mode với Bind Mounts](#part-5-dev-mode-v-bind-mounts)
8. [Part 6: Multi-container với Networking](#part-6-multi-container-vi-mạng)
9. [Part 7: Docker Compose](#part-7-docker-compose)
10. [Tài liệu tham khảo](#tài-liệu-tham-kháo)

---

## 1. Giới thiệu

### Docker là gì?

Docker là một nền tảng mã nguồn mở giúp đóng gói ứng dụng và các phụ thuộc của nó vào trong một đơn vị gọi là **container**. Container có thể chạy trên bất kỳ máy nào có Dockerinstalled, đảm bảo ứng dụng luôn hoạt động đồng nhất trên mọi môi trường.

### Tại sao phải dùng Docker?

Việc setup và deploy ứng dụng lên server rất phức tạp: cài đặt runtime, database, cấu hình môi trường, chưa kể sự khác biệt giữa các hệ điều hành. Docker giải quyết vấn đề này bằng cách:

- **Đồng nhất môi trường**: Dev, staging, production đều giống nhau
- **Tách biệt dịch vụ**: Mỗi container đảm nhận một nhiệm vụ (app, database, cache...)
- **Dễ dàng triển khai**: Chỉ cần chạy `docker run` là ứng dụng khởi chạy
- **Bảo mật mã nguồn**: Khách hàng không cần tiếp cận source code

### Các khái niệm chính

| Khái niệm | Mô tả |
|-----------|-------|
| **Docker Image** | Bản snapshot của môi trường phát triển (OS + dependencies + source code). Được tạo từ Dockerfile. |
| **Dockerfile** | File chứa các câu lệnh để tự động build Docker image. |
| **Docker Container** | Instance đang chạy của một Docker Image. |
| **Docker Hub** | Kho lưu trữ trực tuyến các Docker image (tương tự GitHub nhưng cho image). |
| **Docker Compose** | Công cụ định nghĩa và chạy multi-container applications. |

---

## 2. Các khái niệm cơ bản

### Yêu cầu

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) đã cài đặt trên máy tính
- Docker Hub account (miễn phí): https://hub.docker.com

### Kiểm tra cài đặt

```bash
docker --version
docker compose version
```

### Ứng dụng Demo

Chúng ta sẽ xây dựng một Todo API với các endpoint:

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| `GET` | `/items` | Lấy danh sách todos |
| `POST` | `/items` | Thêm todo mới |
| `PUT` | `/items/:id` | Cập nhật todo |
| `DELETE` | `/items/:id` | Xóa todo |

---

## Part 1: Viết Dockerfile & Build Image

### Bước 1: Clone repository

```bash
git clone https://github.com/nbhson/docker-tutorial.git
cd docker-tutorial
```

### Bước 2: Tìm hiểu Dockerfile

Dockerfile là "công thức" để xây dựng image. Xem file `Dockerfile` trong project:

```dockerfile
# syntax=docker/dockerfile:1

# 1. Chọn base image - Node.js 18 trên Alpine Linux (nhẹ)
FROM node:18-alpine

# 2. Đặt thư mục làm việc trong container
WORKDIR /app_container

# 3. Copy toàn bộ source code vào container
COPY . .

# 4. Cài đặt dependencies
RUN yarn install --production

# 5. Khởi chạy ứng dụng
CMD ["node", "src/index.js"]

# 6. Mở port 3000
EXPOSE 3000
```

**Giải thích từng instruction:**

| Instruction | Ý nghĩa |
|-------------|----------|
| `FROM` | Base image để bắt đầu build. Alpine Linux rất nhẹ (~5MB). |
| `WORKDIR` | Thư mục làm việc mặc định trong container. |
| `COPY` | Copy files từ host vào container. |
| `RUN` | Chạy lệnh trong quá trình build image (chỉ chạy 1 lần). |
| `CMD` | Lệnh mặc định để chạy khi container start. |
| `EXPOSE` | Khai báo port mà container sẽ dùng (chỉ tài liệu, không tự mở port). |

### Bước 3: Build image

```bash
docker build -t todo-image .
```

- `-t todo-image`: Đặt tên cho image
- `.`: Chỉ định Dockerfile ở thư mục hiện tại

### Bước 4: Chạy container lần đầu

```bash
docker run -dp 3000:3000 todo-image
```

- `-d`: Chạy ở chế độ background (detached)
- `-p 3000:3000`: Map port 3000 trên host với port 3000 trong container

Mở trình duyệt truy cập `http://localhost:3000` để thấy ứng dụng Todo đang chạy.

---

## Part 2: Quản lý Container

### Các lệnh cơ bản

```bash
# Xem danh sách container đang chạy
docker ps

# Xem tất cả container (bao gồm đã dừng)
docker ps -a

# Xem danh sách image
docker image ls
```

### Start / Stop / Xóa container

```bash
# Dừng container
docker stop <container-id>

# Khởi động lại container đã dừng
docker start <container-id>

# Xóa container
docker rm <container-id>
```

> 💡 **Mẹo:** Bạn có thể dùng tên image hoặc container name thay vì ID. Khi tạo container bằng `docker run`, có thể thêm `--name` để đặt tên:
> ```bash
> docker run -dp 3000:3000 --name todo-app todo-image
> ```

### Cập nhật ứng dụng (Rebuild container)

Khi thay đổi source code, bạn cần rebuild image và tạo container mới:

```bash
# 1. Dừng và xóa container cũ
docker stop todo-app
docker rm todo-app

# 2. Rebuild image
docker build -t todo-image .

# 3. Tạo container mới
docker run -dp 3000:3000 --name todo-app todo-image
```

> 🔍 Kiểm tra log của container:
> ```bash
> docker logs <container-id>
> docker logs -f <container-id>  # Theo dõi log real-time
> ```

---

## Part 3: Chia sẻ Image lên Docker Hub

### Bước 1: Đăng nhập Docker Hub

```bash
docker login
```

Nhập username và password (hoặc Access Token) của bạn.

### Bước 2: Tag image

```bash
docker build -t todo-image:1.0 .
docker tag todo-image:1.0 <your-username>/docker-tutorial:1.0
```

Ví dụ với username `nbhson`:

```bash
docker tag todo-image:1.0 nbhson/docker-tutorial:1.0
```

### Bước 3: Push lên Docker Hub

```bash
docker push <your-username>/docker-tutorial:1.0
```

### Bước 4: Chạy image từ Docker Hub

Bất kỳ ai cũng có thể chạy image của bạn:

```bash
docker run -dp 3000:3000 <your-username>/docker-tutorial:1.0
```

> 💡 Thử tại https://labs.play-with-docker.com/ - mở port 3000 và chạy lệnh trên!

---

## Part 4: Persist Data - Volumes

> ⚠️ **Vấn đề:** Khi xóa container, toàn bộ data bên trong sẽ mất. Làm thế nào để giữ lại data?

### Sử dụng Named Volumes

**Volume** là vùng nhớ lưu trữ bên ngoài container, được quản lý bởi Docker.

```bash
# Bước 1: Tạo volume
docker volume create todo-mysql-data

# Bước 2: Chạy container với volume được mount
docker run -dp 3000:3000 \
  --mount type=volume,src=todo-mysql-data,target=/var/lib/mysql \
  todo-image

# Bước 3: Kiểm tra thông tin volume
docker volume inspect todo-mysql-data
```

> 💡 Bây giờ dù bạn có xóa container và tạo lại, data vẫn được giữ nguyên vì nó nằm trong volume.

### Quản lý Volume

```bash
# Liệt kê tất cả volumes
docker volume ls

# Xóa volume (chỉ khi chắc chắn không cần data)
docker volume rm todo-mysql-data
```

---

## Part 5: Dev Mode - Bind Mounts

> Khi developing, bạn không muốn phải rebuild image mỗi lần thay đổi code. **Bind Mount** cho phép map thư mục source code từ host vào container.

### Chạy với Bind Mount

```bash
docker run -dp 127.0.0.1:3000:3000 \
  -w /app \
  -v "$(pwd):/app" \
  node:18-alpine \
  sh -c "yarn install && yarn run dev"
```

**Giải thích:**

| Flag | Ý nghĩa |
|------|----------|
| `-w /app` | Đặt working directory trong container |
| `-v "$(pwd):/app"` | Map thư mục hiện tại host vào `/app` trong container |
| `sh -c "yarn install && yarn run dev"` | Cài dependencies và chạy dev server |

> 💡 Với bind mount, mỗi khi bạn edit code trên host, container sẽ tự động update (qua nodemon). Chỉ cần refresh trình duyệt!

### Xem log real-time

```bash
docker logs -f <container-id>
```

---

## Part 6: Multi-container - Networking

> Một ứng dụng thực tế thường có nhiều services: App Server + Database + Cache. Mỗi service nên chạy trong một container riêng.

### Kiến trúc Todo App

```
┌─────────────────────────────────────────┐
│              Docker Network              │
│                                         │
│  ┌──────────────┐   ┌──────────────┐   │
│  │  Todo App    │   │    MySQL     │   │
│  │  (Node.js)   │──▶│   8.0        │   │
│  │  Port 3000   │   │  Port 3306   │   │
│  └──────────────┘   └──────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

### Bước 1: Tạo Network

```bash
docker network create todo-network
docker network ls
```

### Bước 2: Chạy MySQL container trên network

```bash
docker run -d \
  --network todo-network \
  --network-alias mysql \
  -v todo-mysql-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=secret \
  -e MYSQL_DATABASE=todos \
  mysql:8.0
```

**Giải thích:**

| Flag | Ý nghĩa |
|------|----------|
| `--network todo-network` | Kết nối container vào network đã tạo |
| `--network-alias mysql` | Đặt alias để các container khác có thể gọi là "mysql" |
| `-v todo-mysql-data:/var/lib/mysql` | Mount volume để persist data MySQL |
| `-e MYSQL_ROOT_PASSWORD=secret` | Đặt root password cho MySQL |
| `-e MYSQL_DATABASE=todos` | Tự tạo database "todos" khi start |

### Bước 3: Verify MySQL

```bash
# Vào terminal của MySQL container
docker exec -it <mysql-container-id> mysql -u root -p
# Nhập password: secret
```

```sql
-- Trong MySQL shell
SHOW DATABASES;
USE todos;
SHOW TABLES;
```

### Bước 4: Chạy App kết nối với MySQL

```bash
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
```

> 💡 **Lưu ý:** `MYSQL_HOST=mysql` dùng alias thay vì IP. Docker DNS sẽ tự động resolve tên `mysql` sang IP của MySQL container.

### Bước 5 (Tùy chọn): Kiểm tra DNS trong network

```bash
# Chạy container netshoot để tra cứu DNS
docker run -it --network todo-network nicolaka/netshoot

# Trong netshoot container
dig mysql
```

---

## Part 7: Docker Compose

> Quản lý nhiều container bằng lệnh `docker run` riêng lẻ rất rườm rà. **Docker Compose** cho phép định nghĩa toàn bộ multi-container application trong một file YAML.

### Docker Compose hoạt động như thế nào?

Docker Compose không chỉ đơn giản là "gộp" nhiều container lại — nó còn **tự động tạo một network riêng** để tất cả các services trong file `docker-compose.yml` có thể giao tiếp với nhau.

**Ví dụ kiến trúc 3-tier với Docker Compose:**

```
┌──────────────────────────────────────────────────────────┐
│                   Docker Network (tự tạo)                │
│                                                          │
│  ┌────────────┐   ┌────────────┐   ┌────────────────┐  │
│  │  Frontend  │   │   Backend  │   │   Database     │  │
│  │   (Nginx)  │──▶│ (Node.js)  │──▶│  (MySQL/       │  │
│  │  Port 80   │   │ Port 3000  │   │   PostgreSQL)  │  │
│  └────────────┘   └────────────┘   │  Port 5432     │  │
│                                    └────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

Ví dụ file `docker-compose.yml` cho kiến trúc 3-tier:

```yaml
services:
  frontend:
    image: nginx:alpine
    ports:
      - "80:80"
    networks:
      - app-network

  backend:
    build: ./backend
    environment:
      DB_HOST: database    # ← Kết nối đến DB qua tên service
      DB_PORT: 5432
    networks:
      - app-network

  database:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp
      POSTGRES_PASSWORD: secret
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - app-network

networks:
  app-network:         # ← Compose tự tạo network này
    driver: bridge

volumes:
  db-data:
```

> 💡 **Điểm quan trọng:** Trong Docker Compose, mỗi service có thể gọi nhau bằng **tên service** (ví dụ: `DB_HOST: database`). Compose tự động tạo DNS record cho mỗi service trong network. Bạn **không cần tạo network thủ công** bằng `docker network create` nữa!

### `docker compose up` chạy gì?

`docker compose up` sẽ **chạy TOÀN BỘ group container** được định nghĩa trong file `docker-compose.yml` cùng lúc:

```bash
docker compose up          # Chạy tất cả services
docker compose up -d       # Chạy tất cả services ở chế độ background
docker compose up frontend # Chỉ chạy service frontend
```

Khi chạy `docker compose up`, Docker sẽ:

1. **Kiểm tra image** — Nếu image chưa có, tự build hoặc pull từ Docker Hub
2. **Tạo network** — Tự động tạo network riêng cho group services (nếu chưa có)
3. **Tạo volumes** — Khai báo các named volumes
4. **Khởi chạy tất cả containers** — Theo thứ tự phụ thuộc (DB chạy trước BE, BE chạy trước FE...)
5. **Kết nối vào network** — Tất cả containers đều có thể gọi nhau qua tên service

```bash
# Dừng TOÀN BỘ group container
docker compose down
```

### So sánh: Tự quản lý vs Docker Compose

**Cách truyền thống (không dùng Compose):**

```bash
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
```

**Cách dùng Docker Compose:**

```bash
# Chỉ cần 1 lệnh, chạy cả 3 containers
docker compose up -d
```

| Tiêu chí | docker run truyền thống | Docker Compose |
|----------|------------------------|----------------|
| Số lệnh | Nhiều lệnh riêng lẻ | 1 lệnh `docker compose up` |
| Network | Phải tạo thủ công | Tự động tạo |
| Khởi động | Mỗi container 1 lệnh | Chạy tất cả cùng lúc |
| Stops | Mỗi container 1 lệnh | `docker compose down` là xong |
| Dependency | Phải tự thứ tự | Tự sắp xếp theo logic |
| Cấu hình | Phải nhớ tất cả flags | Định nghĩa 1 lần trong YAML |
| Reusability | Khó share | File YAML dễ share + version control |

### File docker-compose.yml

Xem file `docker-compose.yml` trong project:

```yaml
services:
  application:
    image: todo-image
    command: sh -c "yarn install && yarn run dev"
    ports:
      - 127.0.0.1:3000:3000
    working_dir: /app
    volumes:
      - ./:/app
    environment:
      MYSQL_HOST: mysql
      MYSQL_USER: root
      MYSQL_PASSWORD: secret
      MYSQL_DB: todos

  mysql:
    image: mysql:8.0
    volumes:
      - todo-mysql-data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: todos

volumes:
  todo-mysql-data:
```

**Giải thích cấu trúc:**

| Phần | Ý nghĩa |
|------|----------|
| `services` | Định nghĩa các container services |
| `application` | Service cho Todo App (Node.js) |
| `mysql` | Service cho MySQL database |
| `volumes` (top-level) | Khai báo named volume được dùng chung |

### Các lệnh Docker Compose

```bash
# Khởi động tất cả services (background mode)
docker compose up -d

# Xem logs tất cả services
docker compose logs -f

# Dừng tất cả services
docker compose down

# Dừng và xóa cả volumes (⚠️ xóa data!)
docker compose down -v

# Xem danh sách services đang chạy
docker compose ps

# Rebuild và restart service
docker compose up -d --build
```

### So sánh: docker run vs docker compose

| docker run | docker compose |
|------------|----------------|
| Mỗi lệnh chạy 1 container | Chạy nhiều container cùng lúc |
| Phải nhớ nhiều flags | Định nghĩa 1 lần trong YAML |
| Khó tái sử dụng | Dễ tái sử dụng và share |
| Phù hợp chạy nhanh/test | Phù hợp multi-service apps |

---

## Tổng kết

Trong tutorial này, bạn đã học được:

- [x] Viết **Dockerfile** để đóng gói ứng dụng
- [x] Build **Image** và chạy **Container**
- [x] Quản lý container (start/stop/rm/logs)
- [x] Chia sẻ image lên **Docker Hub**
- [x] Sử dụng **Volumes** để persist data
- [x] Sử dụng **Bind Mounts** cho development
- [x] Tạo **Multi-container** application với networking
- [x] Sử dụng **Docker Compose** để quản lý multi-service

### Lệnh Docker Reference

```bash
# Images
docker build -t <name> .          # Build image
docker image ls                   # List images
docker image rm <image>           # Remove image

# Containers
docker run -dp <host>:<container> <image>  # Run container
docker ps                                     # List running containers
docker ps -a                                  # List all containers
docker stop <container>                       # Stop container
docker start <container>                      # Start container
docker rm <container>                         # Remove container
docker logs -f <container>                    # View logs
docker exec -it <container> sh                # Shell into container

# Volumes
docker volume create <name>       # Create volume
docker volume ls                  # List volumes
docker volume inspect <name>      # Inspect volume

# Compose
docker compose up -d              # Start all services
docker compose down               # Stop all services
docker compose ps                 # List services
docker compose logs -f            # View logs
```

---

## Tài liệu tham khảo

- [Docker Official Documentation](https://docs.docker.com/get-started/)
- [Docker Hub](https://hub.docker.com)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Play With Docker](https://labs.play-with-docker.com/)