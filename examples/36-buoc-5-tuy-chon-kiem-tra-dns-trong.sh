# Chạy container netshoot để tra cứu DNS
docker run -it --network todo-network nicolaka/netshoot

# Trong netshoot container
dig mysql
