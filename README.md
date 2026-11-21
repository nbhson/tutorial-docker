# Docker Tutorial - Xây dựng Todo App với Docker

> Tutorial này dạy bạn dùng Docker từ con số 0 đến nâng cao. Cách học: tự tay xây một ứng dụng **Todo CRUD API** bằng Node.js, Express và MySQL. Học mà làm — làm xong là nhớ.

## 📌 Version sử dụng trong tutorial (cập nhật 10/2026)

| Thành phần | Version | Ghi chú |
|------------|---------|---------|
| **Docker Engine** | 27.x / 28.x / 29.x | Engine 28 (ra 02/2025, mới nhất `28.5.2`) và Engine 29 (ra 11/2025, mới nhất `29.9.2`). Engine 27.x đã hết hỗ trợ. |
| **Docker Compose** | v2.x / v5.x | Compose v2 (CLI `docker compose`, từ 2.40.x) và Compose v5 (ra 12/2025, mới nhất 5.6.1 tại thời điểm viết 10/2026) — cả hai đều dùng **Compose Specification**. |
| **Compose file format** | Compose Specification | Không còn dùng `version: "2.x"` hay `version: "3.x"` trong file YAML (đã **obsolete**). Tên file khuyến nghị: `compose.yaml`. |
| **BuildKit / Buildx** | BuildKit v0.25+ / Buildx v0.28+ | Build mặc định qua BuildKit, hỗ trợ multi-stage, cache mount, build checks. |

> **Cách đọc bảng này:** Cột "Thành phần" là công cụ, cột "Version" là phiên bản an toàn để dùng, cột "Ghi chú" giải thích thêm. Chỉ cần nhớ: cài Docker Desktop mới là đủ.

> ⚠️ **Quan trọng:** Nếu bạn vẫn đang dùng Docker Compose v1 (`docker-compose` viết thường, Python-based) thì đã **EOL từ 06/2023**. Hãy nâng cấp lên Docker Desktop (Compose v2/v5 tích hợp sẵn) hoặc Docker Engine 28+.

> **Tóm gọn 1 câu:** Dùng Docker Desktop bản mới nhất là có đủ mọi thứ; Compose v1 đã "nghỉ hưu", đừng dùng nữa.

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

Docker giống như một chiếc "hộp chở hàng" cho ứng dụng. Bạn nhét app kèm toàn bộ đồ đạc nó cần (runtime, thư viện, config) vào một đơn vị gọi là **container**. Chiếc hộp này chạy được trên bất kỳ máy nào có cài Docker — máy dev, máy staging hay server production đều cho ra kết quả y hệt nhau. Hết cảnh "máy tôi chạy được mà máy anh không chạy".

### Tại sao phải dùng Docker?

Mục này giải thích lý do bạn cần Docker. Không có Docker, việc setup và deploy rất đau đầu: phải cài runtime, database, chỉnh config từng máy, chưa kể mỗi hệ điều hành một kiểu. Docker gói gọn mọi thứ lại, nên bạn chỉ cần "xé hộp" là chạy. Lợi ích cụ thể:

- **Đồng nhất môi trường**: Dev, staging, production đều giống nhau
- **Tách biệt dịch vụ**: Mỗi container đảm nhận một nhiệm vụ (app, database, cache...)
- **Dễ dàng triển khai**: Chỉ cần chạy `docker run` là ứng dụng khởi chạy
- **Bảo mật mã nguồn**: Lưu ý quan trọng — **image KHÔNG phải là hộp đen**. Bất kỳ ai có image đều có thể trích xuất được source code bên trong bằng `docker history <image>` (xem từng layer) hoặc `docker save` + export từng layer. Vì vậy:
  - **Không bao giờ** nhúng secret (API key, password, private key) vào image qua `COPY`, `ENV` hay `ARG` — ngay cả khi bạn xóa file ở layer sau, file vẫn còn trong layer trước
  - Secret nên truyền lúc runtime qua biến môi trường, Docker secrets, hoặc secret manager
  - Dùng `.dockerignore` để loại trừ `.env`, credential files khỏi build context (xem Part 1)

> **Tóm gọn 1 câu:** Docker đóng gói app thành "hộp" chạy được ở mọi nơi — nhưng nhớ rằng image không phải hộp đen, ai cũng đọc được code bên trong nên đừng giấu secret trong đó.

### Các khái niệm chính

| Khái niệm | Mô tả |
|-----------|-------|
| **Docker Image** | Bản snapshot của môi trường phát triển (OS + dependencies + source code). Được tạo từ Dockerfile. |
| **Dockerfile** | File chứa các câu lệnh để tự động build Docker image. |
| **Docker Container** | Instance đang chạy của một Docker Image. |
| **Docker Hub** | Kho lưu trữ trực tuyến các Docker image (tương tự GitHub nhưng cho image). |
| **Docker Compose** | Công cụ định nghĩa và chạy multi-container applications. |

> **Cách đọc bảng này:** Mỗi dòng là một khái niệm sẽ gặp suốt tutorial. Đọc theo thứ tự từ trên xuống: image là "bản thiết kế", Dockerfile là "công thức tạo bản thiết kế", container là "ngôi nhà dựng từ bản thiết kế".

> **Tóm gọn 1 câu:** Nhớ bộ tứ: Dockerfile (công thức) → Image (bản đóng gói) → Container (bản đang chạy) → Docker Hub (kho chia sẻ).

---

## 2. Các khái niệm cơ bản

### Yêu cầu

Trước khi bắt đầu, bạn cần hai thứ sau:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) đã cài đặt trên máy tính
- Docker Hub account (miễn phí): https://hub.docker.com

> **Tóm gọn 1 câu:** Cài Docker Desktop và tạo account Docker Hub miễn phí — chỉ thế là đủ để học hết tutorial.

### Kiểm tra cài đặt

> 📄 **Code ví dụ:** [`examples/01-kiem-tra-cai-at.sh`](examples/01-kiem-tra-cai-at.sh)

### Ứng dụng Demo

Đây là ứng dụng ta sẽ xây dựng: một Todo API — bạn có thể xem, thêm, sửa, xóa công việc. Nó có 4 endpoint:

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| `GET` | `/items` | Lấy danh sách todos |
| `POST` | `/items` | Thêm todo mới |
| `PUT` | `/items/:id` | Cập nhật todo |
| `DELETE` | `/items/:id` | Xóa todo |

> **Cách đọc bảng này:** Cột "Method" là kiểu hành động (GET = đọc, POST = thêm, PUT = sửa, DELETE = xóa), cột "Endpoint" là địa chỉ gọi API.

> **Tóm gọn 1 câu:** Demo là một Todo API đầy đủ CRUD: xem, thêm, sửa, xóa công việc qua 4 endpoint.

---

## Part 1: Viết Dockerfile & Build Image

### Bước 1: Clone repository

> 📄 **Code ví dụ:** [`examples/02-buoc-1-clone-repository.sh`](examples/02-buoc-1-clone-repository.sh)

### Bước 2: Tìm hiểu Dockerfile

Mục này giúp bạn đọc hiểu Dockerfile trước khi tự viết. Hãy coi Dockerfile như "công thức nấu ăn": ghi rõ từng bước, Docker làm theo để "nấu" ra image. Xem file `Dockerfile` trong project:

> 📄 **Code ví dụ:** [`examples/03-buoc-2-tim-hieu-dockerfile.dockerfile`](examples/03-buoc-2-tim-hieu-dockerfile.dockerfile)

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

> **Cách đọc bảng này:** Mỗi dòng là một instruction (từ khóa) trong Dockerfile. Đọc từ trên xuống sẽ đúng thứ tự xuất hiện trong file: chọn gốc (`FROM`) → chọn chỗ làm việc (`WORKDIR`) → chép đồ vào (`COPY`) → chạy lệnh (`RUN`) → khai báo port (`EXPOSE`) → hẹn lệnh khởi động (`CMD`).

> **Tóm gọn 1 câu:** Dockerfile là công thức nấu image: `FROM` chọn nền, `COPY` chép code, `RUN` cài đồ, `CMD` hẹn lệnh khởi động.

### Bước 3: Build image

> 📄 **Code ví dụ:** [`examples/04-buoc-3-build-image.sh`](examples/04-buoc-3-build-image.sh)

- `-t todo-image`: Đặt tên cho image
- `.`: Chỉ định Dockerfile ở thư mục hiện tại

> **Tóm gọn 1 câu:** Lệnh `docker build -t todo-image .` đọc công thức ở thư mục hiện tại và đóng gói thành image tên `todo-image`.

### Bước 4: Chạy container lần đầu

> 📄 **Code ví dụ:** [`examples/05-buoc-4-chay-container-lan-au.sh`](examples/05-buoc-4-chay-container-lan-au.sh)

- `-d`: Chạy ở chế độ background (detached)
- `-p 3000:3000`: Map port 3000 trên host với port 3000 trong container

Mở trình duyệt truy cập `http://localhost:3000` để thấy ứng dụng Todo đang chạy.

> **Tóm gọn 1 câu:** `docker run -dp 3000:3000 todo-image` khởi động app ở background, mở `localhost:3000` là thấy thành quả.

---

## Part 2: Quản lý Container

### Các lệnh cơ bản

> 📄 **Code ví dụ:** [`examples/06-cac-lenh-co-ban.sh`](examples/06-cac-lenh-co-ban.sh)

### Start / Stop / Xóa container

> 📄 **Code ví dụ:** [`examples/07-start-stop-xoa-container.sh`](examples/07-start-stop-xoa-container.sh)

> 💡 **Mẹo:** Bạn có thể dùng tên image hoặc container name thay vì ID. Khi tạo container bằng `docker run`, có thể thêm `--name` để đặt tên:
> ```bash
> docker run -dp 3000:3000 --name todo-app todo-image
> ```

> **Tóm gọn 1 câu:** Đặt `--name` ngay từ đầu để sau này start/stop/xóa theo tên dễ nhớ, khỏi phải tra ID.

### Cập nhật ứng dụng (Rebuild container)

Khi thay đổi source code, bạn cần rebuild image và tạo container mới:

> 📄 **Code ví dụ:** [`examples/08-cap-nhat-ung-dung-rebuild-container.sh`](examples/08-cap-nhat-ung-dung-rebuild-container.sh)

> 🔍 Kiểm tra log của container:
> ```bash
> docker logs <container-id>
> docker logs -f <container-id>  # Theo dõi log real-time
> ```

> **Tóm gọn 1 câu:** Đổi code = rebuild image + chạy container mới; log thì xem bằng `docker logs -f` để soi lỗi ngay.

---

## Part 3: Thao tác với Docker Hub

> **Docker Hub** là kho lưu trữ image trực tuyến, nơi bạn có thể chia sẻ và tải về các Docker image. Tương tự như GitHub nhưng dành cho Docker image. Phần này dạy bạn cách đẩy image của mình lên đó và kéo image của người khác về chạy.

### Bước 1: Đăng nhập / Đăng xuất Docker Hub

> 📄 **Code ví dụ:** [`examples/09-buoc-1-ang-nhap-ang-xuat-docker-hub.sh`](examples/09-buoc-1-ang-nhap-ang-xuat-docker-hub.sh)

> 💡 **Lưu ý:** Docker Desktop có thể tự duy trì session đăng nhập. Dùng `docker logout` để xóa thông tin đăng nhập trên máy.

### Bước 2: Tạo & Tag Image

> 📄 **Code ví dụ:** [`examples/10-buoc-2-tao-tag-image.sh`](examples/10-buoc-2-tao-tag-image.sh)

**Quy tắc đặt tên image cho Docker Hub:**

| Format | Ý nghĩa |
|--------|----------|
| `<username>/<repo>` | Image trong account cá nhân |
| `<org>/<repo>` | Image thuộc organization |
| `library/<repo>` | Image chính thức (official image) |
| `<username>/<repo>:<tag>` | Version cụ thể |
| `<username>/<repo>:latest` | Tag mặc định (latest) |

> **Cách đọc bảng này:** Cột "Format" là cách viết tên image, cột "Ý nghĩa" cho biết nó trỏ tới đâu. Tên luôn có dạng `ai-đó/tên-repo`, thêm `:tag` nếu muốn chỉ định version.

> **Tóm gọn 1 câu:** Tên image trên Hub luôn là `<username>/<repo>`, thêm `:tag` nếu muốn đóng dấu version.

### Bước 3: Push Image lên Docker Hub

> 📄 **Code ví dụ:** [`examples/11-buoc-3-push-image-len-docker-hub.sh`](examples/11-buoc-3-push-image-len-docker-hub.sh)

### Bước 4: Pull Image từ Docker Hub

> 📄 **Code ví dụ:** [`examples/12-buoc-4-pull-image-tu-docker-hub.sh`](examples/12-buoc-4-pull-image-tu-docker-hub.sh)

### Bước 5: Chạy image từ Docker Hub

Bất kỳ ai cũng có thể chạy image của bạn:

> 📄 **Code ví dụ:** [`examples/13-buoc-5-chay-image-tu-docker-hub.sh`](examples/13-buoc-5-chay-image-tu-docker-hub.sh)

> 💡 Thử tại https://labs.play-with-docker.com/ - mở port 3000 và chạy lệnh trên!

### Tìm kiếm Image trên Docker Hub

> 📄 **Code ví dụ:** [`examples/14-tim-kiem-image-tren-docker-hub.sh`](examples/14-tim-kiem-image-tren-docker-hub.sh)

### Quản lý Remote Image

> 📄 **Code ví dụ:** [`examples/15-quan-ly-remote-image.sh`](examples/15-quan-ly-remote-image.sh)

### Xem thông tin về repository

> 📄 **Code ví dụ:** [`examples/16-xem-thong-tin-ve-repository.sh`](examples/16-xem-thong-tin-ve-repository.sh)

### Multi-Architecture Build (Multi-Platform)

> 📄 **Code ví dụ:** [`examples/17-multi-architecture-build-multi-platform.sh`](examples/17-multi-architecture-build-multi-platform.sh)

### Docker Hub API (thông qua CLI)

> 📄 **Code ví dụ:** [`examples/18-docker-hub-api-thong-qua-cli.sh`](examples/18-docker-hub-api-thong-qua-cli.sh)

### Best Practices khi sử dụng Docker Hub

1. **Luôn sử dụng tag cụ thể** — Tránh dùng `latest` trong production vì nó có thể thay đổi bất ngờ.
2. **Viết README tốt** — Docker Hub hỗ trợ Markdown README cho mỗi repository.
3. **Sử dụng Access Token** — Thay vì password, tạo Access Token trong Docker Hub Settings > Security.
4. **Kiểm tra vulnerability** — Docker Hub có tích hợp Docker Scout để scan vulnerabilities.
5. **Automated Build** — Kết nối repository GitHub/GitLab để tự động build image khi có commit mới.

> **Tóm gọn 1 câu:** Dùng tag cụ thể thay vì `latest`, đăng nhập bằng Access Token, và quét vulnerability trước khi share image.

---

## Part 4: Persist Data - Volumes

> ⚠️ **Vấn đề:** Khi xóa container, toàn bộ data bên trong sẽ mất. Làm thế nào để giữ lại data?

### Sử dụng Named Volumes

**Volume** là vùng nhớ lưu trữ bên ngoài container, được quản lý bởi Docker. Hãy tưởng tượng như két sắt riêng ở ngoài phòng thuê: bạn đổi phòng (xóa container) thì đồ trong két vẫn còn nguyên.

> 📄 **Code ví dụ:** [`examples/19-su-dung-named-volumes.sh`](examples/19-su-dung-named-volumes.sh)

> 💡 Bây giờ dù bạn có xóa container và tạo lại, data vẫn được giữ nguyên vì nó nằm trong volume.

> **Tóm gọn 1 câu:** Named volume là két sắt ngoài container — container chết bao nhiêu lần data vẫn sống.

### Quản lý Volume

> 📄 **Code ví dụ:** [`examples/20-quan-ly-volume.sh`](examples/20-quan-ly-volume.sh)

> ⚠️ **Cẩn thận với `prune`:** `docker volume prune` chỉ xóa volume **anonymous** và volume không được container nào tham chiếu. Nhưng nếu bạn quên gắn volume vào container trong lần chạy sau, data vẫn tồn tại — đến khi bạn chạy `prune -a` thì mất hẳn. Trước khi prune, luôn kiểm tra lại bằng `docker volume ls`.

> **Tóm gọn 1 câu:** `prune` là cây chổi quét sạch volume "mồ côi" — luôn chạy `docker volume ls` để soát trước khi quét.

### Anonymous Volumes vs Named Volumes

Mục này so sánh hai loại volume để bạn biết khi nào dùng loại nào. Có **2 loại volume**:

| | Anonymous Volume | Named Volume |
|---|---|---|
| Cách tạo | `-v /var/lib/mysql` (chỉ path trong container) | `-v todo-mysql-data:/var/lib/mysql` hoặc `docker volume create` |
| Tên | Hash ngẫu nhiên, ví dụ `d7f1a...` | Tên bạn đặt, dễ đọc |
| Tái sử dụng | Khó — phải tra hash bằng `docker volume ls` | Dễ — tham chiếu theo tên |
| Dọn dẹp | Tự xóa khi dùng `--rm` với container | Phải xóa thủ công / bằng `prune` |
| Khi nào dùng | Container tạm, cache build (ví dụ `/app/node_modules`) | Dữ liệu cần giữ lâu dài (database, uploads) |

> **Cách đọc bảng này:** Soi theo cột "Khi nào dùng" là quyết định nhanh nhất: dữ liệu tạm thì anonymous, dữ liệu cần giữ thì named.

> **Tóm gọn 1 câu:** Anonymous volume cho đồ tạm (cache), named volume cho đồ quý (database) — tên dễ đọc nên dễ quản.

> 📄 **Code ví dụ:** [`examples/21-anonymous-volumes-vs-named-volumes.sh`](examples/21-anonymous-volumes-vs-named-volumes.sh)

> 📄 **Code ví dụ:** [`examples/22-anonymous-volumes-vs-named-volumes.sh`](examples/22-anonymous-volumes-vs-named-volumes.sh)

> 💡 **Mẹo:** Trong Dockerfile, mỗi `VOLUME /path` khai báo cũng tạo anonymous volume mỗi lần chạy container. Vì vậy nên khai báo volume ở tầng `compose.yaml` hoặc `docker run`, ít khai báo trong Dockerfile.

### Backup & Restore Volume với tar

Volume không nằm trong container nên xóa container không mất data — nhưng **xóa volume thì mất thật**. Backup bằng cách mount cả volume lẫn thư mục backup vào một container tạm rồi đóng gói tar:

**Backup:**

> 📄 **Code ví dụ:** [`examples/23-backup-restore-volume-voi-tar.sh`](examples/23-backup-restore-volume-voi-tar.sh)

**Restore:**

> 📄 **Code ví dụ:** [`examples/24-backup-restore-volume-voi-tar.sh`](examples/24-backup-restore-volume-voi-tar.sh)

**Giải thích:**

| Phần | Ý nghĩa |
|------|----------|
| `--rm` | Container tạm tự xóa sau khi chạy xong |
| `-v todo-mysql-data:/data:ro` | Mount volume cần backup, chỉ đọc (`:ro`) để an toàn |
| `-v "$(pwd)":/backup` | Map thư mục host để lưu file tar |
| `tar czf ... -C /data .` | Nén toàn bộ nội dung volume vào file tar |

> **Cách đọc bảng này:** Mỗi dòng giải thích một mảnh trong lệnh backup. Hiểu nôm na: container tạm "cầm" volume ở tay này (`/data`, chỉ đọc) và túi đựng file tar ở tay kia (`/backup`).

> 💡 Với MySQL, cách backup "đúng chuẩn" hơn là dùng `mysqldump` trong container để xuất file `.sql`:
> ```bash
> docker exec <mysql-container-id> \
>   mysqldump -u root -psecret todos > todos-backup.sql
> ```
> Cách tar volume phù hợp backup "nguyên trạng" mọi loại data (không chỉ database).

> **Tóm gọn 1 câu:** Backup = cho container tạm đọc volume và nén ra file tar trên host; restore làm ngược lại.

---

## Part 5: Dev Mode - Bind Mounts

> Khi developing, bạn không muốn phải rebuild image mỗi lần thay đổi code. **Bind Mount** cho phép map thư mục source code từ host vào container. Nôm na: thay vì photocopier code vào hộp container, bạn mở một "cửa sổ" thông giữa hai nhà — sửa file bên nhà host, bên container thấy ngay.

### Chạy với Bind Mount

> 📄 **Code ví dụ:** [`examples/25-chay-voi-bind-mount.sh`](examples/25-chay-voi-bind-mount.sh)

**Giải thích:**

| Flag | Ý nghĩa |
|------|----------|
| `-w /app` | Đặt working directory trong container |
| `-v "$(pwd):/app"` | Map thư mục hiện tại host vào `/app` trong container |
| `sh -c "yarn install && yarn run dev"` | Cài dependencies và chạy dev server |

> **Cách đọc bảng này:** Mỗi dòng là một flag trong lệnh `docker run`. Ba mảnh ghép lại: chọn chỗ làm việc (`-w`), nối thư mục code (`-v`), rồi ra lệnh chạy (`sh -c`).

> 💡 Với bind mount, mỗi khi bạn edit code trên host, container sẽ tự động update (qua nodemon). Chỉ cần refresh trình duyệt!

> **Tóm gọn 1 câu:** Bind mount nối thư mục code host vào container, nên sửa code là app tự cập nhật, khỏi rebuild.

### Bind Mount flags: `:ro`, `:rw`, `:z`, `:Z`

Bạn có thể thêm **options** vào cuối bind mount (sau dấu `:` thứ hai), cách nhau bằng dấu phẩy:

> 📄 **Code ví dụ:** [`examples/26-bind-mount-flags-ro-rw-z-z.sh`](examples/26-bind-mount-flags-ro-rw-z-z.sh)

**SELinux labels (dành cho Fedora/RHEL/CentOS — host có SELinux enforcing):**

| Flag | Ý nghĩa |
|------|---------|
| `:z` | Gắn label SELinux **shared**: nhiều container có thể mount cùng nội dung này |
| `:Z` | Gắn label SELinux **private**: CHỈ container hiện tại được dùng nội dung này |

> **Cách đọc bảng này:** Chỉ cần phân biệt `z` (chia sẻ cho nhiều container) và `Z` (độc quyền cho một container). Hai flag còn lại (`:ro`, `:rw`) là chuyện đọc hay ghi, khác hẳn chuyện SELinux.

> 📄 **Code ví dụ:** [`examples/27-bind-mount-flags-ro-rw-z-z.sh`](examples/27-bind-mount-flags-ro-rw-z-z.sh)

> 💡 Trên macOS và hầu hết môi trường dev (Ubuntu không bật SELinux enforcing) bạn không cần `:z`/`:Z`. Nhưng nếu tutorial/CI của bạn chạy trên Fedora, RHEL, CentOS — nhớ thêm flag này, lỗi `Permission denied` khi bind mount gần như luôn do SELinux.
>
> ⚠️ `:Z` re-label toàn bộ thư mục host — đừng dùng với thư mục hệ thống như `$HOME`.

> **Tóm gọn 1 câu:** Thêm `:ro` để chỉ đọc, `:z`/`:Z` chỉ cần khi host dùng SELinux (Fedora/RHEL/CentOS).

### Các dạng đường dẫn của bind mount

> 📄 **Code ví dụ:** [`examples/28-cac-dang-uong-dan-cua-bind-mount.sh`](examples/28-cac-dang-uong-dan-cua-bind-mount.sh)

### Lỗi phổ biến với bind mount + Node.js

Khi bind mount `./:/app`, thư mục `node_modules` trên host (rỗng hoặc thiếu) sẽ **che** mất `node_modules` trong container. Cách xử lý kinh điển — dùng anonymous volume "chặn" riêng:

> 📄 **Code ví dụ:** [`examples/29-loi-pho-bien-voi-bind-mount-node-js.sh`](examples/29-loi-pho-bien-voi-bind-mount-node-js.sh)

Volume thứ hai (anonymous) giữ `node_modules` của container, không bị bind mount từ host đè lên. Xóa container kèm `--rm` sẽ dọn anonymous volume này.

| So sánh | Named Volume | Bind Mount |
|---------|--------------|------------|
| Vị trí lưu | Do Docker quản lý (trong Docker Desktop VM) | Bất kỳ đâu trên host |
| Ai tạo nội dung | Container / Docker | Bạn (source code, config) |
| Tính di động | Cao — không phụ thuộc cấu trúc thư mục host | Thấp — phụ thuộc đường dẫn host |
| Hiệu năng (macOS/Windows) | Tốt hơn với nhiều file nhỏ | Chậm hơn, trừ khi dùng `compose watch` sync |
| Khi nào dùng | Dữ liệu production (database), chia sẻ giữa container | Dev mode (live-reload code), mount config |
| Backup | Phải tar/export (xem Part 4) | Trực tiếp trên host |

> **Cách đọc bảng này:** Chạy thẳng tới hai dòng cuối — "Khi nào dùng" và "Backup" — để chọn nhanh: dữ liệu production dùng named volume, code dev dùng bind mount.

> **Cách đọc bảng này:** Soi dòng "Khi nào dùng" để ra quyết định: volume cho data production, bind mount cho code khi dev. Các dòng còn lại giải thích lý do.

> **Tóm gọn 1 câu:** Named volume cho data production, bind mount cho code dev; gặp lỗi `node_modules` thì dùng anonymous volume chặn riêng.

### Xem log real-time

> 📄 **Code ví dụ:** [`examples/30-xem-log-real-time.sh`](examples/30-xem-log-real-time.sh)

---

## Part 6: Multi-container - Networking

> Một ứng dụng thực tế thường có nhiều services: App Server + Database + Cache. Mỗi service nên chạy trong một container riêng. Phần này dạy bạn nối các container đó lại với nhau qua **network** — giống như cấp chung một mạng wifi cho các thiết bị trong nhà để chúng gọi nhau được.

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

> 📄 **Code ví dụ:** [`examples/31-buoc-1-tao-network.sh`](examples/31-buoc-1-tao-network.sh)

### Bước 2: Chạy MySQL container trên network

> 📄 **Code ví dụ:** [`examples/32-buoc-2-chay-mysql-container-tren-network.sh`](examples/32-buoc-2-chay-mysql-container-tren-network.sh)

**Giải thích:**

| Flag | Ý nghĩa |
|------|----------|
| `--network todo-network` | Kết nối container vào network đã tạo |
| `--network-alias mysql` | Đặt alias để các container khác có thể gọi là "mysql" |
| `-v todo-mysql-data:/var/lib/mysql` | Mount volume để persist data MySQL |
| `-e MYSQL_ROOT_PASSWORD=secret` | Đặt root password cho MySQL |
| `-e MYSQL_DATABASE=todos` | Tự tạo database "todos" khi start |

> **Cách đọc bảng này:** Mỗi dòng là một flag của lệnh `docker run` cho MySQL. Quan trọng nhất: `--network` (nhập mạng chung) và `--network-alias` (đặt tên để gọi).

### Bước 3: Verify MySQL

> 📄 **Code ví dụ:** [`examples/33-buoc-3-verify-mysql.sh`](examples/33-buoc-3-verify-mysql.sh)

> 📄 **Code ví dụ:** [`examples/34-buoc-3-verify-mysql.sql`](examples/34-buoc-3-verify-mysql.sql)

### Bước 4: Chạy App kết nối với MySQL

> 📄 **Code ví dụ:** [`examples/35-buoc-4-chay-app-ket-noi-voi-mysql.sh`](examples/35-buoc-4-chay-app-ket-noi-voi-mysql.sh)

> 💡 **Lưu ý:** `MYSQL_HOST=mysql` dùng alias thay vì IP. Docker DNS sẽ tự động resolve tên `mysql` sang IP của MySQL container.

### Bước 5 (Tùy chọn): Kiểm tra DNS trong network

> 📄 **Code ví dụ:** [`examples/36-buoc-5-tuy-chon-kiem-tra-dns-trong.sh`](examples/36-buoc-5-tuy-chon-kiem-tra-dns-trong.sh)

> **Tóm gọn 1 câu:** Tạo network chung, chạy MySQL và app vào cùng mạng đó; app gọi MySQL bằng tên alias, Docker DNS lo phần tìm IP.

---

## Part 7: Docker Compose (Compose Specification)

> Quản lý nhiều container bằng lệnh `docker run` riêng lẻ rất rườm rà. **Docker Compose** cho phép định nghĩa toàn bộ multi-container application trong một file YAML. Hãy tưởng tượng: thay vì chạy từng lệnh một cho mỗi container, bạn viết cả "kịch bản dàn diễn" vào một file rồi ra một lệnh duy nhất là cả nhóm lên sân khấu.

### Docker Compose v2/v5 — Điểm gì đã thay đổi?

Docker Compose có ba giai đoạn:

| Thời kỳ | CLI | File format | Ghi chú |
|---------|-----|------------|---------|
| **Compose v1** (2014–2020) | `docker-compose` (Python) | `version: 2.x`, `version: 3.x` | Đã **EOL 06/2023** |
| **Compose v2** (2020–2025) | `docker compose` (Go) | **Compose Specification** (rolling) | `version:` field **obsolete/warning** |
| **Compose v5** (12/2025–nay) | `docker compose` (Go + SDK) | **Compose Specification** (rolling) | Thêm Go SDK, hỗ trợ Jobs (manual) |

> **Cách đọc bảng này:** Ba dòng là ba thời kỳ của Compose. Chỉ cần nhớ: dòng v1 là quá khứ cần bỏ, hai dòng còn lại dùng chung chuẩn Compose Specification hiện tại.

> ⚠️ **`version:` trong file YAML là obsolete.** Kể từ Compose v2 (2020), trường top-level `version` không còn có ý nghĩa chọn schema — Compose luôn dùng spec mới nhất. Nếu dùng, bạn sẽ nhận **warning**: `'version' is obsolete`. Khuyến nghị: **xóa hoàn toàn** dòng `version: "3.x"` khỏi file.

> **Tóm gọn 1 câu:** Compose v1 đã chết, v2/v5 dùng chuẩn mới — và hãy xóa dòng `version:` khỏi file YAML vì nó chỉ gây warning.

### Tên file khuyến nghị: `compose.yaml`

Compose ưu tiên `compose.yaml` (thay vì `docker-compose.yml` cũ):
- `compose.yaml` → ưu tiên cao nhất
- `compose.yml` → được chấp nhận
- `docker-compose.yaml` / `docker-compose.yml` → vẫn hoạt động (backward compatible)

Trong tutorial này ta dùng file **`compose.yaml`** — file thực tế của project đã được đổi tên từ `docker-compose.yml` sang `compose.yaml`.

### Docker Compose hoạt động như thế nào?

Mục này giải thích "phép màu" đằng sau Compose. Docker Compose không chỉ đơn giản là "gộp" nhiều container lại — nó còn **tự động tạo một network riêng** để tất cả các services trong file `compose.yaml` có thể giao tiếp với nhau.

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

> 📄 **Code ví dụ:** [`examples/37-docker-compose-hoat-ong-nhu-the-nao.yaml`](examples/37-docker-compose-hoat-ong-nhu-the-nao.yaml)

> 💡 **Điểm quan trọng:** Trong Docker Compose, mỗi service có thể gọi nhau bằng **tên service** (ví dụ: `DB_HOST: database`). Compose tự động tạo DNS record cho mỗi service trong network. Bạn **không cần tạo network thủ công** bằng `docker network create` nữa!

> **Tóm gọn 1 câu:** Compose tự lập network và sổ địa chỉ (DNS) cho các service — chúng gọi nhau bằng tên, bạn khỏi cần tạo network tay.

### `docker compose up` chạy gì?

`docker compose up` sẽ **chạy TOÀN BỘ group container** được định nghĩa trong file `compose.yaml` cùng lúc:

> 📄 **Code ví dụ:** [`examples/38-docker-compose-up-chay-gi.sh`](examples/38-docker-compose-up-chay-gi.sh)

Khi chạy `docker compose up`, Docker sẽ:

1. **Kiểm tra image** — Nếu image chưa có, tự build hoặc pull từ Docker Hub
2. **Tạo network** — Tự động tạo network riêng cho group services (nếu chưa có)
3. **Tạo volumes** — Khai báo các named volumes
4. **Khởi chạy tất cả containers** — Theo thứ tự phụ thuộc (DB chạy trước BE, BE chạy trước FE...)
5. **Kết nối vào network** — Tất cả containers đều có thể gọi nhau qua tên service

> **Tóm gọn 1 câu:** `docker compose up` là "một lệnh ra tất cả": tự build/pull image, lập network, tạo volume, rồi khởi động đủ cả nhóm container.

> 📄 **Code ví dụ:** [`examples/39-docker-compose-up-chay-gi.sh`](examples/39-docker-compose-up-chay-gi.sh)

### So sánh: Tự quản lý vs Docker Compose

**Cách truyền thống (không dùng Compose):**

> 📄 **Code ví dụ:** [`examples/40-so-sanh-tu-quan-ly-vs-docker-compose.sh`](examples/40-so-sanh-tu-quan-ly-vs-docker-compose.sh)

**Cách dùng Docker Compose:**

> 📄 **Code ví dụ:** [`examples/41-so-sanh-tu-quan-ly-vs-docker-compose.sh`](examples/41-so-sanh-tu-quan-ly-vs-docker-compose.sh)

| Tiêu chí | docker run truyền thống | Docker Compose |
|----------|------------------------|----------------|
| Số lệnh | Nhiều lệnh riêng lẻ | 1 lệnh `docker compose up` |
| Network | Phải tạo thủ công | Tự động tạo |
| Khởi động | Mỗi container 1 lệnh | Chạy tất cả cùng lúc |
| Stops | Mỗi container 1 lệnh | `docker compose down` là xong |
| Dependency | Phải tự thứ tự | Tự sắp xếp theo logic |
| Cấu hình | Phải nhớ tất cả flags | Định nghĩa 1 lần trong YAML |
| Reusability | Khó share | File YAML dễ share + version control |

> **Cách đọc bảng này:** Soi từng dòng để thấy Compose thắng ở mọi tiêu chí: ít lệnh hơn, tự tạo network, tự sắp thứ tự, và file YAML dễ chia sẻ.

> **Tóm gọn 1 câu:** Compose thay một đống lệnh `docker run` bằng một file YAML và một lệnh `up` — dễ nhớ, dễ share, dễ lặp lại.

### File compose.yaml của project

File `compose.yaml` trong project được dùng để chạy Todo App + MySQL. So với version đơn giản phía trên, file thực tế thêm `name:` (tránh trùng tên project), `healthcheck` cho MySQL và `depends_on: condition: service_healthy` (app chỉ start khi MySQL sẵn sàng):

> 📄 **Code ví dụ:** [`examples/42-file-compose-yaml-cua-project.yaml`](examples/42-file-compose-yaml-cua-project.yaml)

**Giải thích cấu trúc:**

| Phần | Ý nghĩa |
|------|----------|
| `name: todo-app` | Đặt tên project. Khi dùng Docker Compose, tất cả resource (network, volume, container) đều prefix bằng `todo-app`. Tránh trùng với app khác. |
| `depends_on.condition: service_healthy` | App chỉ start khi service `mysql` có healthcheck trả về **healthy** (không phải chờ `mysql` "bật lên" rồi crash ngay vì chưa sẵn sàng) |
| `healthcheck` | Kiểm tra MySQL bằng `mysqladmin ping` mỗi 5 giây, timeout 3s, thử 10 lần, chờ 30s khởi tạo trước khi đếm |

> **Cách đọc bảng này:** Ba dòng là ba nâng cấp so với file ví dụ đơn giản phía trên: đặt tên project, chờ DB "khỏe" rồi mới chạy app, và cách kiểm tra sức khỏe DB.

> **Tóm gọn 1 câu:** File thật thêm `name:`, `healthcheck` và `depends_on: service_healthy` để app chỉ khởi động khi MySQL thực sự sẵn sàng.

### Các lệnh Docker Compose (v2/v5)

> 📄 **Code ví dụ:** [`examples/43-cac-lenh-docker-compose-v2-v5.sh`](examples/43-cac-lenh-docker-compose-v2-v5.sh)

### Compose Watch (tính năng mới — sync code real-time)

Kể từ Compose v2.22, bạn có thể dùng `develop.watch` thay cho bind mount thủ công:

> 📄 **Code ví dụ:** [`examples/44-compose-watch-tinh-nang-moi-sync-code-real.yaml`](examples/44-compose-watch-tinh-nang-moi-sync-code-real.yaml)

> 📄 **Code ví dụ:** [`examples/45-compose-watch-tinh-nang-moi-sync-code-real.sh`](examples/45-compose-watch-tinh-nang-moi-sync-code-real.sh)

> **Tóm gọn 1 câu:** `develop.watch` đưa tính năng live-reload vào luôn file YAML — gọn hơn tự gõ flag bind mount.

### So sánh: docker run vs docker compose

| docker run | docker compose |
|------------|----------------|
| Mỗi lệnh chạy 1 container | Chạy nhiều container cùng lúc |
| Phải nhớ nhiều flags | Định nghĩa 1 lần trong YAML |
| Khó tái sử dụng | Dễ tái sử dụng và share |
| Phù hợp chạy nhanh/test | Phù hợp multi-service apps |

> **Cách đọc bảng này:** Cột trái là `docker run` đơn lẻ, cột phải là Compose. Chọn nhanh: chạy thử 1 container thì dùng `docker run`, app nhiều service thì dùng Compose.

> **Tóm gọn 1 câu:** `docker run` cho việc nhanh gọn một container, `docker compose` cho app nhiều service.

---

## Part 8: Multi-stage Builds

> Vấn đề: Image production thường chứa cả build tools (yarn, gcc, dev dependencies...) không cần thiết → image to, chậm deploy, tăng bề mặt tấn công bảo mật. **Multi-stage builds** giải quyết bằng cách dùng nhiều `FROM` trong một Dockerfile. Nôm na: như nấu ăn trong bếp đầy đủ dụng cụ, rồi chỉ bưng món thành phẩm ra bàn — khách không cần thấy cả căn bếp.

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

> 📄 **Code ví dụ:** [`examples/46-dockerfile-multi-stage-cho-todo-app-node-js.dockerfile`](examples/46-dockerfile-multi-stage-cho-todo-app-node-js.dockerfile)

**Kỹ thuật quan trọng:**

| Kỹ thuật | Ý nghĩa |
|----------|----------|
| `FROM <image> AS <tên>` | Đặt tên stage để `COPY --from=<tên>` dễ đọc, không bị lỗi khi đổi thứ tự |
| `COPY --from=build` | Copy artifact từ stage trước vào stage hiện tại |
| `USER node` | Chạy container bằng user non-root (không phải `root`) |
| `ENV NODE_ENV=production` | Chỉ cài production dependencies trong stage cuối |
| Copy `package*.json` **trước** source | Tận dụng build cache — chỉ `yarn install` lại khi dependencies đổi |

> **Cách đọc bảng này:** Mỗi dòng là một kỹ thuật trong Dockerfile multi-stage. Cặp quan trọng nhất: `FROM ... AS <tên>` để đặt tên stage, và `COPY --from=<tên>` để bưng artifact qua stage sau.

> **Tóm gọn 1 câu:** Nhiều `FROM` = nhiều stage; bưng chỉ phần cần thiết từ stage build sang stage cuối, giữ image gọn và sạch.

### Build với stage cụ thể

> 📄 **Code ví dụ:** [`examples/47-build-voi-stage-cu-the.sh`](examples/47-build-voi-stage-cu-the.sh)

### Lợi ích của multi-stage builds

- 📉 **Giảm kích thước image**: không chứa build tools, cache, dev dependencies
- 🔒 **Giảm attack surface**: ít package → ít CVE tiềm ẩn
- 🔐 **Không leak secrets**: `ARG` trong stage build không xuất hiện ở image cuối (`docker history` không thấy)
- ⚡ **Build song song**: các stage độc lập chạy parallel với BuildKit
- 🧪 **Debug dễ dàng**: giữ nguyên stage `build`/`debug` riêng, không ảnh hưởng production

> **Tóm gọn 1 câu:** Multi-stage build giúp image nhỏ hơn, an toàn hơn, không leak secret, và vẫn giữ chỗ debug riêng khi cần.

---

## Part 9: Docker Scout - Security Scanning

> **Docker Scout** phân tích image và tạo **SBOM** (Software Bill of Materials), đối chiếu với cơ sở dữ liệu CVE cập nhật liên tục để phát hiện lỗ hổng bảo mật. Tích hợp sẵn trong Docker Desktop 4.23+ và Docker Hub. Hiểu đơn giản: Scout như bác sĩ khám định kỳ cho image — nó liệt kê "hồ sơ bệnh án" (SBOM) rồi đối chiếu với danh sách "vi-rút" (CVE) mới nhất để báo bạn biết.

### Các lệnh Docker Scout cơ bản

> 📄 **Code ví dụ:** [`examples/48-cac-lenh-docker-scout-co-ban.sh`](examples/48-cac-lenh-docker-scout-co-ban.sh)

### Xuất báo cáo (CI/CD integration)

> 📄 **Code ví dụ:** [`examples/49-xuat-bao-cao-ci-cd-integration.sh`](examples/49-xuat-bao-cao-ci-cd-integration.sh)

### Enroll organization với Docker Scout (phân tích repo remote)

> 📄 **Code ví dụ:** [`examples/50-enroll-organization-voi-docker-scout-phan-tich-repo.sh`](examples/50-enroll-organization-voi-docker-scout-phan-tich-repo.sh)

> 💡 **Lưu ý:** Phân tích local bằng CLI/Docker Desktop không lưu data. Khi enable cho repository, Docker Scout lưu snapshot metadata và **tự động đánh giá lại** khi có CVE mới — không cần quét lại image.

> **Tóm gọn 1 câu:** Docker Scout quét lỗ hổng trong image và, khi bật cho repository, tự re-check mỗi khi có CVE mới.

---

## Part 10: CI/CD với GitHub Actions

> Tự động hóa: mỗi lần push code lên GitHub → build image → scan bảo mật → push lên registry. Tất cả chạy trong pipeline **GitHub Actions**, không cần làm thủ công. Coi như bạn thuê một "robot trực ca": bạn đẩy code lên, robot tự làm nốt phần còn lại.

### Workflow hoàn chỉnh

Tạo file `.github/workflows/docker.yml`:

> 📄 **Code ví dụ:** [`examples/51-workflow-hoan-chinh.yaml`](examples/51-workflow-hoan-chinh.yaml)

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

> **Cách đọc bảng này:** Mỗi dòng là một mảnh trong file workflow. Ba mảnh đáng nhớ nhất: `build-push-action` làm việc nặng, `cache-from/to` giúp build nhanh, `--exit-code` của Scout chặn image lỗi.

> 💡 **Chặn image lỗi nhưng không block cứng?** Ở giai đoạn đầu, có thể để bước Scout chỉ warning bằng cách thêm `continue-on-error: true`, sau đó turn thành fail cứng khi team đã quen xử lý CVE.

### Biến thể: push lên GitHub Container Registry (ghcr.io)

> 📄 **Code ví dụ:** [`examples/52-bien-the-push-len-github-container-registry-ghcr.yaml`](examples/52-bien-the-push-len-github-container-registry-ghcr.yaml)

### Best Practices cho Docker CI/CD

1. **Pin version của actions** — dùng `@v4` / `@v3` (major tag) hoặc commit SHA đầy đủ để chống supply-chain attack qua actions.
2. **Multi-platform build** — thêm `platforms: linux/amd64,linux/arm64` vào `build-push-action` khi cần chạy trên server ARM.
3. **Đừng cache với `--no-cache`** — nếu cần build "sạch", thay vì tắt cache toàn bộ, dùng `docker build --pull` để chỉ cập nhật base image.
4. **Scan sớm, scan mọi PR** — đặt bước Scout trước bước push để CVE bị chặn trước khi image vào registry.
5. **Xuất SARIF lên GitHub Code Scanning** — `docker scout cves --format sarif --output report.sarif.json` rồi dùng `github/codeql-action/upload-sarif` để thấy CVE ngay trong tab Security của repo.

> **Tóm gọn 1 câu:** Pipeline chuẩn: pin version action, scan Scout trước khi push, dùng cache để build nhanh, và tag image theo commit hash để truy vết.

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

> **Tóm gọn 1 câu:** Dockerfile tốt = base image nhỏ, multi-stage, non-root, có `.dockerignore`, và sắp lệnh tận dụng cache.

### 2. Docker Compose

1. **Không dùng `version:`** — field này obsolete; chỉ dùng Compose Specification.
2. **Tên file `compose.yaml`** — chuẩn mới, ưu tiên cao hơn `docker-compose.yml`.
3. **Đặt tên project** — dùng `name:` top-level (Compose v2.3.3+) thay vì `-p`:
   > 📄 **Code ví dụ:** [`examples/53-2-docker-compose.yaml`](examples/53-2-docker-compose.yaml)
4. **Dùng `healthcheck` + `depends_on` với condition** — chờ DB sẵn sàng trước khi start app.
5. **External secrets qua `.env`** — không hardcode password trong YAML; dùng biến môi trường và `.env` (đã `.gitignore`).

> **Tóm gọn 1 câu:** Compose chuẩn mới: bỏ `version:`, dùng `compose.yaml`, đặt `name:`, và chờ DB healthy trước khi chạy app.

### 3. Bảo mật (Security)

1. **Scan image với Docker Scout** — `docker scout cves <image>` (xem Part 9).
2. **Không chạy container bằng `root`** — dùng `USER` instruction.
3. **Giới hạn quyền**: `--read-only`, `--cap-drop=ALL`, `--security-opt=no-new-privileges` khi phù hợp.
4. **Không đưa secrets vào `ARG`/`ENV`** — dùng Docker BuildKit secret mounts:
   > 📄 **Code ví dụ:** [`examples/54-3-bao-mat-security.sh`](examples/54-3-bao-mat-security.sh)
5. **Cập nhật base image thường xuyên** — rebuild định kỳ với `docker build --pull`.

> **Tóm gọn 1 câu:** Bảo mật = quét image bằng Scout, không chạy root, giới hạn quyền, và không bao giờ nhúng secret vào image.

### 4. Dev Experience

1. **Bind mount / `docker compose watch`** cho dev; **named volume** cho production data.
2. **Sử dụng build cache hiệu quả** — sắp xếp Dockerfile theo tần suất thay đổi (ít đổi → trên cùng).
3. **Kiểm tra logs real-time** với `docker logs -f` hoặc `docker compose logs -f` để debug nhanh.

> **Tóm gọn 1 câu:** Dev với Docker thoải mái hơn: bind mount/`compose watch` cho code sống, cache đúng chỗ, và log real-time để bắt lỗi liền.

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

> **Tóm gọn 1 câu:** Từ Dockerfile đến CI/CD, bạn đã đi trọn vòng đời: đóng gói, chạy, lưu data, chia sẻ, và tự động hóa — kèm thói quen bảo mật đúng chuẩn.

### Lệnh Docker Reference

> 📄 **Code ví dụ:** [`examples/55-lenh-docker-reference.sh`](examples/55-lenh-docker-reference.sh)

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