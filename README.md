# BÀI 2: ĐÓNG GÓI ỨNG DỤNG WEB BACKEND BẰNG SINGLE-STAGE DOCKERFILE

---

## 1. Mục tiêu & Bối cảnh

Trong quy trình phát triển và triển khai phần mềm (CI/CD), việc đóng gói ứng dụng Backend thành Docker Image giúp:
- **Chuẩn hóa môi trường:** Ứng dụng chạy đồng nhất trên mọi máy chủ mà không phụ thuộc vào việc máy chủ đã cài đặt Node.js hay chưa.
- **Dễ dàng phân phối & kiểm thử:** Đóng gói toàn bộ source code và thư viện phụ thuộc vào một image duy nhất để sẵn sàng deploy lên môi trường Staging/Testing.

Dự án này triển khai một ứng dụng REST API viết bằng **Node.js/Express**, được đóng gói chuẩn hóa bằng **Single-stage Dockerfile** dựa trên base image siêu nhẹ `node:18-alpine`.

---

## 2. Cấu trúc thư mục

```
BT2/
├── Dockerfile          # Tệp cấu hình đóng gói Docker Single-stage
├── .dockerignore       # Loại trừ các file/thư mục không cần thiết khi build
├── package.json        # Định nghĩa dự án và các thư viện phụ thuộc (Express)
├── server.js           # Mã nguồn ứng dụng REST API
└── README.md           # Hướng dẫn chi tiết và kết quả kiểm thử
```

---

## 3. Chi tiết mã nguồn ứng dụng

### 3.1. `package.json`
Định nghĩa thông tin ứng dụng và thư viện phụ thuộc `express`:
```json
{
  "name": "ex2-backend",
  "version": "1.0.0",
  "description": "Simple Express backend packaged with Docker Single-stage",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

### 3.2. `server.js`
Khởi tạo Web Server lắng nghe cổng từ biến môi trường `PORT` (mặc định là `3000`), trả về JSON response tại endpoint `/`:
```javascript
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    status: 'success',
    message: 'Hello from Docker Single-stage!'
  });
});

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
```

---

## 4. Phân tích kiến trúc Dockerfile Single-stage

Nội dung tệp `Dockerfile`:
```dockerfile
# 1. Base Image siêu nhẹ dựa trên Alpine Linux
FROM node:18-alpine

# 2. Thiết lập thư mục làm việc bên trong container
WORKDIR /app

# 3. Khai báo biến môi trường chỉ định cổng dịch vụ
ENV PORT=3000

# 4. Copy tệp mô tả dependencies trước để tận dụng Docker Layer Caching
COPY package*.json ./

# 5. Cài đặt các thư viện phụ thuộc bên trong container
RUN npm install

# 6. Copy toàn bộ mã nguồn còn lại của ứng dụng
COPY . .

# 7. Khai báo cổng ứng dụng lắng nghe
EXPOSE 3000

# 8. Lệnh khởi chạy ứng dụng chính thức (Exec form)
CMD ["node", "server.js"]
```

### Giải thích chi tiết các chỉ thị:
1. **`FROM node:18-alpine`:**
   - Sử dụng phiên bản Node.js 18 trên nền tảng Alpine Linux.
   - Alpine Linux có dung lượng siêu nhẹ (~5MB), giúp giảm tổng kích thước Docker Image xuống mức tối thiểu (~130MB sau khi cài Express), giảm thời gian tải và giảm thiểu bề mặt tấn công bảo mật.
2. **`WORKDIR /app`:**
   - Tạo và chuyển thư mục làm việc mặc định trong container sang `/app`. Mọi chỉ thị sau đó (`COPY`, `RUN`, `CMD`) đều được thực thi tại đường dẫn này.
3. **`ENV PORT=3000`:**
   - Khai báo biến môi trường `PORT` để ứng dụng Node.js đọc thông qua `process.env.PORT`.
4. **`COPY package*.json ./` & `RUN npm install`:**
   - **Tối ưu hóa Docker Layer Cache:** Bằng cách copy riêng `package.json` và chạy `npm install` trước khi copy toàn bộ mã nguồn, Docker sẽ cache lại layer chứa `node_modules`. Khi lập trình viên chỉ sửa đổi code trong `server.js`, Docker sẽ bỏ qua bước `npm install` giúp tốc độ build image diễn ra gần như tức thì.
5. **`COPY . .`:**
   - Copy mã nguồn ứng dụng vào container. Kết hợp với `.dockerignore` để tránh copy đè thư mục `node_modules` hay `.git` từ máy host.
6. **`EXPOSE 3000`:**
   - Đóng vai trò tài liệu hóa (Documentation) và metadata chỉ định container lắng nghe kết nối tại port 3000.
7. **`CMD ["node", "server.js"]`:**
   - Sử dụng định dạng **Exec form** `["executable", "param1"]` thay vì Shell form.
   - Khi dùng Exec form, tiến trình Node.js sẽ được chạy trực tiếp dưới dạng `PID 1` trong container, giúp nó nhận đúng các tín hiệu UNIX (như `SIGTERM`, `SIGINT`) để thực hiện tắt ứng dụng an toàn (Graceful Shutdown).

---

## 5. Hướng dẫn xây dựng và kiểm thử hệ thống

### Bước 1: Build Docker Image
Chạy lệnh đóng gói image với tag `hw-backend:v1`:
```bash
docker build -t hw-backend:v1 .
```
- **Kết quả:** Quá trình build hoàn thành thành công không có lỗi, image được tạo với tag `hw-backend:v1`.

### Bước 2: Khởi chạy Container
Khởi chạy container ở chế độ nền (`-d`), đặt tên container là `app-single-stage` và ánh xạ port `8080` của host sang port `3000` của container:
```bash
docker run -d --name app-single-stage -p 8080:3000 hw-backend:v1
```

### Bước 3: Kiểm tra trạng thái Container
Kiểm tra container đang chạy:
```bash
docker ps
```
- **Kết quả thực tế:**
```text
CONTAINER ID   IMAGE           COMMAND                  CREATED          STATUS          PORTS                                         NAMES
7a39d4f4f677   hw-backend:v1   "docker-entrypoint.s…"   16 seconds ago   Up 15 seconds   0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp   app-single-stage
```
Container ở trạng thái **Up** và port mapping `8080:3000` hoạt động bình thường.

### Bước 4: Kiểm tra Logs của Container
Xem log xuất ra từ ứng dụng Node.js:
```bash
docker logs app-single-stage
```
- **Kết quả thực tế:**
```text
Server listening on port 3000
```

### Bước 5: Kiểm tra Endpoint HTTP bằng curl
Gửi yêu cầu GET đến cổng `8080`:
```bash
curl -i http://localhost:8080/
```
*(Trên môi trường Windows PowerShell có thể dùng `curl.exe -i -4 http://localhost:8080/` hoặc `Invoke-WebRequest -Uri "http://127.0.0.1:8080/"`)*

- **Kết quả HTTP Response thực tế:**
```http
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 64
ETag: W/"40-upZb7Fps+hszzRU9BoKtiCsmGCQ"
Date: Mon, 12 Oct 2026 00:59:31 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"status":"success","message":"Hello from Docker Single-stage!"}
```

---

## 6. Kết luận
- Ứng dụng đã được đóng gói thành công theo chuẩn Single-stage Dockerfile.
- Tận dụng hiệu quả base image `node:18-alpine` và cơ chế caching layer của Docker.
- Container vận hành ổn định, response trả về chuẩn `HTTP 200 OK` với dữ liệu JSON như yêu cầu.
