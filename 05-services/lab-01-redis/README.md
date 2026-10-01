# Lab 01 ⭐ — Redis: cài đặt, bảo mật và cache cho API

> **Module:** 05 Services · **Không bắt buộc**

## Mục tiêu
- Cài đặt Redis, giới hạn truy cập mạng và bật xác thực.
- Hiểu và cấu hình persistence (RDB, AOF).
- Áp dụng cache-aside cho endpoint `/api/employees` của app Flask ở module 04.

## Kiến thức cần có
- Module 04 lab-01 (app Flask đang chạy trên vm2).

## Môi trường
- vm1 (`192.168.56.11`): Redis server. vm2 (`192.168.56.12`): app Flask.

## Yêu cầu

### Phần A — Cài đặt & bảo mật
1. Cài Redis từ repo của Ubuntu (hoặc repo chính thức của Redis), chạy bằng systemd.
2. Cấu hình Redis listen trên `127.0.0.1` và `192.168.56.11`, giữ `protected-mode yes`.
3. Bật xác thực theo 2 cách và so sánh:
   - `requirepass` (user `default`)
   - **ACL**: tạo user `flaskapp` chỉ được dùng các lệnh `get`, `set`, `del`, `expire`, `ttl`, `ping` trên key có prefix `employees:*`; tắt user `default` hoặc đặt mật khẩu mạnh.
4. Firewall trên vm1: chỉ vm2 được kết nối port `6379`. Chứng minh vm3 không kết nối được.
5. Đổi tên/vô hiệu các lệnh nguy hiểm cho user ứng dụng (`FLUSHALL`, `CONFIG`, `KEYS`) — bằng ACL thay vì `rename-command`.

### Phần B — Persistence
6. Quan sát cấu hình RDB mặc định (`save`), tạo vài key, `systemctl restart redis` → key còn không? Xem file `dump.rdb` ở đâu.
7. Bật AOF (`appendonly yes`, `appendfsync everysec`). Ghi dữ liệu, kill `-9` process Redis, khởi động lại → kiểm tra dữ liệu.
8. Đặt `maxmemory 64mb` và chọn `maxmemory-policy` phù hợp cho cache — giải thích lựa chọn.

### Phần C — Cache cho Flask API
9. Sửa app Flask (module 04 lab-01): `/api/employees` dùng cache-aside — đọc key `employees:all` từ Redis, nếu không có thì query PostgreSQL rồi ghi vào Redis với TTL 60 giây.
10. Thêm header `X-Cache: HIT` / `MISS` vào response để dễ quan sát.
11. Cấu hình Redis qua biến môi trường (`REDIS_URL` hoặc `REDIS_HOST`/`REDIS_PASSWORD`…) trong env file của service, không hardcode.
12. Redis chết thì API vẫn phải trả dữ liệu từ DB (chỉ chậm hơn), không được trả `500`.
13. Đo thời gian response khi `MISS` và khi `HIT` (`curl -w '%{time_total}'`).

## Kết quả cần nộp
`devops-training/05-services/lab-01-redis/`:
- `NOTES.md`: các bước, output `ACL LIST` (che mật khẩu), kết quả test persistence, bảng đo HIT/MISS, kết quả khi tắt Redis
- `redis.conf` (phần đã thay đổi) / file ACL, code Flask đã sửa, `flaskapp.env.example`

## Tiêu chí đạt
- [ ] `redis-cli -h 192.168.56.11 ping` không có mật khẩu → bị từ chối (`NOAUTH`)
- [ ] User `flaskapp` không chạy được `FLUSHALL`, `KEYS *`, `CONFIG GET *`
- [ ] vm3 không kết nối được port `6379`
- [ ] Dữ liệu còn sau `kill -9` khi bật AOF
- [ ] Gọi `/api/employees` 2 lần liên tiếp: lần 1 `X-Cache: MISS`, lần 2 `X-Cache: HIT`
- [ ] Tắt Redis, API vẫn trả `200`

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. `protected-mode` hoạt động thế nào? Khi nào nó tự tắt tác dụng?
2. `requirepass` và ACL khác nhau thế nào? Vì sao ACL tốt hơn cho nhiều ứng dụng dùng chung Redis?
3. Vì sao `KEYS *` nguy hiểm trên production? Dùng gì thay thế?
4. `appendfsync always`, `everysec`, `no` — đánh đổi giữa hiệu năng và an toàn dữ liệu?
5. TTL 60 giây nghĩa là dữ liệu có thể "cũ" tối đa bao lâu? Làm sao xóa cache ngay khi dữ liệu thay đổi?
6. Cache stampede là gì? Khi key `employees:all` hết hạn đúng lúc có 1000 request cùng lúc thì sao?
7. `allkeys-lru` và `volatile-lru` khác nhau thế nào?

<details>
<summary>Gợi ý</summary>

- Thư viện Python: `redis` (`pip install redis`). Đặt `socket_connect_timeout` ngắn để Redis chết không làm treo API.
- Kết nối có user: `redis-cli -h 192.168.56.11 --user flaskapp --askpass`.
- ACL: tìm hiểu cú pháp `ACL SETUSER <user> on >password ~pattern +command`, và `aclfile` để lưu ACL ra file.
- Dữ liệu list nhân viên có thể lưu dạng JSON string (`json.dumps`).

</details>

## Tài liệu tham khảo
- https://redis.io/docs/latest/operate/oss_and_stack/management/security/
- https://redis.io/docs/latest/operate/oss_and_stack/management/security/acl/
- https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/
- https://redis.io/docs/latest/develop/reference/eviction/
- https://redis-py.readthedocs.io/
