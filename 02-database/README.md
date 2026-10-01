# 02 — Database Server (PostgreSQL / MySQL)

> **Môi trường:** [lab-env](../lab-env/README.md) — vm1 (server), vm2, vm3 (client)

Chọn **một** trong hai: PostgreSQL (khuyến nghị, đề bài viết theo PostgreSQL) hoặc MySQL. Mỗi lab có mục *Ghi chú MySQL* cho lệnh/file tương đương. Nếu chọn MySQL, thay tên user/database/file cấu hình tương ứng và ghi rõ trong `NOTES.md`.

## Mục tiêu

Sau module này bạn sẽ:
- Cài đặt, cấu hình và vận hành một database server trên Linux.
- Quản lý role/user, phân quyền theo nguyên tắc **least privilege** (read-only, read-write theo schema).
- Cấu hình remote access an toàn: listen address, xác thực theo host (`pg_hba.conf`), firewall — và hiểu sự khác nhau giữa các lớp chặn.
- Backup, restore, backup tự động có retention.

## Lý thuyết cần tự học

- PostgreSQL Tutorial: https://www.postgresql.org/docs/current/tutorial.html
- Server Administration — các chương: *Server Configuration*, *Client Authentication* (`pg_hba.conf`), *Database Roles*, *Backup and Restore*: https://www.postgresql.org/docs/current/admin.html
- Privileges: https://www.postgresql.org/docs/current/ddl-priv.html
- MySQL (nếu chọn): https://dev.mysql.com/doc/refman/8.0/en/ — *Access Control and Account Management*, *Backup and Recovery*.

Checklist kiến thức:
- [ ] Kiến trúc client–server, port mặc định (5432 / 3306), process `postgres`/`mysqld`
- [ ] Cluster, database, schema, table; role vs user
- [ ] `psql` cơ bản: `\l \c \dn \dt \du \dp \x \q`
- [ ] SQL cơ bản: `CREATE/ALTER/DROP`, `SELECT/INSERT/UPDATE/DELETE`, `JOIN`
- [ ] `GRANT/REVOKE`, `ALTER DEFAULT PRIVILEGES`, owner của object
- [ ] `postgresql.conf` (`listen_addresses`, `port`, `max_connections`, logging), `pg_hba.conf`
- [ ] Phương thức xác thực: `peer`, `scram-sha-256`, `md5`, `trust`, `reject`
- [ ] Backup logic (`pg_dump`, `pg_dumpall`) vs physical (`pg_basebackup`), WAL, PITR, replication (khái niệm)

## Danh sách lab

| Lab | Nội dung | Bắt buộc |
|-----|----------|----------|
| [lab-01-install-and-configure](lab-01-install-and-configure/README.md) | Cài đặt, cấu hình, tạo database & dữ liệu mẫu | ✅ |
| [lab-02-readonly-remote-access](lab-02-readonly-remote-access/README.md) | Yêu cầu 1: user read-only, kết nối từ VM2 | ✅ |
| [lab-03-restrict-by-ip](lab-03-restrict-by-ip/README.md) | Yêu cầu 2: chỉ VM2 được kết nối, VM3 bị chặn | ✅ |
| [lab-04-backup-restore](lab-04-backup-restore/README.md) | Backup/restore, backup định kỳ, retention | ✅ (phần ⭐ không bắt buộc) |
| [lab-05-users-and-privileges](lab-05-users-and-privileges/README.md) | Role cho ứng dụng, least privilege — chuẩn bị cho capstone | ⭐ (khuyến khích mạnh) |

Mô hình chung:

```
            ┌───────────────────────────┐
            │ vm1 192.168.56.11         │
            │ PostgreSQL Server :5432   │
            └─────────────▲─────────────┘
          được phép  │            ✗ bị chặn (lab-03)
     ┌───────────────┴───┐   ┌───────────────────┐
     │ vm2 192.168.56.12 │   │ vm3 192.168.56.13 │
     │ psql client       │   │ psql client       │
     └───────────────────┘   └───────────────────┘
```

## Câu hỏi tự kiểm tra cuối module
Tự trả lời, ghi vào một file `devops-training/<module>/NOTES.md`. Câu nào chưa trả lời được thì quay lại lý thuyết/lab tương ứng.

1. Một client không kết nối được DB — liệt kê theo thứ tự các điểm cần kiểm tra (từ network tới quyền trên bảng).
2. `listen_addresses`, `pg_hba.conf`, firewall — mỗi cái kiểm soát điều gì? Thiếu một trong ba thì lỗi phía client hiển thị thế nào?
3. `pg_hba.conf` được đọc theo thứ tự nào? Sửa xong cần `reload` hay `restart`? Còn `listen_addresses`?
4. `GRANT SELECT ON ALL TABLES IN SCHEMA` có áp dụng cho bảng tạo sau không? Vì sao user read-only vẫn bị `permission denied for schema`?
5. Vì sao app không nên dùng user `postgres` (superuser) hay owner của database để kết nối?
6. `peer` authentication là gì? Vì sao `sudo -u postgres psql` vào được mà không cần password?
7. `pg_dump` có làm khóa database không? Dump có nhất quán khi đang có ghi dữ liệu không?
8. Backup logic và physical khác nhau thế nào? Khi nào cần PITR?
9. Backup chưa từng test restore có được coi là backup không? Cách kiểm tra backup định kỳ?
10. Có nên mở port 5432 ra Internet không? Nếu bắt buộc remote, có những cách nào an toàn hơn (VPN, SSH tunnel, TLS, allowlist IP)?

## Bài tự luyện debug (break & fix)

Chụp snapshot vm1 trước (`vagrant snapshot save vm1 before-break`). **Tự cố tình làm hỏng** từng mục dưới đây (mỗi lần một lỗi), thử kết nối từ vm2 như một ứng dụng bình thường, tự chẩn đoán và sửa. Ghi vào `devops-training/02-database/BREAK-FIX.md` theo bảng: **Lỗi đã cài → Triệu chứng (thông báo lỗi phía client) → Cách chẩn đoán (lệnh, log server) → Nguyên nhân → Cách sửa**.

- `listen_addresses = 'localhost'` rồi restart → vm2 nhận `Connection refused`.
- Xóa dòng cho vm2 trong `pg_hba.conf` (hoặc thêm một dòng `reject` lên trước) → `no pg_hba.conf entry for host ...` / `pg_hba.conf rejects connection`.
- Sửa `pg_hba.conf` đúng nhưng **không** reload → "đã sửa mà vẫn lỗi".
- `ufw deny 5432` → client bị timeout.
- `REVOKE USAGE ON SCHEMA public FROM usertest1` → `permission denied for schema public`.
- Tạo bảng mới bằng một role không nằm trong `ALTER DEFAULT PRIVILEGES` → user read-only không đọc được bảng mới.
- Đổi password user nhưng client vẫn dùng password cũ trong `~/.pgpass`; hoặc đặt quyền `.pgpass` là `644` → file bị bỏ qua (đọc cảnh báo).
- Đổi owner thư mục data (`chown -R root /var/lib/postgresql/<version>/main`) → PostgreSQL không start, đọc `journalctl -u postgresql@*` và log PostgreSQL.

Xong thì `vagrant snapshot restore vm1 before-break`.
