# Trên Fedora/RHEL, nếu không có :z/:Z container sẽ bị "Permission denied"
docker run -d -v "$(pwd):/app:z" my-app
