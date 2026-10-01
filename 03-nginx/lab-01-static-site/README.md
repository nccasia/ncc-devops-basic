# Lab 01 — Serve Static Website

> **Module:** 03 Nginx

## Mục tiêu
- Cài đặt và quản lý Nginx bằng systemd.
- Serve một website tĩnh (HTML + CSS) từ thư mục riêng.
- Nắm cấu trúc `sites-available` / `sites-enabled`, kiểm tra cấu hình, đọc log.

## Kiến thức cần có
- Module 01: quyền file, user/group, systemd.

## Môi trường
- Web server: vm2 (`192.168.56.12`). Client: máy host hoặc vm3.

## Yêu cầu
1. Cài Nginx, bật khởi động cùng hệ thống, kiểm tra trạng thái bằng `systemctl`.
2. Tạo website tĩnh đơn giản gồm ít nhất `index.html`, `about.html`, `css/style.css` (và 1 ảnh).
3. Đặt website tại `/var/www/mysite`. Owner và quyền phải hợp lý: Nginx (`www-data`) đọc được, **không** dùng `777`.
4. Tạo file cấu hình `/etc/nginx/sites-available/mysite`, enable bằng symlink sang `sites-enabled`, disable site `default`.
5. Truy cập được qua `http://localhost` (trên vm2) và `http://192.168.56.12` (từ client).
6. Cấu hình trang lỗi 404 tùy chỉnh (`404.html`).
7. Cấu hình access log và error log riêng cho site: `/var/log/nginx/mysite.access.log`, `/var/log/nginx/mysite.error.log`.
8. Thực hành và ghi lại sự khác nhau giữa `nginx -t`, `systemctl reload nginx`, `systemctl restart nginx` (quan sát PID master/worker trước và sau bằng `ps`).
9. Tái hiện lỗi 403 (bằng cách sai quyền), đọc error log để tìm nguyên nhân, rồi sửa lại.

## Kết quả cần nộp
`devops-training/03-nginx/lab-01-static-site/`:
- `NOTES.md`: các bước, output `curl -I`, `ls -la /var/www/mysite`, đoạn log 403 và cách sửa, quan sát reload vs restart
- `mysite.conf` (file cấu hình Nginx)
- `site/` (source website)

## Tiêu chí đạt
- [ ] `curl -I http://192.168.56.12` trả `200 OK` từ client
- [ ] `curl http://192.168.56.12/does-not-exist` trả trang 404 tùy chỉnh với status `404`
- [ ] Site `default` đã disable, `nginx -t` không lỗi/warning
- [ ] Quyền thư mục web hợp lý (không `777`), giải thích được vì sao cần quyền `x` trên thư mục
- [ ] Log ghi đúng file riêng của site

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Vì sao Nginx cần quyền `x` trên **tất cả** thư mục cha của `/var/www/mysite`?
2. `sites-available` / `sites-enabled` là quy ước của ai? Nginx đọc chúng nhờ dòng nào trong `nginx.conf`?
3. `reload` hoạt động thế nào để không làm rớt kết nối đang có? Khi nào bắt buộc phải `restart`?
4. Master process và worker process chạy dưới user nào? Vì sao?
5. `root` đặt trong `server` khác gì đặt trong `location`?
6. Nếu `nginx -t` báo OK nhưng site vẫn không truy cập được từ client, bạn kiểm tra những gì (theo thứ tự)?

<details>
<summary>Gợi ý</summary>

- `namei -l /var/www/mysite/index.html` giúp xem quyền của từng thư mục trên đường dẫn.
- `ss -tlnp | grep nginx` để xem Nginx đang listen port nào, trên địa chỉ nào.
- `tail -f /var/log/nginx/mysite.error.log` trong lúc `curl` để thấy lỗi ngay lập tức.
- Directive cần tìm hiểu: `error_page`, `access_log`, `error_log`, `index`.

</details>

## Tài liệu tham khảo
- https://nginx.org/en/docs/beginners_guide.html
- https://nginx.org/en/docs/http/ngx_http_core_module.html#error_page
- https://nginx.org/en/docs/control.html
