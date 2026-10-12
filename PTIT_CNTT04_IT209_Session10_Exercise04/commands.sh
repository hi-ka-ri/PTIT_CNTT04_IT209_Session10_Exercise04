
# 1. Tạo Custom Bridge Network tên app-net
docker network create --driver bridge app-net

# 2. Tạo Named Volume tên db-data
docker volume create db-data

# 3. Khởi chạy Database Container (postgres:15-alpine) tên db-server tham gia app-net, mount volume db-data vào /var/lib/postgresql/data
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=mydb \
  postgres:15-alpine

# Chờ Database khởi động sẵn sàng
sleep 5

# 4. Khởi chạy Backend Container tham gia app-net, truyền biến kết nối DB bằng hostname db-server
docker run -d \
  --name app-container \
  --network app-net \
  -e DB_HOST=db-server \
  -e DB_PORT=5432 \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e DB_NAME=mydb \
  alpine:latest \
  sleep 3600

# 5. Thực hiện test Data Persistence:
# 5.1. Thêm dữ liệu vào Database
docker exec -i db-server psql -U postgres -d mydb -c "CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name VARCHAR(50));"
docker exec -i db-server psql -U postgres -d mydb -c "INSERT INTO users (name) VALUES ('DevOps Student 1'), ('DevOps Student 2');"
echo "=== Dữ liệu trước khi xóa container ==="
docker exec -i db-server psql -U postgres -d mydb -c "SELECT * FROM users;"

# 5.2. Xóa cứng container DB
docker rm -f db-server

# 5.3. Khởi chạy lại container DB mới gắn cùng Volume db-data
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=mydb \
  postgres:15-alpine

# Chờ Database mới khởi động sẵn sàng
sleep 5

# 5.4. Xác minh dữ liệu không bị mất
echo "=== Dữ liệu sau khi tái tạo container DB mới (Data Persistence) ==="
docker exec -i db-server psql -U postgres -d mydb -c "SELECT * FROM users;"

# 6. Các lệnh kiểm tra theo yêu cầu đề bài
echo "=== Lệnh kiểm tra 1: docker network ls | grep app-net ==="
docker network ls | grep app-net

echo "=== Lệnh kiểm tra 2: docker volume ls | grep db-data ==="
docker volume ls | grep db-data

echo "=== Lệnh kiểm tra 3: docker network inspect app-net ==="
docker network inspect app-net

echo "=== Lệnh kiểm tra 4: docker exec -it app-container ping -c 2 db-server ==="
docker exec -it app-container ping -c 2 db-server || docker exec app-container ping -c 2 db-server
