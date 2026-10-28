# Docker Tutorial - Xây dựng Todo App với Docker

> Tutorial hướng dẫn sử dụng Docker từ cơ bản đến nâng cao thông qua việc xây dựng một ứng dụng **Todo CRUD API** sử dụng Node.js, Express và MySQL.

## 📌 Version sử dụng trong tutorial (cập nhật 10/2026)

| Thành phần | Version | Ghi chú |
|------------|---------|---------|
| **Docker Engine** | 27.x / 28.x / 29.x | Engine 28 (ra 02/2025, mới nhất `28.5.2`) và Engine 29 (ra 11/2025, mới nhất `29.9.2`). Engine 27.x đã hết hỗ trợ. |
| **Docker Compose** | v2.x / v5.x | Compose v2 (CLI `docker compose`, từ 2.40.x) và Compose v5 (ra 12/2025, mới nhất 5.6.1 tại thời điểm viết 10/2026) — cả hai đều dùng **Compose Specification**. |
| **Compose file format** | Compose Specification | Không còn dùng `version: "2.x"` hay `version: "3.x"` trong file YAML (đã **obsolete**). Tên file khuyến nghị: `compose.yaml`. |
| **BuildKit / Buildx** | BuildKit v0.25+ / Buildx v0.28+ | Build mặc định qua BuildKit, hỗ trợ multi-stage, cache mount, build checks. |

> ⚠️ **Quan trọng:** Nếu bạn vẫn đang dùng Docker Compose v1 (`docker-compose` viết thường, Python-based) thì đã **EOL từ 06/2023**. Hãy nâng cấp lên Docker Desktop (Compose v2/v5 tích hợp sẵn) hoặc Docker Engine 28+.

---

## Mục lục

1. [Giới thiệu](#1-giới-thiệu)
2. [Các khái niệm cơ bản](#2-các-khái-niệm-cơ-bản)
3. [Part 1: Viết Dockerfile & Build Image](#part-1-viết-dockerfile--build-image)
4. [Part 2: Quản lý Container](#part-2-quản-lý-container)
5. [Part 3: Thao tác với Docker Hub](#part-3-thao-tác-với-docker-hub)
6. [Part 4: Persist Data với Volumes](#part-4-persist-data-với-volumes)
7. [Part 5: Dev Mode với Bind Mounts](#part-5-dev-mode-với-bind-mounts)
8. [Part 6: Multi-container với Networking](#part-6-multi-container-với-networking)
9. [Part 7: Docker Compose (Compose Specification)](#part-7-docker-compose-compose-specification)
10. [Part 8: Multi-stage Builds](#part-8-multi-stage-builds)
11. [Part 9: Docker Scout - Security Scanning](#part-9-docker-scout---security-scanning)
12. [Part 10: CI/CD với GitHub Actions](#part-10-cicd-với-github-actions)
13. [Best Practices tổng hợp](#best-practices-tổng-hợp)
14. [Tài liệu tham khảo](#tài-liệu-tham-khảo)

---

## 1. Giới thiệu

### Docker là gì?

Docker là một nền tảng mã nguồn mở giúp đóng gói ứng dụng và các phụ thuộc của nó vào trong một đơn vị gọi là **container**. Container có thể chạy trên bất kỳ máy nào có Docker installed, đảm bảo ứng dụng luôn hoạt động đồng nhất trên mọi môi trường.

### Tại sao phải dùng Docker?

Việc setup và deploy ứng dụng lên server rất phức tạp: cài đặt runtime, database, cấu hình môi trường, chưa kể sự khác biệt giữa các hệ điều hành. Docker giải quyết vấn đề này bằng cách:

- **Đồng nhất môi trường**: Dev, staging, production đều giống nhau
- **Tách biệt dịch vụ**: Mỗi container đảm nhận một nhiệm vụ (app, database, cache...)
- **Dễ dàng triển khai**: Chỉ cần chạy `docker run` là ứng dụng khởi chạy
- **Bảo mật mã nguồn**: Lưu ý quan trọng — **image KHÔNG phải là hộp đen**. Bất kỳ ai có image đều có thể trích xuất được source code bên trong bằng `docker history <image>` (xem từng layer) hoặc `docker save` + export từng layer. Vì vậy:
  - **Không bao giờ** nhúng secret (API key, password, private key) vào image qua `COPY`, `ENV` hay `ARG` — ngay cả khi bạn xóa file ở layer sau, file vẫn còn trong layer trước
  - Secret nên truyền lúc runtime qua biến môi trường, Docker secrets, hoặc secret manager
  - Dùng `.dockerignore` để loại trừ `.env`, credential files khỏi build context (xem Part 1)

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
# Docker Engine version (27.x/28.x/29.x)
docker --version
# Docker Engine v29.9.2 — phiên bản mới nhất tính đến 10/2026

# Docker Compose CLI (v2.x / v5.x) — dùng "docker compose" (không có dấu gạch ngang)
docker compose version
# Docker Compose version v5.6.1 (mới nhất tại thời điểm viết 10/2026, dùng Compose Specification)

# BuildKit + Buildx (mặc định từ Engine v23+)
docker buildx version
# docker buildx github.com/docker/buildx v0.28.0

# Docker Scout (tích hợp sẵn từ Docker Desktop 4.23+ / Engine v27+)
docker scout version
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
```

> 💡 **Lưu ý:** Dockerfile ở trên là phiên bản đơn giản để học. Dockerfile thực tế trong repo là phiên bản **multi-stage** (2 stage + `USER node`) — xem chi tiết ở [Part 8: Multi-stage Builds](#part-8-multi-stage-builds). Ngoài ra, project có sẵn file **`.dockerignore`** để loại trừ `node_modules`, `.git`, `.env`, `spec/`, logs... khỏi build context — giúp build nhanh hơn và tránh leak secret vào image.

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

## Part 3: Thao tác với Docker Hub

> **Docker Hub** là kho lưu trữ image trực tuyến, nơi bạn có thể chia sẻ và tải về các Docker image. Tương tự như GitHub nhưng dành cho Docker image.

### Bước 1: Đăng nhập / Đăng xuất Docker Hub

```bash
# Đăng nhập Docker Hub
docker login

# Đăng nhập với username cụ thể
docker login -u <your-username>

# Đăng nhập bằng Access Token (an toàn hơn password)
echo "<your-access-token>" | docker login -u <your-username> --password-stdin

# Đăng xuất
docker logout
```

> 💡 **Lưu ý:** Docker Desktop có thể tự duy trì session đăng nhập. Dùng `docker logout` để xóa thông tin đăng nhập trên máy.

### Bước 2: Tạo & Tag Image

```bash
# Build image với tên và tag
docker build -t todo-image:1.0 .

# Tag image với namespace Docker Hub
docker tag todo-image:1.0 <your-username>/docker-tutorial:1.0

# Tag nhiều tag khác nhau cho cùng 1 image
docker tag todo-image:1.0 <your-username>/docker-tutorial:latest
docker tag todo-image:1.0 <your-username>/docker-tutorial:1.0.1
```

**Quy tắc đặt tên image cho Docker Hub:**

| Format | Ý nghĩa |
|--------|----------|
| `<username>/<repo>` | Image trong account cá nhân |
| `<org>/<repo>` | Image thuộc organization |
| `library/<repo>` | Image chính thức (official image) |
| `<username>/<repo>:<tag>` | Version cụ thể |
| `<username>/<repo>:latest` | Tag mặc định (latest) |

### Bước 3: Push Image lên Docker Hub

```bash
# Push image với tag cụ thể
docker push <your-username>/docker-tutorial:1.0

# Push image latest
docker push <your-username>/docker-tutorial:latest

# Push tất cả các tag của cùng 1 repository
docker push <your-username>/docker-tutorial --all-tags
```

### Bước 4: Pull Image từ Docker Hub

```bash
# Pull image chính thức
docker pull nginx
docker pull nginx:alpine
docker pull nginx:1.25

# Pull image từ account cá nhân
docker pull <your-username>/docker-tutorial:1.0

# Pull image latest (mặc định)
docker pull <your-username>/docker-tutorial
```

### Bước 5: Chạy image từ Docker Hub

Bất kỳ ai cũng có thể chạy image của bạn:

```bash
docker run -dp 3000:3000 <your-username>/docker-tutorial:1.0
```

> 💡 Thử tại https://labs.play-with-docker.com/ - mở port 3000 và chạy lệnh trên!

### Tìm kiếm Image trên Docker Hub

```bash
# Tìm image theo tên
docker search nginx

# Tìm image và giới hạn kết quả
docker search --limit 5 nginx

# Tìm image theo số stars
docker search --filter stars=100 nginx

# Tìm official image only
docker search --filter is-official=true nginx

# Tìm image có Automated build
docker search --filter is-automated=true nginx
```

### Quản lý Remote Image

```bash
# Xem chi tiết image (bao gồm size, layers, tags)
docker image inspect <your-username>/docker-tutorial:1.0

# Xem history (các layers) của image
docker history <your-username>/docker-tutorial:1.0

# Xóa local image sau khi push
docker image rm <your-username>/docker-tutorial:1.0

# Dọn dẹp các image không sử dụng (dangling images)
docker image prune

# Dọn dẹp TẤT CẢ image không sử dụng
docker image prune -a

# Xóa image local theo ID
docker image rm <image-id>
```

### Xem thông tin về repository

```bash
# Xem tất cả image của bạn
docker image ls

# Filter image theo repository
docker image ls <your-username>/docker-tutorial

# Filter theo tag
docker image ls --filter reference=<your-username>/docker-tutorial:*

# Format output
docker image ls --format "{{.Repository}}:{{.Tag}} - {{.Size}}"
```

### Multi-Architecture Build (Multi-Platform)

```bash
# Tạo builder hỗ trợ buildx (multi-platform)
docker buildx create --name mybuilder --use
docker buildx inspect --bootstrap

# Build image cho nhiều platform cùng lúc
docker buildx build --platform linux/amd64,linux/arm64 \
  -t <your-username>/docker-tutorial:1.0 . --push

# Build và push
docker buildx build --platform linux/amd64,linux/arm64 \
  -t <your-username>/docker-tutorial:latest \
  --push .
```

### Docker Hub API (thông qua CLI)

```bash
# Tải image từ Docker Hub Registry API
curl -s "https://hub.docker.com/v2/repositories/<your-username>/docker-tutorial/tags/" | jq

# Xem thông tin repo
curl -s "https://hub.docker.com/v2/repositories/<your-username>/docker-tutorial/" | jq
```

### Best Practices khi sử dụng Docker Hub

1. **Luôn sử dụng tag cụ thể** — Tránh dùng `latest` trong production vì nó có thể thay đổi bất ngờ.
2. **Viết README tốt** — Docker Hub hỗ trợ Markdown README cho mỗi repository.
3. **Sử dụng Access Token** — Thay vì password, tạo Access Token trong Docker Hub Settings > Security.
4. **Kiểm tra vulnerability** — Docker Hub có tích hợp Docker Scout để scan vulnerabilities.
5. **Automated Build** — Kết nối repository GitHub/GitLab để tự động build image khi có commit mới.

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

# Xem chi tiết volume (mountpoint, driver, size...)
docker volume inspect todo-mysql-data

# Xóa volume (chỉ khi chắc chắn không cần data)
docker volume rm todo-mysql-data

# Xóa các volume không còn được container nào dùng
docker volume prune

# Xóa MỌI volume không dùng (⚠️ bao gồm cả data cũ, không hỏi lại)
docker volume prune -a

# Xóa volume khi dừng compose stack (⚠️ mất data!)
docker compose down -v
```

> ⚠️ **Cẩn thận với `prune`:** `docker volume prune` chỉ xóa volume **anonymous** và volume không được container nào tham chiếu. Nhưng nếu bạn quên gắn volume vào container trong lần chạy sau, data vẫn tồn tại — đến khi bạn chạy `prune -a` thì mất hẳn. Trước khi prune, luôn kiểm tra lại bằng `docker volume ls`.

### Anonymous Volumes vs Named Volumes

Có **2 loại volume**:

| | Anonymous Volume | Named Volume |
|---|---|---|
| Cách tạo | `-v /var/lib/mysql` (chỉ path trong container) | `-v todo-mysql-data:/var/lib/mysql` hoặc `docker volume create` |
| Tên | Hash ngẫu nhiên, ví dụ `d7f1a...` | Tên bạn đặt, dễ đọc |
| Tái sử dụng | Khó — phải tra hash bằng `docker volume ls` | Dễ — tham chiếu theo tên |
| Dọn dẹp | Tự xóa khi dùng `--rm` với container | Phải xóa thủ công / bằng `prune` |
| Khi nào dùng | Container tạm, cache build (ví dụ `/app/node_modules`) | Dữ liệu cần giữ lâu dài (database, uploads) |

```bash
# Anonymous volume: không có tên bên trái dấu ":"
docker run -d -v /var/lib/mysql mysql:8.0

# Named volume: có tên bên trái
docker run -d -v todo-mysql-data:/var/lib/mysql mysql:8.0
```

```bash
# Xem anonymous volumes "rác" tích tụ theo thời gian
docker volume ls --filter dangling=true

# Dọn rác anonymous volumes
docker volume prune
```

> 💡 **Mẹo:** Trong Dockerfile, mỗi `VOLUME /path` khai báo cũng tạo anonymous volume mỗi lần chạy container. Vì vậy nên khai báo volume ở tầng `compose.yaml` hoặc `docker run`, ít khai báo trong Dockerfile.

### Backup & Restore Volume với tar

Volume không nằm trong container nên xóa container không mất data — nhưng **xóa volume thì mất thật**. Backup bằng cách mount cả volume lẫn thư mục backup vào một container tạm rồi đóng gói tar:

**Backup:**

```bash
# Mount volume vào /data (ro) và thư mục hiện tại vào /backup, rồi nén tar
docker run --rm \
  -v todo-mysql-data:/data:ro \
  -v "$(pwd)":/backup \
  alpine \
  tar czf /backup/todo-mysql-data-backup.tar.gz -C /data .

# Kết quả: file todo-mysql-data-backup.tar.gz trong thư mục hiện tại
ls -lh todo-mysql-data-backup.tar.gz
```

**Restore:**

```bash
# Tạo volume trống rồi giải nén backup vào
docker run --rm \
  -v todo-mysql-data:/data \
  -v "$(pwd)":/backup:ro \
  alpine \
  tar xzf /backup/todo-mysql-data-backup.tar.gz -C /data
```

**Giải thích:**

| Phần | Ý nghĩa |
|------|----------|
| `--rm` | Container tạm tự xóa sau khi chạy xong |
| `-v todo-mysql-data:/data:ro` | Mount volume cần backup, chỉ đọc (`:ro`) để an toàn |
| `-v "$(pwd)":/backup` | Map thư mục host để lưu file tar |
| `tar czf ... -C /data .` | Nén toàn bộ nội dung volume vào file tar |

> 💡 Với MySQL, cách backup "đúng chuẩn" hơn là dùng `mysqldump` trong container để xuất file `.sql`:
> ```bash
> docker exec <mysql-container-id> \
>   mysqldump -u root -psecret todos > todos-backup.sql
> ```
> Cách tar volume phù hợp backup "nguyên trạng" mọi loại data (không chỉ database).

---

## Part 5: Dev Mode - Bind Mounts

> Khi developing, bạn không muốn phải rebuild image mỗi lần thay đổi code. **Bind Mount** cho phép map thư mục source code từ host vào container.

### Chạy với Bind Mount

```bash
docker run -dp 127.0.0.1:3000:3000 \
  -w /app \
  -v "$(pwd):/app" \
  node:22-alpine \
  sh -c "yarn install && yarn run dev"
```

**Giải thích:**

| Flag | Ý nghĩa |
|------|----------|
| `-w /app` | Đặt working directory trong container |
| `-v "$(pwd):/app"` | Map thư mục hiện tại host vào `/app` trong container |
| `sh -c "yarn install && yarn run dev"` | Cài dependencies và chạy dev server |

> 💡 Với bind mount, mỗi khi bạn edit code trên host, container sẽ tự động update (qua nodemon). Chỉ cần refresh trình duyệt!

### Bind Mount flags: `:ro`, `:rw`, `:z`, `:Z`

Bạn có thể thêm **options** vào cuối bind mount (sau dấu `:` thứ hai), cách nhau bằng dấu phẩy:

```bash
# :ro (read-only) — container chỉ ĐỌC, không ghi được vào thư mục host
# Hữu ích khi mount config, static assets, hoặc khi muốn "đảm bảo" container không phá code
docker run -d -v "$(pwd)/config:/etc/app/config:ro" my-app

# :rw (read-write) — mặc định, có thể ghi lẫn nhau
docker run -d -v "$(pwd):/app:rw" my-app
```

**SELinux labels (dành cho Fedora/RHEL/CentOS — host có SELinux enforcing):**

| Flag | Ý nghĩa |
|------|---------|
| `:z` | Gắn label SELinux **shared**: nhiều container có thể mount cùng nội dung này |
| `:Z` | Gắn label SELinux **private**: CHỈ container hiện tại được dùng nội dung này |

```bash
# Trên Fedora/RHEL, nếu không có :z/:Z container sẽ bị "Permission denied"
docker run -d -v "$(pwd):/app:z" my-app
```

> 💡 Trên macOS và hầu hết môi trường dev (Ubuntu không bật SELinux enforcing) bạn không cần `:z`/`:Z`. Nhưng nếu tutorial/CI của bạn chạy trên Fedora, RHEL, CentOS — nhớ thêm flag này, lỗi `Permission denied` khi bind mount gần như luôn do SELinux.
>
> ⚠️ `:Z` re-label toàn bộ thư mục host — đừng dùng với thư mục hệ thống như `$HOME`.

### Các dạng đường dẫn của bind mount

```bash
# Đường dẫn tuyệt đối
docker run -v /home/son/project:/app my-app

# Đường dẫn tương đối so với thư mục hiện tại (khuyến nghị trong script)
docker run -v "$(pwd):/app" my-app

# Trong compose.yaml: "./" = thư mục chứa file compose.yaml
volumes:
  - ./:/app
  - ./src:/app/src:ro   # chỉ đọc source, container không ghi đè được
```

### Lỗi phổ biến với bind mount + Node.js

Khi bind mount `./:/app`, thư mục `node_modules` trên host (rỗng hoặc thiếu) sẽ **che** mất `node_modules` trong container. Cách xử lý kinh điển — dùng anonymous volume "chặn" riêng:

```bash
docker run -dp 127.0.0.1:3000:3000 \
  -v "$(pwd):/app" \
  -v /app/node_modules \
  node:22-alpine \
  sh -c "yarn install && yarn run dev"
```

Volume thứ hai (anonymous) giữ `node_modules` của container, không bị bind mount từ host đè lên. Xóa container kèm `--rm` sẽ dọn anonymous volume này.

| So sánh | Named Volume | Bind Mount |
|---------|--------------|------------|
| Vị trí lưu | Do Docker quản lý (trong Docker Desktop VM) | Bất kỳ đâu trên host |
| Ai tạo nội dung | Container / Docker | Bạn (source code, config) |
| Tính di động | Cao — không phụ thuộc cấu trúc thư mục host | Thấp — phụ thuộc đường dẫn host |
| Hiệu năng (macOS/Windows) | Tốt hơn với nhiều file nhỏ | Chậm hơn, trừ khi dùng `compose watch` sync |
| Khi nào dùng | Dữ liệu production (database), chia sẻ giữa container | Dev mode (live-reload code), mount config |
| Backup | Phải tar/export (xem Part 4) | Trực tiếp trên host |

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

## Part 7: Docker Compose (Compose Specification)

> Quản lý nhiều container bằng lệnh `docker run` riêng lẻ rất rườm rà. **Docker Compose** cho phép định nghĩa toàn bộ multi-container application trong một file YAML.

### Docker Compose v2/v5 — Điểm gì đã thay đổi?

Docker Compose có ba giai đoạn:

| Thời kỳ | CLI | File format | Ghi chú |
|---------|-----|------------|---------|
| **Compose v1** (2014–2020) | `docker-compose` (Python) | `version: 2.x`, `version: 3.x` | Đã **EOL 06/2023** |
| **Compose v2** (2020–2025) | `docker compose` (Go) | **Compose Specification** (rolling) | `version:` field **obsolete/warning** |
| **Compose v5** (12/2025–nay) | `docker compose` (Go + SDK) | **Compose Specification** (rolling) | Thêm Go SDK, hỗ trợ Jobs (manual) |

> ⚠️ **`version:` trong file YAML là obsolete.** Kể từ Compose v2 (2020), trường top-level `version` không còn có ý nghĩa chọn schema — Compose luôn dùng spec mới nhất. Nếu dùng, bạn sẽ nhận **warning**: `'version' is obsolete`. Khuyến nghị: **xóa hoàn toàn** dòng `version: "3.x"` khỏi file.

### Tên file khuyến nghị: `compose.yaml`

Compose ưu tiên `compose.yaml` (thay vì `docker-compose.yml` cũ):
- `compose.yaml` → ưu tiên cao nhất
- `compose.yml` → được chấp nhận
- `docker-compose.yaml` / `docker-compose.yml` → vẫn hoạt động (backward compatible)

Trong tutorial này ta dùng file **`compose.yaml`** — file thực tế của project đã được đổi tên từ `docker-compose.yml` sang `compose.yaml`.

### Docker Compose hoạt động như thế nào?

Docker Compose không chỉ đơn giản là "gộp" nhiều container lại — nó còn **tự động tạo một network riêng** để tất cả các services trong file `compose.yaml` có thể giao tiếp với nhau.

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

Ví dụ file `compose.yaml` cho kiến trúc 3-tier (Compose Specification, **không có** `version:`):

```yaml
# compose.yaml — Compose Specification (Docker Compose v2/v5)
# LƯU Ý: KHÔNG khai báo "version:" nữa — field này đã obsolete từ 2020.

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

`docker compose up` sẽ **chạy TOÀN BỘ group container** được định nghĩa trong file `compose.yaml` cùng lúc:

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

### File compose.yaml của project

File `compose.yaml` trong project được dùng để chạy Todo App + MySQL. So với version đơn giản phía trên, file thực tế thêm `name:` (tránh trùng tên project), `healthcheck` cho MySQL và `depends_on: condition: service_healthy` (app chỉ start khi MySQL sẵn sàng):

```yaml
# compose.yaml — Compose Specification (Docker Compose v2/v5)
# ⚠️ KHÔNG có "version: 2.x" hay "version: 3.x" — chỉ dùng Compose Specification

name: todo-app

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
    depends_on:
      mysql:
        condition: service_healthy

  mysql:
    image: mysql:8.0
    volumes:
      - todo-mysql-data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: todos
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "-u", "root", "--password=secret"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 30s

volumes:
  todo-mysql-data:
```

**Giải thích cấu trúc:**

| Phần | Ý nghĩa |
|------|----------|
| `name: todo-app` | Đặt tên project. Khi dùng Docker Compose, tất cả resource (network, volume, container) đều prefix bằng `todo-app`. Tránh trùng với app khác. |
| `depends_on.condition: service_healthy` | App chỉ start khi service `mysql` có healthcheck trả về **healthy** (không phải chờ `mysql` "bật lên" rồi crash ngay vì chưa sẵn sàng) |
| `healthcheck` | Kiểm tra MySQL bằng `mysqladmin ping` mỗi 5 giây, timeout 3s, thử 10 lần, chờ 30s khởi tạo trước khi đếm |

### Các lệnh Docker Compose (v2/v5)

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

# Chạy lệnh trong service
docker compose exec application sh

# Validate file compose.yaml (kiểm tra lỗi syntax)
docker compose config

# Xem cấu hình sau khi merge .env (compose v2.24+)
docker compose config --format json
```

### Compose Watch (tính năng mới — sync code real-time)

Kể từ Compose v2.22, bạn có thể dùng `develop.watch` thay cho bind mount thủ công:

```yaml
services:
  application:
    build: .
    develop:
      watch:
        - action: sync        # sync file thay đổi vào container
          path: ./src
          target: /app/src
        - action: rebuild     # rebuild khi package.json thay đổi
          path: ./package.json
```

```bash
# Chạy với watch mode (auto sync code, không cần restart)
docker compose watch
```

### So sánh: docker run vs docker compose

| docker run | docker compose |
|------------|----------------|
| Mỗi lệnh chạy 1 container | Chạy nhiều container cùng lúc |
| Phải nhớ nhiều flags | Định nghĩa 1 lần trong YAML |
| Khó tái sử dụng | Dễ tái sử dụng và share |
| Phù hợp chạy nhanh/test | Phù hợp multi-service apps |

---

## Part 8: Multi-stage Builds

> Vấn đề: Image production thường chứa cả build tools (yarn, gcc, dev dependencies...) không cần thiết → image to, chậm deploy, tăng bề mặt tấn công bảo mật. **Multi-stage builds** giải quyết bằng cách dùng nhiều `FROM` trong một Dockerfile.

### Nguyên lý

Mỗi `FROM` bắt đầu một **stage** mới. Bạn copy artifact từ stage build sang stage cuối — stage build bị bỏ lại, không vào image cuối.

```
┌─────────────────────┐         ┌──────────────────────┐
│  Stage 1: build     │         │  Stage 2: production │
│  node:22 (to)       │  COPY   │  node:22-alpine      │
│  - dev dependencies │ ──────▶ │  - node_modules      │
│  - build tools      │ --from= │  - source code       │
│  - source code      │  build  │  (~nhỏ hơn nhiều)    │
└─────────────────────┘         └──────────────────────┘
```

### Dockerfile multi-stage cho Todo App (Node.js)

```dockerfile
# syntax=docker/dockerfile:1

# ===== Stage 1: build =====
FROM node:22-alpine AS build
WORKDIR /app

# Copy file manifest trước để tận dụng build cache
COPY package*.json yarn.lock ./
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
```

**Kỹ thuật quan trọng:**

| Kỹ thuật | Ý nghĩa |
|----------|----------|
| `FROM <image> AS <tên>` | Đặt tên stage để `COPY --from=<tên>` dễ đọc, không bị lỗi khi đổi thứ tự |
| `COPY --from=build` | Copy artifact từ stage trước vào stage hiện tại |
| `USER node` | Chạy container bằng user non-root (không phải `root`) |
| `ENV NODE_ENV=production` | Chỉ cài production dependencies trong stage cuối |
| Copy `package*.json` **trước** source | Tận dụng build cache — chỉ `yarn install` lại khi dependencies đổi |

### Build với stage cụ thể

```bash
# Build đến stage cuối (production)
docker build -t todo-image:multi-stage .

# Chỉ build đến stage "build" (dùng để debug / chạy test)
docker build --target build -t todo-image:debug .

# Kiểm tra build config theo best practices (BuildKit checks)
docker build --check .
```

### Lợi ích của multi-stage builds

- 📉 **Giảm kích thước image**: không chứa build tools, cache, dev dependencies
- 🔒 **Giảm attack surface**: ít package → ít CVE tiềm ẩn
- 🔐 **Không leak secrets**: `ARG` trong stage build không xuất hiện ở image cuối (`docker history` không thấy)
- ⚡ **Build song song**: các stage độc lập chạy parallel với BuildKit
- 🧪 **Debug dễ dàng**: giữ nguyên stage `build`/`debug` riêng, không ảnh hưởng production

---

## Part 9: Docker Scout - Security Scanning

> **Docker Scout** phân tích image và tạo **SBOM** (Software Bill of Materials), đối chiếu với cơ sở dữ liệu CVE cập nhật liên tục để phát hiện lỗ hổng bảo mật. Tích hợp sẵn trong Docker Desktop 4.23+ và Docker Hub.

### Các lệnh Docker Scout cơ bản

```bash
# Tổng quan nhanh về vulnerability của image (dùng image build gần nhất nếu không chỉ định)
docker scout quickview todo-image:multi-stage
#   ✓ SBOM of image already cached, 187 packages indexed
#   Your image  todo-image:multi-stage  │  0C  2H  8M  1L
#   Base image  node:22-alpine          │  0C  0H  0M  0L

# Liệt kê chi tiết CVEs
docker scout cves todo-image:multi-stage

# Chỉ hiện CVE có thể fix được
docker scout cves --only-fixed todo-image:multi-stage

# Lọc theo mức độ nghiêm trọng
docker scout cves --only-severity critical,high todo-image:multi-stage

# Lọc CVE theo package cụ thể (ví dụ express)
docker scout cves --only-package express

# Xuất SBOM của image
docker scout sbom todo-image:multi-stage

# Gợi ý update base image để giảm CVE
docker scout recommendations todo-image:multi-stage

# So sánh 2 image (trước/sau khi fix)
docker scout compare todo-image:1.0 --to todo-image:2.0

# Thoát mã 2 nếu có vulnerability (dùng trong CI/CD)
docker scout cves --exit-code --only-severity critical,high todo-image:multi-stage
```

### Xuất báo cáo (CI/CD integration)

```bash
# Xuất SARIF (tích hợp GitHub Code Scanning / GitLab)
docker scout cves --format sarif --output report.sarif.json todo-image

# Xuất SBOM định dạng SPDX
docker scout sbom --format spdx todo-image > sbom.spdx.json
```

### Enroll organization với Docker Scout (phân tích repo remote)

```bash
# Đăng ký organization với Docker Scout
docker scout enroll <ORG_NAME>

# Bật Docker Scout cho repository trên Docker Hub
docker scout repo enable --org <ORG_NAME> <ORG_NAME>/docker-tutorial

# Push image → Scout tự phân tích, cập nhật real-time khi có CVE mới
docker push <your-username>/docker-tutorial:latest
```

> 💡 **Lưu ý:** Phân tích local bằng CLI/Docker Desktop không lưu data. Khi enable cho repository, Docker Scout lưu snapshot metadata và **tự động đánh giá lại** khi có CVE mới — không cần quét lại image.

---

## Part 10: CI/CD với GitHub Actions

> Tự động hóa: mỗi lần push code lên GitHub → build image → scan bảo mật → push lên registry. Tất cả chạy trong pipeline **GitHub Actions**, không cần làm thủ công.

### Workflow hoàn chỉnh

Tạo file `.github/workflows/docker.yml`:

```yaml
name: Docker Build & Scan

on:
  push:
    branches: [main]
    tags: ["v*"]
  pull_request:
    branches: [main]

env:
  REGISTRY: docker.io
  IMAGE_NAME: ${{ github.repository }}   # vd: nbhson/docker-tutorial

jobs:
  build-scan-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      # 1. Lấy source code
      - name: Checkout
        uses: actions/checkout@v4

      # 2. Setup Buildx (bắt buộc để dùng cache type=gha và build-push-action)
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      # 3. Đăng nhập Docker Hub (secrets cấu hình trong repo Settings → Secrets)
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      # 4. Build image (KHÔNG push ngay) + cache layer vào GitHub Actions cache
      - name: Build image
        uses: docker/build-push-action@v6
        with:
          context: .
          load: true
          tags: ${{ env.IMAGE_NAME }}:ci
          cache-from: type=gha          # 🔄 lấy cache từ các lần build trước
          cache-to: type=gha,mode=max   # 🔄 lưu cache (cả intermediate layers)

      # 5. Scan bảo mật — pipeline FAIL nếu có CVE critical/high
      - name: Scan image với Docker Scout
        run: |
          docker scout cves ${{ env.IMAGE_NAME }}:ci \
            --exit-code \
            --only-severity critical,high

      # 6. Push image (chỉ chạy khi push lên main hoặc tag)
      - name: Push image
        if: github.event_name == 'push'
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: |
            ${{ env.IMAGE_NAME }}:latest
            ${{ env.IMAGE_NAME }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Giải thích các điểm quan trọng

| Thành phần | Ý nghĩa |
|------------|---------|
| `docker/build-push-action@v6` | Action chính thức của Docker: build, tag, push image trong pipeline |
| `cache-from` / `cache-to: type=gha` | Dùng **GitHub Actions cache** làm build cache. Lần build sau tái sử dụng layers → nhanh hơn nhiều lần. `mode=max` cache cả intermediate layers, không chỉ layer cuối |
| `load: true` | Build vào Docker Engine của runner (thay vì push ngay), để bước Scout scan được |
| `docker scout cves --exit-code` | Thoát với mã lỗi ≠ 0 nếu tìm thấy CVE theo điều kiện → **pipeline fail**, không cho image lỗi qua cổng |
| `--only-severity critical,high` | Chỉ chặn CVE mức critical/high (cân bằng giữa an toàn và "pipeline đỏ vô reason") |
| `secrets.DOCKERHUB_TOKEN` | Dùng **Access Token** của Docker Hub, không bao giờ commit username/password. Cấu hình tại repo Settings → Secrets and variables → Actions |
| Tag `${{ github.sha }}` | Tag immutable theo commit hash — image production luôn trace được về đúng code đã build |

> 💡 **Chặn image lỗi nhưng không block cứng?** Ở giai đoạn đầu, có thể để bước Scout chỉ warning bằng cách thêm `continue-on-error: true`, sau đó turn thành fail cứng khi team đã quen xử lý CVE.

### Biến thể: push lên GitHub Container Registry (ghcr.io)

```yaml
      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}   # token tự sinh, không cần cấu hình

      # ... tags: ghcr.io/${{ github.repository }}:latest
```

### Best Practices cho Docker CI/CD

1. **Pin version của actions** — dùng `@v4` / `@v3` (major tag) hoặc commit SHA đầy đủ để chống supply-chain attack qua actions.
2. **Multi-platform build** — thêm `platforms: linux/amd64,linux/arm64` vào `build-push-action` khi cần chạy trên server ARM.
3. **Đừng cache với `--no-cache`** — nếu cần build "sạch", thay vì tắt cache toàn bộ, dùng `docker build --pull` để chỉ cập nhật base image.
4. **Scan sớm, scan mọi PR** — đặt bước Scout trước bước push để CVE bị chặn trước khi image vào registry.
5. **Xuất SARIF lên GitHub Code Scanning** — `docker scout cves --format sarif --output report.sarif.json` rồi dùng `github/codeql-action/upload-sarif` để thấy CVE ngay trong tab Security của repo.

---

## Best Practices tổng hợp

### 1. Dockerfile

1. **Dùng base image nhỏ và chính chủ** — ưu tiên Docker Official Images, Alpine variant khi có thể. Pin version cụ thể (`node:22-alpine` thay vì `node:latest`).
2. **Multi-stage builds** — tách stage build/runtime, chỉ ship những gì cần để chạy (xem Part 8).
3. **`.dockerignore`** — loại trừ `node_modules`, `.git`, `.env`, logs để build nhanh và tránh leak secret vào image.
4. **Chạy non-root user** — thêm `USER node` (hoặc user riêng) trong Dockerfile production stage.
5. **Tận dụng build cache** — sắp xếp `COPY package.json` + `RUN yarn install` **trước** `COPY . .` để tránh reinstall dependencies mỗi lần đổi code.
6. **Pin base image version** — tránh `latest` trong production; cân nhắc pin digest (`node:22-alpine@sha256:...`).
7. **Mỗi `RUN` một câu lệnh gộp** — ví dụ `apt-get update && apt-get install -y && rm -rf /var/lib/apt/lists/*`.
8. **Chạy build checks** — `docker build --check .` để lint Dockerfile theo quy tắc BuildKit (JSONArgsRecommended, SecretsUsedInArgOrEnv...).
9. **Rebuild image thường xuyên** — dùng `docker build --pull` để lấy base image mới nhất (vá security patch).
10. **Dùng `HEALTHCHECK`** — khai báo command kiểm tra tình trạng app (Compose v2+ hỗ trợ `healthcheck` trong YAML).

### 2. Docker Compose

1. **Không dùng `version:`** — field này obsolete; chỉ dùng Compose Specification.
2. **Tên file `compose.yaml`** — chuẩn mới, ưu tiên cao hơn `docker-compose.yml`.
3. **Đặt tên project** — dùng `name:` top-level (Compose v2.3.3+) thay vì `-p`:
   ```yaml
   name: todo-app
   services:
     # ...
   ```
4. **Dùng `healthcheck` + `depends_on` với condition** — chờ DB sẵn sàng trước khi start app.
5. **External secrets qua `.env`** — không hardcode password trong YAML; dùng biến môi trường và `.env` (đã `.gitignore`).

### 3. Bảo mật (Security)

1. **Scan image với Docker Scout** — `docker scout cves <image>` (xem Part 9).
2. **Không chạy container bằng `root`** — dùng `USER` instruction.
3. **Giới hạn quyền**: `--read-only`, `--cap-drop=ALL`, `--security-opt=no-new-privileges` khi phù hợp.
4. **Không đưa secrets vào `ARG`/`ENV`** — dùng Docker BuildKit secret mounts:
   ```bash
   docker build --secret id=npm,src=.npmrc .
   ```
5. **Cập nhật base image thường xuyên** — rebuild định kỳ với `docker build --pull`.

### 4. Dev Experience

1. **Bind mount / `docker compose watch`** cho dev; **named volume** cho production data.
2. **Sử dụng build cache hiệu quả** — sắp xếp Dockerfile theo tần suất thay đổi (ít đổi → trên cùng).
3. **Kiểm tra logs real-time** với `docker logs -f` hoặc `docker compose logs -f` để debug nhanh.

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
- [x] Sử dụng **Docker Compose v2/v5** với Compose Specification (không dùng `version:`)
- [x] Viết **Multi-stage builds** để tối ưu image
- [x] Scan bảo mật image với **Docker Scout**
- [x] Tự động hóa build + scan + push với **GitHub Actions CI/CD**
- [x] Áp dụng **best practices** (non-root, .dockerignore, build cache, build checks)

### Lệnh Docker Reference

```bash
# Images
docker build -t <name> .                    # Build image (dùng BuildKit mặc định)
docker build --pull .                       # Build + pull fresh base images
docker build --no-cache -t <name> .         # Build không dùng cache
docker build --check .                      # Lint Dockerfile (BuildKit build checks)
docker image ls                             # List images
docker image rm <image>                     # Remove image
docker image prune -a                       # Remove all unused images
docker history <image>                      # View image layers
docker scout quickview <image>              # Tổng quan bảo mật image

# Containers
docker run -dp <host>:<container> <image> # Run container
docker ps                                   # List running containers
docker ps -a                                # List all containers
docker stop <container>                     # Stop container
docker start <container>                    # Start container
docker rm <container>                       # Remove container
docker logs -f <container>                  # View logs
docker exec -it <container> sh              # Shell into container

# Docker Hub
docker login                                # Login to Docker Hub
docker login -u <username>                  # Login with username
docker logout                               # Logout from Docker Hub
docker search <keyword>                     # Search images on Docker Hub
docker pull <image>                         # Pull image from Docker Hub
docker push <image>                         # Push image to Docker Hub
docker push <image> --all-tags              # Push all tags of an image
docker tag <src-image> <dst-image>          # Tag an image

# Volumes
docker volume create <name>                 # Create volume
docker volume ls                            # List volumes
docker volume inspect <name>                # Inspect volume
docker volume rm <name>                    # Remove volume

# Docker Scout (security scanning)
docker scout cves <image>                  # Liệt kê CVE vulnerabilities
docker scout cves --only-fixed <image>     # Chỉ CVE có thể fix
docker scout cves --format sarif -o <file> # Xuất SARIF (CI/CD)
docker scout quickview <image>             # Tổng quan nhanh
docker scout sbom <image>                  # Generate SBOM
docker scout recommendations <image>       # Gợi ý update base image
docker scout compare <img1> --to <img2>    # So sánh 2 image

# Buildx (multi-platform builds)
docker buildx create --name mybuilder --use
docker buildx inspect --bootstrap
docker buildx build --platform linux/amd64,linux/arm64 -t <name> . --push

# Compose (Docker Compose v2/v5)
docker compose up -d                        # Start all services
docker compose down                         # Stop all services
docker compose ps                           # List services
docker compose logs -f                      # View logs
docker compose up -d --build                # Rebuild and restart
docker compose exec <service> sh            # Shell vào service
docker compose config                       # Validate + xem config đã merge
docker compose watch                        # Watch mode (auto sync code)
```

---

## Tài liệu tham khảo

### Official docs (Docker)

- [Docker Get Started](https://docs.docker.com/get-started/) — hướng dẫn chính thức
- [Docker Engine Release Notes](https://docs.docker.com/engine/release-notes/) — version 27.x / 28.x / 29.x
- [Dockerfile Reference](https://docs.docker.com/reference/dockerfile/)
- [Best practices for writing Dockerfiles](https://docs.docker.com/build/building/best-practices/)
- [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
- [Build checks (BuildKit linting)](https://docs.docker.com/reference/build-checks/)

### Docker Compose

- [Compose Specification (official)](https://compose-spec.github.io/compose-spec/spec.html)
- [Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Version and name top-level elements — `version` obsolete](https://docs.docker.com/reference/compose-file/version-and-name/)
- [Compose file history (v1 → v2 → v5)](https://docs.docker.com/compose/intro/history/)
- [Compose release notes](https://docs.docker.com/release-notes/docker-compose/)

### Docker Scout (security)

- [Docker Scout overview](https://docs.docker.com/scout/)
- [Docker Scout Quickstart](https://docs.docker.com/scout/quickstart/)
- [`docker scout` CLI reference](https://docs.docker.com/reference/cli/docker/scout/)

### CI/CD (GitHub Actions)

- [docker/build-push-action](https://github.com/docker/build-push-action) — action build & push chính thức
- [docker/login-action](https://github.com/docker/login-action) — đăng nhập Docker Hub / GHCR
- [GitHub Actions cache for Docker builds](https://docs.docker.com/build/ci/github-actions/cache/) — cache `type=gha`
- [Docker Scout in CI/CD](https://docs.docker.com/scout/integrations/ci/gha/) — tích hợp Scout vào GitHub Actions

### Khác

- [Docker Hub](https://hub.docker.com)
- [Play With Docker](https://labs.play-with-docker.com/)
- [Docker Engine Release Notes](https://docs.docker.com/engine/release-notes/)
- [OWASP Node.js Docker Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/NodeJS_Docker_Cheat_Sheet.html)