# Capstone — Hướng dẫn chuẩn bị demo

Buổi demo cuối khóa là lúc bạn chứng minh hệ thống chạy thật và bạn hiểu mọi thứ mình đã làm. Trước khi demo, hoàn thành [self-checklist.md](self-checklist.md).

Thời lượng gợi ý cho phần trình bày của bạn: **~30 phút**, sau đó là hỏi đáp.

## Chuẩn bị trước buổi demo
- [ ] Tất cả VM đang chạy, Jenkins và agent online, registry truy cập được
- [ ] Trình duyệt đã import CA nội bộ (hoặc bạn sẵn sàng giải thích cảnh báo cert)
- [ ] Mở sẵn các terminal SSH vào app server, DB server, Jenkins
- [ ] Chuẩn bị sẵn **2 commit** trên branch riêng: 1 thay đổi hợp lệ nhìn thấy được, 1 thay đổi cố tình làm BE lỗi
- [ ] Chạy thử toàn bộ kịch bản dưới đây ít nhất 1 lần trước buổi demo, ghi lại thời gian từng phần
- [ ] Chuẩn bị phương án dự phòng: ảnh chụp/log của từng bước nếu mạng hoặc VM gặp sự cố
- [ ] Biết cách khôi phục nhanh nếu demo hỏng giữa chừng (rollback thủ công, restart service)

## Kịch bản trình bày

### Phần 1 — Tổng quan (5 phút)
- [ ] Trình bày sơ đồ kiến trúc 2 cách deploy, luồng request và luồng CI/CD
- [ ] Giới thiệu cấu trúc repo, chỉ ra secret được lưu ở đâu (không phải trong repo)

### Phần 2 — Hệ thống đang chạy (3 phút)
- [ ] Mở `https://capstone.<tên>.local`, thêm/sửa/xóa dữ liệu
- [ ] `curl -I http://capstone.<tên>.local` → redirect sang HTTPS
- [ ] `curl -k https://capstone.<tên>.local/api/health` → trạng thái app + DB
- [ ] Xem certificate trên trình duyệt: issuer, SAN, ngày hết hạn

### Phần 3 — Deploy version mới (5 phút)
- [ ] Merge commit thay đổi hợp lệ vào `main`
- [ ] Pipeline tự chạy: build → test → image version mới → push → deploy staging → approve → production → smoke test
- [ ] Chỉ ra tag image trên registry, version trong lịch sử deploy, version hiển thị trên app hoặc `/api/health`

### Phần 4 — Deploy lỗi → rollback (5 phút)
- [ ] Merge commit cố tình lỗi
- [ ] Pipeline phát hiện qua smoke test → **rollback tự động** → app trở lại version trước
- [ ] Pipeline kết thúc **FAILURE**, log ghi rõ đã rollback về version nào
- [ ] Chạy job rollback thủ công về một version cũ hơn, smoke test pass
- [ ] Mở lịch sử deploy chỉ ra các dòng SUCCESS / FAILED / ROLLBACK

### Phần 5 — Hai cách deploy (4 phút)
- [ ] Cách 1: `systemctl status`, `journalctl -u <app>`, `ls -l /opt/<app>/current`; `kill -9` process BE → tự lên lại
- [ ] Cách 2: `docker compose ps` (healthy); chứng minh BE/DB không publish port (`ss -tlnp`, `docker port`)

### Phần 6 — Bảo mật & least privilege (4 phút)
- [ ] Đăng nhập DB bằng `app_user`: `DROP TABLE` / `CREATE TABLE` bị từ chối
- [ ] Đăng nhập bằng `readonly_user`: `INSERT` bị từ chối
- [ ] Kết nối DB từ một máy không phải BE → bị từ chối
- [ ] `sudo ufw status verbose` trên app server và DB server
- [ ] User `deploy` thử `sudo cat /etc/shadow` → bị từ chối
- [ ] Quét repo không có secret; console log Jenkins hiển thị `****`

### Phần 7 — Chrome DevTools (4 phút)
Theo [devtools-checklist.md](devtools-checklist.md):
- [ ] Tab Network: request `/api/...` — method, status, headers, payload, timing
- [ ] Chứng minh FE và BE cùng origin (không có preflight `OPTIONS`, không header CORS)
- [ ] Tab Security: thông tin cert
- [ ] Tái hiện trực tiếp ít nhất 1 lỗi: dừng BE → 502, sai path → 404 — và giải thích

## Sẵn sàng cho tình huống debug trực tiếp
Trong buổi demo bạn có thể được yêu cầu xử lý một lỗi phát sinh trên chính hệ thống của mình. Hãy luyện trước bằng phần **Tự luyện debug** trong [self-checklist.md](self-checklist.md) và quen với quy trình:

**triệu chứng → xem log nào → giả thuyết → kiểm chứng → sửa → xác nhận lại**

Chuẩn bị sẵn các lệnh hay dùng: `systemctl status`, `journalctl -u … -f`, `tail -f /var/log/nginx/error.log`, `docker compose logs -f`, `ss -tlnp`, `curl -v`, `openssl s_client`, `psql`/`mysql`.

## Câu hỏi tự kiểm tra trước buổi demo
Tự trả lời trước, ghi vào `docs/demo-prep.md`. Nếu chưa trả lời được câu nào, quay lại module tương ứng.

**Kiến trúc & Nginx**
1. Đi từ lúc gõ URL trên trình duyệt đến khi có dữ liệu từ DB: liệt kê từng bước (DNS, TCP, TLS, Nginx, BE, DB).
2. `proxy_pass http://backend;` và `proxy_pass http://backend/;` khác nhau thế nào với location `/api/`?
3. Vì sao dùng 1 endpoint thì không cần CORS? Khi nào vẫn phải cấu hình CORS?
4. SPA fallback (`try_files $uri /index.html`) dùng để làm gì? Nếu thiếu thì lỗi gì xảy ra?

**HTTPS**
5. Self-signed cert và cert do CA nội bộ ký khác nhau thế nào? Vì sao trình duyệt cảnh báo?
6. SAN là gì? Vì sao cert chỉ có CN mà không có SAN bị Chrome từ chối?
7. TLS termination tại Nginx nghĩa là gì? Traffic Nginx → BE có mã hóa không, có cần không?

**Linux & Docker**
8. So sánh 2 cách deploy: ưu nhược điểm, khi nào chọn cách nào?
9. `Restart=always` và `Restart=on-failure` khác nhau? Restart policy của Docker tương ứng?
10. Vì sao BE/DB không nên publish port trong compose? Container nói chuyện với nhau bằng gì?
11. Dữ liệu DB nằm ở đâu khi chạy bằng Docker? `docker compose down -v` gây hậu quả gì?

**Database**
12. Giải thích từng GRANT của 3 user. Vì sao tách `migration_user` khỏi `app_user`?
13. `pg_hba.conf` / `bind-address` và firewall — vì sao cần cả hai lớp?
14. Backup của bạn có restore được không? Đã thử khi nào? RPO/RTO hiện tại là bao nhiêu?

**CI/CD & rollback**
15. Image production có phải chính image đã test ở staging không? Chứng minh bằng cách nào?
16. Rollback app nhưng DB đã migration thì xử lý thế nào?
17. Jenkins controller chết thì có ảnh hưởng ứng dụng đang chạy không? Mất `JENKINS_HOME` thì khôi phục thế nào?
18. Secret được truyền từ Jenkins đến server như thế nào, nằm ở đâu, quyền file ra sao?

**Vận hành**
19. App chạy chậm bất thường — bạn kiểm tra những gì, theo thứ tự nào?
20. Nếu đưa hệ thống này lên production thật cho khách hàng, bạn còn thiếu gì?
