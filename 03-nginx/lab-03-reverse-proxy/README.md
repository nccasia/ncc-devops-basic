# Lab 03 — Reverse Proxy

> **Module:** 03 Nginx

## Mục tiêu
- Dùng Nginx làm reverse proxy chuyển tiếp request tới ứng dụng backend.
- Hiểu và cấu hình đúng các header proxy để backend biết thông tin client thật.
- Phân biệt và tái hiện được lỗi 502 và 504.

## Kiến thức cần có
- Lab 01, Lab 02. Python cơ bản (hoặc Node.js).

## Môi trường
- vm2 (`192.168.56.12`): Nginx + app. Client: vm3/máy host (đã phân giải được `site3.local` qua DNS/hosts ở lab 02).
- App mẫu: [`starter/app.py`](starter/app.py) (Flask). Được phép tự viết app Node.js tương đương.

## Yêu cầu
1. Chạy một ứng dụng đơn giản trên port **3000** (dùng `starter/app.py` hoặc Node.js/Express tự viết). App chỉ listen `127.0.0.1:3000` — không được truy cập trực tiếp từ bên ngoài.
2. Cấu hình Nginx làm reverse proxy: truy cập `http://localhost` (trên vm2) → forward đến `localhost:3000`.
3. Cấu hình domain `site3.local`: nhập `site3.local` ở trình duyệt client sẽ trả về content page của app đang chạy ở port 3000 trên server.
4. Thêm các header để backend nhận đúng thông tin client: `Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`. Dùng endpoint `/headers` của app mẫu để chứng minh trước/sau khi cấu hình.
5. Tái hiện và giải thích:
   - **502**: dừng app → truy cập lại, đọc error log.
   - **504**: gọi `/slow?seconds=10` khi `proxy_read_timeout 5s`, đọc error log.
6. Chạy app bằng user thường (không phải root). Ghi lại cách giữ app chạy sau khi logout (gợi ý: systemd — sẽ học kỹ ở module 04).

## Kết quả cần nộp
`devops-training/03-nginx/lab-03-reverse-proxy/`:
- `NOTES.md`: các bước, output `/headers` trước/sau, log 502 và 504 kèm giải thích, output `ss -tlnp`
- `site3.conf`
- App (nếu tự viết)

## Tiêu chí đạt
- [ ] `curl http://site3.local/` từ client trả nội dung của app
- [ ] `curl http://192.168.56.12:3000` từ client **không** kết nối được
- [ ] `/headers` hiển thị `X-Real-IP` là IP client thật (VD `192.168.56.13`), không phải `127.0.0.1`
- [ ] Tái hiện được 502 và 504, chỉ ra đúng dòng error log tương ứng
- [ ] App không chạy bằng root

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Forward proxy và reverse proxy khác nhau thế nào? Lợi ích của reverse proxy?
2. `proxy_pass http://127.0.0.1:3000;` và `proxy_pass http://127.0.0.1:3000/;` khác nhau thế nào khi đặt trong `location /app/`?
3. `X-Forwarded-For` có thể bị client giả mạo không? Backend nên tin header này trong trường hợp nào?
4. Nếu không set `proxy_set_header Host`, backend nhận `Host` là gì? Khi nào điều đó gây lỗi?
5. Phân biệt `proxy_connect_timeout`, `proxy_send_timeout`, `proxy_read_timeout`.
6. Mã lỗi `499` trong access log nghĩa là gì?
7. Vì sao app nên bind `127.0.0.1` thay vì `0.0.0.0` khi đã có reverse proxy?

<details>
<summary>Gợi ý</summary>

- Cài Flask trong virtualenv: `python3 -m venv venv && ./venv/bin/pip install flask`.
- Biến `$remote_addr`, `$proxy_add_x_forwarded_for`, `$scheme`, `$host` của Nginx.
- Thử `curl -v` để xem chi tiết request/response.
- Nếu bật UFW: chỉ mở 80 (và 22), không mở 3000.

</details>

## Tài liệu tham khảo
- https://nginx.org/en/docs/http/ngx_http_proxy_module.html
- https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/
- https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For
