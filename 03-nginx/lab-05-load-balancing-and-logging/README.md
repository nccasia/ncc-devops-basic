# Lab 05 ⭐ — Load Balancing, Logging & Rate Limit

> **Module:** 03 Nginx · **Không bắt buộc**

## Mục tiêu
- Cân bằng tải giữa nhiều backend bằng `upstream`.
- Hiểu health check thụ động của Nginx OSS.
- Tùy biến log format để đo hiệu năng upstream.
- Giới hạn tốc độ request (rate limit).

## Kiến thức cần có
- Lab 03, Lab 04.

## Môi trường
- vm2: Nginx. Backend: 2 instance của `../lab-03-reverse-proxy/starter/app.py` — một trên vm2 (`127.0.0.1:3001`), một trên vm3 (`192.168.56.13:3000`) hoặc 2 port trên cùng vm2.

## Yêu cầu
1. Khai báo `upstream backend` với 2 server. Endpoint `/` của app hiển thị hostname/port để phân biệt instance.
2. So sánh các thuật toán: round robin (mặc định), `weight`, `least_conn`, `ip_hash`. Gửi 20 request bằng vòng lặp `curl` và thống kê phân bố cho từng thuật toán.
3. Health check thụ động: cấu hình `max_fails`, `fail_timeout`, `proxy_next_upstream`. Tắt một backend trong lúc chạy vòng lặp `curl` — chứng minh client không nhận lỗi (hoặc chỉ lỗi ở 1 request đầu) và backend được thử lại sau `fail_timeout`.
4. Tạo `log_format` tên `upstream_log` gồm tối thiểu: `$remote_addr`, `$request`, `$status`, `$request_time`, `$upstream_addr`, `$upstream_status`, `$upstream_response_time`. Dùng format này cho site.
5. Viết script `top-slow.sh` đọc access log và in ra 10 request chậm nhất + số request theo từng `upstream_addr`.
6. Rate limit `/api/`: tối đa 5 request/giây mỗi IP, `burst=10`, trả `429` khi vượt. Chứng minh bằng `ab`, `hey` hoặc vòng lặp `curl`.

## Kết quả cần nộp
`devops-training/03-nginx/lab-05-load-balancing-and-logging/`:
- `NOTES.md`: bảng thống kê phân bố request theo thuật toán, log khi tắt backend, kết quả test rate limit
- `lb.conf`, `top-slow.sh`

## Tiêu chí đạt
- [ ] Request được phân phối tới cả 2 backend
- [ ] Tắt 1 backend, dịch vụ vẫn trả `200`
- [ ] Log có đủ các trường yêu cầu, `top-slow.sh` chạy đúng
- [ ] Vượt rate limit nhận `429` (không phải `503` mặc định)

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Health check thụ động khác health check chủ động thế nào? Nginx OSS hỗ trợ loại nào?
2. Khi nào nên dùng `ip_hash`? Nhược điểm của nó?
3. `$request_time` khác `$upstream_response_time` thế nào? Nếu chênh lệch lớn thì nghĩa là gì?
4. `proxy_next_upstream` có nguy hiểm với request `POST` không? Vì sao?
5. `limit_req` dùng thuật toán gì (leaky bucket)? `burst` và `nodelay` ảnh hưởng thế nào?
6. `$upstream_addr` có thể chứa nhiều địa chỉ trong một dòng log — khi nào?

<details>
<summary>Gợi ý</summary>

- Directive: `upstream`, `least_conn`, `server ... max_fails=3 fail_timeout=10s`, `limit_req_zone`, `limit_req`, `limit_req_status`.
- `for i in $(seq 20); do curl -s http://app.training.local/; done | sort | uniq -c`
- `awk` là công cụ tốt để xử lý log có định dạng cố định.

</details>

## Tài liệu tham khảo
- https://nginx.org/en/docs/http/load_balancing.html
- https://nginx.org/en/docs/http/ngx_http_upstream_module.html
- https://nginx.org/en/docs/http/ngx_http_limit_req_module.html
- https://nginx.org/en/docs/http/ngx_http_log_module.html
