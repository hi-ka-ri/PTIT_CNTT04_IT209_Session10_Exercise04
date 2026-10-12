# Bài 4: Thiết lập Custom Network & Named Volume bằng Docker CLI

## 1. Mục tiêu
- Tạo **Custom Bridge Network** để các Container giao tiếp nội bộ qua tên service (**DNS resolution**).
- Tạo **Named Volume** lưu trữ dữ liệu bền vững (**Data Persistence**).

---

## 2. Các bước thực hiện trong `commands.sh`

### Bước 1: Tạo Custom Bridge Network tên `app-net`
```bash
docker network create --driver bridge app-net
```

### Bước 2: Tạo Named Volume tên `db-data`
```bash
docker volume create db-data
```

### Bước 3: Khởi chạy Database Container (`postgres:15-alpine`) tên `db-server`
Gia nhập network `app-net` và mount volume `db-data` vào `/var/lib/postgresql/data`:
```bash
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=mydb \
  postgres:15-alpine
```

### Bước 4: Khởi chạy Backend Container tham gia `app-net`
Truyền biến kết nối DB bằng hostname `db-server`:
```bash
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
```

---

## 3. Test Data Persistence (Tính bền vững của dữ liệu)

1. **Thêm dữ liệu vào Database:**
```bash
docker exec -i db-server psql -U postgres -d mydb -c "CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name VARCHAR(50));"
docker exec -i db-server psql -U postgres -d mydb -c "INSERT INTO users (name) VALUES ('DevOps Student 1'), ('DevOps Student 2');"
docker exec -i db-server psql -U postgres -d mydb -c "SELECT * FROM users;"
```

2. **Xóa cứng container DB:**
```bash
docker rm -f db-server
```

3. **Khởi chạy lại container DB mới gắn cùng Volume `db-data`:**
```bash
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=mydb \
  postgres:15-alpine
```

4. **Xác minh dữ liệu không bị mất:**
```bash
docker exec -i db-server psql -U postgres -d mydb -c "SELECT * FROM users;"
```
*Kết quả:* Dữ liệu các bản ghi trong bảng `users` vẫn được giữ nguyên vẹn nhờ Named Volume `db-data`.

---

## 4. Lệnh kiểm tra theo yêu cầu đề bài

```bash
docker network ls | grep app-net
docker volume ls | grep db-data
docker network inspect app-net
docker exec -it app-container ping -c 2 db-server
```

### Kết quả mong đợi:
- **Ping test:** Lệnh `ping db-server` từ Backend container (`app-container`) giải mã thành công IP nội bộ của DB container qua cơ chế DNS resolution của Custom Bridge Network.
- **Data Persistence:** Dữ liệu DB nguyên vẹn sau khi xóa cứng và tái tạo container DB mới.

---

## 5. Hướng dẫn nộp bài
- **Đường dẫn trên GitHub:** `homework/session_10/ex4/`
- **Cơ chế nộp:** Nộp `commands.sh` và `README.md`.
