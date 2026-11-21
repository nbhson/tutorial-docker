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
