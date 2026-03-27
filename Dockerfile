# 1. Dùng bản Python nhẹ chuẩn production
FROM python:3.12-slim

# 2. Tạo user mới để chạy app (không dùng root để tránh bị hack server)
RUN useradd -m -u 1000 appuser
WORKDIR /app

# 3. Copy file danh sách thư viện và cài đặt
# Copy riêng file này trước để Docker cache lại, lần sau build sẽ cực nhanh
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copy toàn bộ mã nguồn vào container
COPY app.py .

# 5. Chuyển sang dùng user vừa tạo
USER appuser

# 6. Báo cho Docker biết app chạy cổng 5000
EXPOSE 5000

# 7. Lệnh khởi chạy ứng dụng
CMD ["python", "app.py"]