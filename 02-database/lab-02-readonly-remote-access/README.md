# Lab 02 — User read-only & kết nối từ xa (Yêu cầu 1)

> **Module:** 02 Database

## Mục tiêu
- Tạo user chỉ có quyền đọc dữ liệu, hiểu đầy đủ các lớp quyền cần thiết (database → schema → table).
- Cấu hình PostgreSQL cho phép client ở máy khác kết nối.
- Chứng minh quyền read-only bằng thử nghiệm thực tế, không chỉ "nhìn config".

## Kiến thức cần có
- Hoàn thành [lab-01](../lab-01-install-and-configure/README.md): có `trainingdb`, owner `training_owner`, dữ liệu mẫu, `listen_addresses` có IP private.
- `GRANT`, `REVOKE`, `ALTER DEFAULT PRIVILEGES`, `pg_hba.conf`.

## Môi trường

Bài tập: Setup Database và Networking với PostgreSQL. Mô hình:
- **VM1** (192.168.56.11): cài đặt PostgreSQL Server
- **VM2** (192.168.56.12): cài đặt PostgreSQL Client
- **VM3** (192.168.56.13): cài đặt PostgreSQL Client

Trên vm2, vm3 chỉ cài client: `sudo apt-get install -y postgresql-client`.

## Yêu cầu

### Yêu cầu 1 — Kết nối cơ bản & phân quyền read-only

1. Tạo `usertest1` **read-only** để SELECT data từ PostgreSQL database `trainingdb` của VM1:
   - Có quyền `CONNECT` database, `USAGE` schema `public`, `SELECT` trên **tất cả bảng hiện có**.
   - Bảng được `training_owner` **tạo sau này** cũng tự động SELECT được.
   - Được đọc sequence nếu cần (nghĩ xem có cần không).
   - ⭐ Làm theo cách "đúng chuẩn": tạo role nhóm `readonly` (NOLOGIN) giữ quyền, `usertest1` chỉ là thành viên của role đó. Giải thích lợi ích.
2. Trên PostgreSQL Server của VM1, cấu hình để từ VM2 có thể:
   - Kết nối đến PostgreSQL Server trên VM1 bằng user `usertest1` (xác thực bằng password, `scram-sha-256`).
   - Thực hiện truy vấn `SELECT` và đọc được dữ liệu từ database trên VM1.
3. Chứng minh (chạy từ **vm2**, ghi lại lệnh và output):
   - `psql -h 192.168.56.11 -U usertest1 -d trainingdb -c 'SELECT count(*) FROM employees;'` → thành công.
   - `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, `CREATE TABLE`, `DROP TABLE` đều bị từ chối — ghi lại thông báo lỗi từng lệnh.
   - `training_owner` tạo bảng mới `projects` → `usertest1` SELECT được ngay, không cần GRANT lại.
   - `usertest1` không kết nối được database khác (VD `postgres`) — nếu được thì giải thích vì sao và sửa.
4. Từ vm2 kiểm tra kết nối có được mã hóa không (`\conninfo`, `SELECT ssl FROM pg_stat_ssl WHERE pid = pg_backend_pid();`). ⭐ Bật SSL cho server (dùng cert self-signed) và bắt buộc `hostssl` cho usertest1.

Ở bài này chưa cần chặn VM3 — việc đó thuộc [lab-03](../lab-03-restrict-by-ip/README.md). Ghi lại hiện trạng: từ vm3 có kết nối được bằng usertest1 không? Vì sao?

### Ghi chú MySQL
- Tạo user theo host: `CREATE USER 'usertest1'@'192.168.56.%' IDENTIFIED BY '...';`
- `GRANT SELECT ON trainingdb.* TO 'usertest1'@'192.168.56.%';` — `db.*` tự áp cho bảng tạo sau (khác PostgreSQL, giải thích vì sao).
- `bind-address = 192.168.56.11` trong `mysqld.cnf`. Không có `pg_hba.conf` — host được kiểm soát qua phần `@'host'` của account.

## Kết quả cần nộp
`devops-training/02-database/lab-02-readonly-remote-access/`:
- `readonly.sql`: toàn bộ lệnh SQL tạo role/user/quyền (password dùng biến psql `:'pw'`, không hardcode).
- `pg_hba.conf.diff`, `postgresql.conf.diff` (nếu có thay đổi thêm).
- `NOTES.md`: output các thử nghiệm ở bước 3–4, output `\dp` và `\ddp`, trả lời câu hỏi về vm3.

## Tiêu chí đạt
- [ ] Từ vm2 SELECT được bằng usertest1 qua mạng (`-h 192.168.56.11`)
- [ ] Mọi lệnh ghi/DDL đều bị từ chối
- [ ] Bảng tạo mới bởi `training_owner` tự động đọc được
- [ ] usertest1 không phải superuser, không có quyền nào ngoài đọc
- [ ] Không dùng `trust` trong `pg_hba.conf`
- [ ] Không có password trong file nộp

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Liệt kê đủ các quyền cần cấp để một user đọc được bảng: cấp database, schema, table. Thiếu `USAGE` trên schema thì lỗi gì?
2. `GRANT SELECT ON ALL TABLES IN SCHEMA public` khác `ALTER DEFAULT PRIVILEGES ... GRANT SELECT ON TABLES` thế nào?
3. `ALTER DEFAULT PRIVILEGES` áp dụng cho bảng do **ai** tạo? Nếu một role khác tạo bảng thì sao?
4. Vì sao user mới tạo mặc định có thể `CONNECT` mọi database? Cách tắt?
5. Ý nghĩa từng cột trong một dòng `pg_hba.conf`: `TYPE DATABASE USER ADDRESS METHOD`. `host` khác `hostssl` khác `local`?
6. Một user read-only có thể gây hại cho hệ thống không? (gợi ý: query nặng, `pg_sleep`, đọc dữ liệu nhạy cảm như `salary`) — cách giảm rủi ro?
7. Vì sao nên cấp quyền cho role nhóm rồi gán user vào thay vì cấp trực tiếp cho user?

<details>
<summary>Gợi ý</summary>

- Kiểm tra quyền hiện có: `\dp` (table), `\dn+` (schema), `\l` (database), `\ddp` (default privileges).
- `ALTER DEFAULT PRIVILEGES FOR ROLE training_owner IN SCHEMA public ...` — chú ý `FOR ROLE`.
- Đọc log PostgreSQL trên vm1 khi vm2 kết nối lỗi — log server thường nói rõ hơn lỗi phía client.
- Truyền password an toàn vào script SQL: `psql -v pw="$PW" -f readonly.sql`, trong file dùng `PASSWORD :'pw'`.

</details>

## Tài liệu tham khảo
- https://www.postgresql.org/docs/current/ddl-priv.html
- https://www.postgresql.org/docs/current/sql-alterdefaultprivileges.html
- https://www.postgresql.org/docs/current/auth-pg-hba-conf.html
- https://www.postgresql.org/docs/current/predefined-roles.html (`pg_read_all_data`)
