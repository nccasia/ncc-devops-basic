# Lab 05 ⭐ — User & phân quyền cho ứng dụng (least privilege)

> **Module:** 02 Database

Bài này không bắt buộc để hoàn thành module nhưng **rất nên làm**: ở [Capstone](../../09-capstone/README.md) bạn phải tự thiết kế user và quyền cho database của ứng dụng mình và giải thích được thiết kế đó.

## Mục tiêu
- Thiết kế mô hình role cho một ứng dụng thực tế: tách quyền migrate (DDL), ứng dụng (DML), báo cáo (read-only), backup.
- Áp dụng nguyên tắc **least privilege**: mỗi role chỉ có đúng quyền cần thiết, trong đúng schema.
- Giới hạn tài nguyên theo role (connection limit, timeout).

## Kiến thức cần có
- Lab 01–03 của module này.
- Schema, owner, `GRANT/REVOKE`, `ALTER DEFAULT PRIVILEGES`, role membership (`INHERIT`), `search_path`.

## Môi trường
- vm1 (PostgreSQL server), vm2 (client).

## Yêu cầu

Ứng dụng "shop" dùng database `shopdb` với 2 schema: `app` (dữ liệu nghiệp vụ) và `audit` (log thao tác).

1. Tạo database `shopdb`, xóa/thu hồi schema `public` khỏi người dùng thường (`REVOKE ALL ON SCHEMA public FROM PUBLIC`), tạo schema `app` và `audit`.
2. Thiết kế các role sau (role nhóm `NOLOGIN` giữ quyền, user `LOGIN` là thành viên):

| Role nhóm | User đăng nhập | Quyền |
|-----------|----------------|-------|
| `shop_owner` | `shop_migrator` | Owner của schema `app`, `audit`; chạy migration (CREATE/ALTER/DROP) |
| `shop_rw` | `shop_app` | SELECT/INSERT/UPDATE/DELETE trên `app`; dùng sequence; **chỉ INSERT** vào `audit` (không sửa/xóa log) |
| `shop_ro` | `shop_report` | Chỉ SELECT trên `app`; không thấy `audit` |
| — | `shop_backup` | Đủ quyền để `pg_dump` toàn bộ `shopdb` nhưng không ghi được gì (gợi ý: predefined role `pg_read_all_data`, PostgreSQL ≥ 14) |

3. Dùng `shop_migrator` tạo vài bảng mẫu (`app.products`, `app.orders`, `audit.events` có cột `id` dạng `GENERATED ... AS IDENTITY` hoặc `SERIAL`). Quyền trên bảng mới phải **tự động** đúng với bảng trên (không GRANT tay sau mỗi lần migrate).
4. Giới hạn:
   - `shop_app`: tối đa 20 connection, `statement_timeout = 30s`.
   - `shop_report`: tối đa 5 connection, `statement_timeout = 5min`, `default_transaction_read_only = on`.
   - `search_path` mặc định của các user là `app`.
5. `pg_hba.conf`: `shop_app` chỉ từ vm2 (giả lập server app), `shop_report` từ vm2 và vm3, `shop_migrator` chỉ từ localhost của vm1, `shop_backup` chỉ qua `local`/localhost.
6. Viết `privileges-test.sql` (hoặc script bash gọi psql) chứng minh **ma trận quyền**: với mỗi user, thử SELECT/INSERT/UPDATE/DELETE/CREATE TABLE trên `app` và `audit`, ghi PASS nếu kết quả đúng kỳ vọng (được phép → thành công, không được phép → bị từ chối). Gợi ý cấu trúc: `DO $$ BEGIN ... EXCEPTION WHEN insufficient_privilege THEN ... END $$;`.
7. Viết `NOTES.md` giải thích như đang trình bày với team: vì sao tách các role này, app bị lộ password `shop_app` thì kẻ tấn công làm được gì và không làm được gì.

## Kết quả cần nộp
`devops-training/02-database/lab-05-users-and-privileges/`:
- `roles.sql`: tạo database, schema, role, quyền, default privileges, giới hạn (password qua biến psql)
- `privileges-test.sql` (hoặc `.sh`) và output chạy
- `pg_hba.conf` (các dòng liên quan)
- `NOTES.md`: ma trận quyền dạng bảng, giải thích thiết kế

## Tiêu chí đạt
- [ ] Không user nào là superuser hoặc có `CREATEROLE`/`CREATEDB` (trừ khi giải thích được)
- [ ] `shop_app` không tạo/xóa được bảng, không sửa/xóa được `audit.events`
- [ ] `shop_report` không ghi được và không đọc được `audit`
- [ ] Bảng mới do `shop_migrator` tạo tự có quyền đúng
- [ ] `shop_backup` dump được toàn bộ `shopdb`
- [ ] Giới hạn connection/timeout có hiệu lực (`SELECT rolname, rolconnlimit FROM pg_roles`, `\drds`)
- [ ] Test ma trận quyền chạy PASS toàn bộ

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Vì sao app không nên kết nối bằng user owner của bảng? Owner có những quyền ngầm định nào không thể REVOKE?
2. Vì sao tách user chạy migration và user chạy app? Trong CI/CD, user migrate nên được dùng ở đâu?
3. `INHERIT` và `NOINHERIT` khác nhau thế nào? `SET ROLE` dùng khi nào?
4. Vì sao cần quyền trên sequence/identity để INSERT? Lỗi gì nếu thiếu?
5. `ALTER ROLE ... SET statement_timeout` có hiệu lực với kết nối đang mở không?
6. Schema `public` mặc định có rủi ro gì (đặc biệt trước PostgreSQL 15)?
7. Nếu cần cấp quyền read-only cho một bên thứ ba nhưng ẩn cột `salary`/`email`, bạn làm thế nào? (gợi ý: view, column privilege, row level security)

<details>
<summary>Gợi ý</summary>

- Default privileges gắn với role **tạo** object: `ALTER DEFAULT PRIVILEGES FOR ROLE shop_owner IN SCHEMA app GRANT ... TO shop_rw;` — và migrator phải tạo bảng với tư cách `shop_owner` (`SET ROLE shop_owner` hoặc `ALTER ROLE shop_migrator SET role = 'shop_owner'`).
- `\drds` xem setting theo role/database.
- Thử từng user nhanh: `psql "host=... user=shop_app dbname=shopdb" -c '...'`.

</details>

## Tài liệu tham khảo
- https://www.postgresql.org/docs/current/user-manag.html
- https://www.postgresql.org/docs/current/ddl-schemas.html
- https://www.postgresql.org/docs/current/predefined-roles.html
- https://www.postgresql.org/docs/current/ddl-rowsecurity.html
