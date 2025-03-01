# DOCKER

## Docker là gì ?

Docker là một nền tảng giúp quá trình develop diễn ra đơn giản hơn.

Nó cho phép tạo các môi trường độc lập và tách biệt _(FE + BE + DB + ...)_ để khởi chạy và phát triển ứng dụng. môi trường này được gọi là **container**.

Khi cần deploy lên bất kỳ server nào chỉ cần run container của Docker thì application của bạn sẽ được khởi chạy ngay lập tức.

> Docker desktop phần mềm cài đặt môi trường docker trên máy tính (Kubernetes)
> Docker hub là nơi lưu trữ file (Image)

-   **Docker image**

Docker image là một ảnh của một môi trường phát triển (có thể hiểu là snapshot). Nói ngắn gọn là chúng ta có thể gói các cài đặt môi trường (OS, package, phần mềm của chúng ta đã viết, …) lại thành 1 cục duy nhất, đó chính là docker image. Khi đã có docker image, ta có thể khởi tạo các docker container từ docker image.

-   **Dockerfile**

Bao gồm các câu lệnh để tạo ra images

-   **Docker container**

Docker container là máy ảo chứa môi trường phần mềm, dùng để chạy các file image

## Tại sao phải dùng Docker ?

Việc setup và deploy application lên một hoặc nhiều server rất vất vả từ việc phải cài đặt các **công cụ**, **môi trường** cần cho application đến việc chạy được ứng dụng chưa kể việc không đồng nhất giữa các **môi trường** _(window/linux/mac)_ trên nhiều server khác nhau. Chính vì lý do đó Docker được ra đời để giải quyết vấn đề này.

Việc đóng gói vào container có những lợi ích:

-   Không lo bị lộ mã nguồn
-   Khách hàng không cần cài đặt, chỉ cần chạy lệnh để chạy chương trình

## Getting started:

### Part 1: Config, create image and container

-   Step 1: Run `git clone https://github.com/docker/getting-started.git`
-   Step 2: Create an empty file named `Dockerfile` in getting-started folder
-   Step 3: Add contents into Dockerfile:

```bash
# syntax=docker/dockerfile:1
FROM node:18-alpine
WORKDIR /app
COPY . .
RUN yarn install --production
CMD ["node", "src/index.js"]
EXPOSE 3000
```

-   Step 4: Run `docker build -t [image-name] .` to build image
-   Step 5: Create and start app container: `docker run -dp 3000:3000 [image-name]`

Đây là config cho nodeJS và mongoDB

```bash
# syntax=docker/dockerfile:1
FROM node:18-alpine
WORKDIR /app_container
COPY . .
ENV MONGODB_URI=mongodb://host.docker.internal:27017/cshop
RUN yarn install --production
EXPOSE 3000
CMD ["node", "src/index.js"]
```

### Part 2: Update container (remove old container and create new)

-   Cách dễ nhất là build lại image, và chạy lại container

    -   Step 1: Run `docker build -t [image-name] .` to build image
    -   Step 2: Create and start app container: `docker run -dp 3000:3000 [image-name]`

-   Cách để start/stop/remove docker

    -   `docker start [container-id]`: start a container
    -   `docker stop [container-id]`: stop a container
    -   `docker rm [container-id]`: delete a container

-   Để xem list images và containers có thể dùng lệnh:
    -   `docker ps -a` (process status): view list container
    -   `docker image ls`: view list image

### Part 3: Share image (upload images on docker hub)

-   Step 1: build image on local with tag: `docker build -t [image-name]:[tag-name] .`
-   Step 2: define tag for this image: `docker tag [image-local-name]:[tag-name] [user-name]/[repo-name]:[tag-name]`
-   Step 3: push image on docker hub: `docker push [user-name]/[repo-name]:[tag-name]`
-   Step 4: run image use https://labs.play-with-docker.com/: open port and run `docker run -dp 3000:3000 [user-name]/[repo-name]:[tag-name]`

### Part 4: Container volumes & Persist Data (keeping data - dùng cho thực tế)

-   Step 1: run `docker volume create [volume-name]` để tạo một nơi lưu trữ bên ngoài container
-   Step 2: run `docker run -dp 3000:3000 --mount type=volume,src=[volume-name],target=/etc/todos [image-name]` để khi F5 hoặc xóa container và build lại sẽ không mất data, do data được lưu ở container volumes, vùng nhớ bên ngoài
- Step 3: run `docker volume inspect [volume-name]` để xem các thông tin của volume

### Part 5: Use bind mounts (auto refresh container - dùng cho test local)

-   Step 1: docker run -dp 3000:3000 `-w /app -v "$(pwd):/app" ` node:12-alpine sh -c "yarn install && yarn run dev": set up cho container khi có thay đổi, thì chỉ cần F5 là nó đổi theo, không cần phải build lại image

> Cần đợi một khoảng thời gian để yarn install các package, lúc đó ứng dụng mới start được

-   Step 2: run `docker logs -f [container-id]`: log cái status của con docker container

### Part 6: Multi container (mỗi container chỉ nên làm tốt một nhiệm vụ)

- Step 1: run `docker network create [network-name]` dùng để tạo một network mới
- Step 2: run `docker network ls` xem list network
- Step 3: run  docker run -d ` --network [network-name] --network-alias mysql ` -v todo-mysql-data:/var/lib/mysql ` -e MYSQL_ROOT_PASSWORD=secret ` -e MYSQL_DATABASE=[database-name] ` mysql:8.0: tạo sql container với network đã tạo trước đó
- Step 4: run `docker exec -it [mysql-container-id] mysql -u root -p` verify sql bằng user và password (**secret**)
- Step 5: run `docker run -it --network [network-name] nicolaka/netshoot` và `dig mysql`: tạo một image mới với network để xem địa chỉ ip của mysql (bước này không cần thiết)
- Step 6: run `docker run -dp 127.0.0.1:3000:3000 -w /app -v "$(pwd):/app" --network [network-name] -e MYSQL_HOST=mysql -e MYSQL_USER=root -e MYSQL_PASSWORD=secret -e MYSQL_DB=todos [image-name] sh -c "yarn install && yarn run dev"`: khởi tạo ứng dụng với network

```bash
show databases;
use todos;
show tables;
select * from todo_items;
```

### Part 7: Compose (tập hợp các file config cho multi container và tạo ra một container bao các container nhỏ bên trong)

- Step 1: run `docker-compose version` để kiểm tra version
- Step 2: tạo `docker-compose.yml` file và config
- Step 3: run `docker compose up -d`: start app

## Link

### Lí thuyết

<https://viblo.asia/p/docker-la-gi-kien-thuc-co-ban-ve-docker-maGK7qeelj2#_i-tai-sao-phai-dung-docker--0>

### Thực hành

<https://docs.docker.com/get-started/>

