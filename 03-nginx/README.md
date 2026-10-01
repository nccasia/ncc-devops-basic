# 03 — Nginx

> **Môi trường:** vm2 (192.168.56.12) làm web server, vm3 (192.168.56.13) làm client

## Mục tiêu

- Hiểu kiến trúc Nginx (master/worker, event-driven) và cấu trúc file cấu hình.
- Serve static website, cấu hình nhiều site trên cùng một server (virtual host).
- Dùng Nginx làm reverse proxy cho ứng dụng backend, hiểu các header proxy.
- Cấu hình HTTPS với chứng chỉ tự ký (self-signed CA), gom FE và BE về một endpoint.
- Đọc log để chẩn đoán lỗi 403/404/502/504.

## Lý thuyết cần tự học

- Cấu trúc `/etc/nginx/`: `nginx.conf`, `conf.d/`, `sites-available/`, `sites-enabled/`, `snippets/`
- Context: `main`, `events`, `http`, `server`, `location`, `upstream`; thứ tự match `location` (`=`, `^~`, regex `~`/`~*`, prefix)
- `root` vs `alias`, `index`, `try_files`
- `server_name`, `listen ... default_server`, cách Nginx chọn server block theo `Host` header
- `nginx -t`, `nginx -s reload`, `systemctl reload` vs `restart`
- Reverse proxy: `proxy_pass` (có/không có `/` cuối), `proxy_set_header`, timeout, buffer
- HTTP status code: 301/302, 400, 403, 404, 413, 499, 502, 503, 504
- TLS: CA, certificate chain, SAN, TLS handshake, HSTS
- Upstream & load balancing, `limit_req`

Tài liệu: https://nginx.org/en/docs/beginners_guide.html · https://nginx.org/en/docs/http/request_processing.html · https://www.digitalocean.com/community/tutorials/understanding-nginx-server-and-location-block-selection-algorithms

## Danh sách lab

| Lab | Nội dung | Bắt buộc |
|-----|----------|----------|
| [lab-01-static-site](lab-01-static-site/README.md) | Serve website tĩnh tại `/var/www/mysite` | ✅ |
| [lab-02-multiple-sites](lab-02-multiple-sites/README.md) | `site1.local`, `site2.local` + private DNS | ✅ |
| [lab-03-reverse-proxy](lab-03-reverse-proxy/README.md) | `site3.local` → app port 3000 | ✅ |
| [lab-04-https-self-signed](lab-04-https-self-signed/README.md) | Self-signed CA, HTTPS, `/api/*` → BE, `/*` → FE | ✅ |
| [lab-05-load-balancing-and-logging](lab-05-load-balancing-and-logging/README.md) | Upstream, load balancing, custom log, rate limit | ⭐ |

## Câu hỏi tự kiểm tra cuối module

Tự trả lời các câu dưới đây vào `devops-training/03-nginx/module-questions.md` sau khi xong các lab.

1. Một request tới `http://192.168.56.12/` — Nginx chọn `server` block nào khi có 3 site? Nếu `Host` không khớp `server_name` nào thì sao?
2. `location /api` và `location /api/` khác nhau thế nào? `proxy_pass http://app:3000` và `proxy_pass http://app:3000/` khác nhau thế nào?
3. `root` và `alias` khác nhau ra sao? Cho ví dụ cấu hình sai dẫn tới 404.
4. Gặp 403 Forbidden khi serve static: liệt kê ít nhất 3 nguyên nhân và cách kiểm tra từng cái.
5. 502 Bad Gateway khác 504 Gateway Timeout thế nào? Mỗi lỗi kiểm tra ở đâu?
6. Vì sao backend sau reverse proxy luôn thấy IP client là `127.0.0.1`? Sửa thế nào và backend cần làm gì để tin header đó?
7. `reload` khác `restart` thế nào? Vì sao luôn chạy `nginx -t` trước?
8. Trình bày luồng TLS handshake. Vì sao trình duyệt báo "Not secure" với cert tự ký và cách làm cho client tin cert?

## Bài tự luyện debug (break & fix)

Sau khi làm xong các lab, bạn tự cố tình làm hỏng môi trường theo từng kịch bản dưới đây (mỗi lần một lỗi), quan sát triệu chứng từ phía client, rồi tự chẩn đoán bằng log/lệnh và sửa lại. Ghi vào `devops-training/03-nginx/break-and-fix.md` theo bảng: **Kịch bản → Triệu chứng → Cách chẩn đoán (lệnh, dòng log) → Nguyên nhân → Cách sửa**.

- `chmod 700 /var/www/mysite` hoặc đổi owner thư mục web → trình duyệt thấy gì?
- Xóa symlink trong `sites-enabled`; hoặc khai báo 2 site cùng `default_server`.
- Sửa `proxy_pass` sang port sai, hoặc dừng backend; gọi `/slow` lâu hơn `proxy_read_timeout`.
- Cho `root` trỏ sai thư mục; dùng `alias` thiếu `/` cuối.
- Tạo cert đã hết hạn (`-days 0`/`faketime`) hoặc cert thiếu SAN — trình duyệt báo lỗi gì dù đã trust CA?
- Chặn port 80/443 bằng `ufw`.

Mẹo: trước khi xem lời giải ở đâu đó, hãy tự hỏi "request đi qua những chặng nào (DNS → mạng/firewall → Nginx → upstream)? Nó đã dừng ở chặng nào?"
