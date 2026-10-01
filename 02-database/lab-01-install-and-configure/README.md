# Lab 01 — Cài đặt & cấu hình PostgreSQL

> **Module:** 02 Database

## Mục tiêu
- Cài PostgreSQL từ repository, quản lý service bằng systemd.
- Biết vị trí file cấu hình, thư mục data, log.
- Tạo role owner, database và nạp dữ liệu mẫu.
- Dùng `psql` thành thạo ở mức cơ bản.

## Kiến thức cần có
- Module [01-linux](../../01-linux/README.md) (systemd, user, permission).
- SQL cơ bản.

## Môi trường
- vm1 (192.168.56.11). Snapshot VM trước khi bắt đầu (`vagrant snapshot save vm1 before-db`).

## Yêu cầu

### Phần 1 — Cài đặt
1. Cài PostgreSQL (bản 16 từ repo chính thức `apt.postgresql.org`, hoặc bản mặc định của Ubuntu — ghi rõ chọn bản nào, vì sao).
2. Kiểm tra service: trạng thái, enable khi boot, process, port đang listen.
3. Tìm và ghi lại đường dẫn: `postgresql.conf`, `pg_hba.conf`, thư mục data (`data_directory`), file log. Gợi ý: `SHOW config_file;`, `SHOW data_directory;`, `pg_lsclusters`.

### Phần 2 — Role & database
4. Tạo role `training_owner` (LOGIN, có password, **không** phải superuser, không `CREATEROLE`).
5. Tạo database `trainingdb` với owner là `training_owner`, encoding `UTF8`.
6. Thu hồi quyền mặc định `CONNECT` và `CREATE` trên database/schema `public` của `PUBLIC` (giải thích vì sao — tham khảo thay đổi từ PostgreSQL 15).
7. Nạp dữ liệu mẫu bằng [`starter/seed.sql`](starter/seed.sql) **bằng user `training_owner`** qua TCP (`-h localhost`), không dùng `postgres`.

### Phần 3 — Cấu hình cơ bản
Sửa `postgresql.conf` (ghi lại giá trị cũ → mới và lý do):
8. `listen_addresses`: lắng nghe trên `localhost` và IP private của vm1 (`192.168.56.11`) — **không** dùng `*` ở bài này. Giải thích khác biệt.
9. `port` giữ `5432` (ghi chú: nếu đổi port thì những chỗ nào phải đổi theo?).
10. Logging: bật `log_connections`, `log_disconnections`, `log_line_prefix` có thời gian, user, database, IP client; `log_min_duration_statement = 500ms`.
11. `password_encryption = scram-sha-256`.
12. Áp dụng cấu hình. Thay đổi nào cần `restart`, thay đổi nào chỉ cần `reload`? (gợi ý: cột `context` trong `pg_settings`).

### Phần 4 — psql cơ bản
13. Với `psql`, thực hiện và ghi lại output: liệt kê database, role, bảng; xem cấu trúc bảng `employees`; xem quyền trên bảng (`\dp`); bật hiển thị dọc `\x`; truy vấn danh sách nhân viên kèm tên phòng ban (JOIN); đếm nhân viên đang active theo phòng ban.
14. Tạo file `~/.pgpass` để `training_owner` kết nối không cần gõ password. Quyền file phải là gì?

### Ghi chú MySQL
| PostgreSQL | MySQL tương đương |
|------------|-------------------|
| `postgresql.conf` | `/etc/mysql/mysql.conf.d/mysqld.cnf` |
| `listen_addresses` | `bind-address` |
| `CREATE ROLE ... LOGIN` | `CREATE USER 'u'@'host' IDENTIFIED BY ...` |
| `\l`, `\dt`, `\du` | `SHOW DATABASES;`, `SHOW TABLES;`, `SELECT user,host FROM mysql.user;` |
| `~/.pgpass` | `~/.my.cnf` (section `[client]`) |
| `mysql_secure_installation` | (không có — tự thu hồi quyền `PUBLIC`) |

Với MySQL cần chuyển `seed.sql`: `SERIAL` → `INT AUTO_INCREMENT`, `TIMESTAMPTZ` → `TIMESTAMP`, bỏ `BEGIN/COMMIT` hoặc dùng `START TRANSACTION`.

## Kết quả cần nộp
`devops-training/02-database/lab-01-install-and-configure/`:
- `install.sh`: cài đặt + tạo role/database + nạp seed (password đọc từ biến môi trường, không hardcode).
- `postgresql.conf.diff`: chỉ phần thay đổi (`diff -u` bản gốc và bản sửa).
- `NOTES.md`: đường dẫn file, giải thích cấu hình, output psql Phần 4, đoạn log có `connection authorized`.

## Tiêu chí đạt
- [ ] Service `active`, enabled, listen `127.0.0.1:5432` và `192.168.56.11:5432` (`ss -tlnp`)
- [ ] `training_owner` không phải superuser, là owner của `trainingdb`
- [ ] Dữ liệu mẫu có đủ 5 departments, 10 employees
- [ ] Log ghi được kết nối, có IP client
- [ ] `.pgpass` quyền `600`, không commit lên repo

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Cluster, database, schema trong PostgreSQL là gì? Một cluster có thể có bao nhiêu database?
2. Role và user khác nhau thế nào trong PostgreSQL?
3. Vì sao `sudo -u postgres psql` vào được không cần password, còn `psql -h localhost -U postgres` lại hỏi password?
4. `listen_addresses = '*'` khác `'localhost,192.168.56.11'` thế nào? Vì sao thay đổi này cần restart?
5. Owner của database có toàn quyền trên các bảng trong đó không? Owner của bảng thì sao?
6. `PUBLIC` là gì? Vì sao nên thu hồi quyền của `PUBLIC`?
7. `scram-sha-256` tốt hơn `md5` ở điểm nào?

<details>
<summary>Gợi ý</summary>

- Trên Ubuntu, file cấu hình nằm ở `/etc/postgresql/<version>/main/`, data ở `/var/lib/postgresql/<version>/main/`.
- `SELECT name, setting, context FROM pg_settings WHERE name IN (...)`.
- Định dạng `.pgpass`: `hostname:port:database:username:password`.

</details>

## Tài liệu tham khảo
- https://www.postgresql.org/download/linux/ubuntu/
- https://www.postgresql.org/docs/current/runtime-config.html
- https://www.postgresql.org/docs/current/app-psql.html
- https://www.postgresql.org/docs/current/libpq-pgpass.html
