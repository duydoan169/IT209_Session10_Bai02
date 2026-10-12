# Base image: node 18 alpine nhẹ, tối ưu tài nguyên
FROM node:18-alpine

# Thư mục làm việc bên trong container
WORKDIR /app

# Biến môi trường chỉ định cổng chạy ứng dụng
ENV PORT=3000

# Copy file định nghĩa phụ thuộc trước để tối ưu hóa layer caching
COPY package*.json ./

# Cài đặt các phụ thuộc ứng dụng
RUN npm install

# Copy toàn bộ mã nguồn ứng dụng
COPY . .

# Khai báo port lắng nghe bên trong container
EXPOSE 3000

# Lệnh khởi chạy ứng dụng (Exec form)
CMD ["node", "server.js"]
