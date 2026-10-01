# Lab 04 — Backup & Restore

> **Module:** 02 Database

## Mục tiêu
- Backup và restore database bằng công cụ logic (`pg_dump`, `pg_restore`, `pg_dumpall`).
- Tự động hóa backup định kỳ có retention, kiểm tra backup hợp lệ.
- Thực hành restore — vì backup chưa từng restore thử thì chưa phải backup.
- ⭐ Làm quen backup vật lý: PITR hoặc streaming replication.

## Kiến thức cần có
- Lab 01–03 của module này.
- BT5 ([01-linux/lab-04](../../01-linux/lab-04-bash-scripting/README.md)) và systemd timer ([01-linux/lab-06](../../01-linux/lab-06-systemd-service/README.md)).

## Môi trường
- vm1 (PostgreSQL server). Phần ⭐ dùng thêm vm2 làm replica.

## Yêu cầu

### Phần 1 — Backup & restore thủ công
1. Backup `trainingdb` theo 3 định dạng: plain SQL (`-Fp`), custom (`-Fc`), directory (`-Fd -j 2`). So sánh kích thước, thời gian, khả năng restore chọn lọc.
2. Backup **chỉ schema** và **chỉ dữ liệu** của bảng `employees`.
3. Backup các đối tượng toàn cluster (role, tablespace) bằng `pg_dumpall --globals-only`. Giải thích vì sao `pg_dump` một database không chứa role.
4. Restore bản custom vào database mới `trainingdb_restore`. So sánh số dòng từng bảng giữa 2 database.
5. Giả lập sự cố: `DELETE FROM employees WHERE department_id = 2;` trên `trainingdb`. Khôi phục **chỉ bảng `employees`** từ backup mà không ảnh hưởng bảng khác (gợi ý: `pg_restore -t` / `-l` + `-L`). Ghi lại các bước, lưu ý ràng buộc khóa ngoại.

### Phần 2 — Backup tự động
6. Viết `pg-backup.sh`:
   - Tham số: database (một hoặc `all`), thư mục đích, số ngày giữ (mặc định 7).
   - Chạy bằng user hệ thống `postgres` (peer auth) hoặc user backup riêng có quyền tối thiểu — **không** để password trong script.
   - Tên file: `<db>_<YYYYmmdd_HHMMSS>.dump` (custom format) + file `globals_<timestamp>.sql`.
   - Kiểm tra backup hợp lệ ngay sau khi tạo (`pg_restore -l` đọc được), ghi checksum.
   - Xóa backup quá hạn (chỉ file đúng pattern).
   - Ghi log, exit code ≠ 0 khi lỗi, gửi thông báo khi lỗi (tái sử dụng cách gửi của BT5).
   - Thư mục backup quyền `700`, file `600`, owner `postgres`.
7. Chạy `pg-backup.sh` hằng ngày lúc 01:30 bằng **systemd timer** (hoặc cron — nêu lý do chọn).
8. Viết `pg-restore-test.sh`: lấy bản backup mới nhất, restore vào database tạm `restore_test_<timestamp>`, chạy vài query kiểm tra (đếm dòng), in PASS/FAIL, rồi xóa database tạm. Đây là cách kiểm tra backup định kỳ.
9. ⭐ Đẩy bản backup sang máy khác (vm2) bằng `rsync` qua SSH key — giải thích vì sao backup để cùng máy với DB là chưa đủ (quy tắc 3-2-1).

### Phần 3 — ⭐ Backup vật lý (chọn 1)
10. **PITR**: bật WAL archiving, tạo base backup bằng `pg_basebackup`, ghi dữ liệu, ghi lại thời điểm T, xóa nhầm dữ liệu, khôi phục cluster về đúng thời điểm T (`recovery_target_time`).
11. **Streaming replication**: dựng vm2 làm hot standby của vm1 (`pg_basebackup -R`), chứng minh dữ liệu ghi ở vm1 xuất hiện ở vm2, vm2 chỉ đọc. Kiểm tra `pg_stat_replication`. Giải thích vì sao replica **không thay thế** backup.

### Ghi chú MySQL
| PostgreSQL | MySQL |
|------------|-------|
| `pg_dump -Fc db` | `mysqldump --single-transaction --routines --triggers db` |
| `pg_dumpall --globals-only` | `mysqldump mysql` / `SHOW GRANTS` / `mysqlpump --users` |
| `pg_restore` | `mysql db < dump.sql` |
| WAL + PITR | binlog + `mysqlbinlog --stop-datetime` |
| `pg_basebackup -R` | `CHANGE REPLICATION SOURCE TO ...` / Percona XtraBackup |

## Kết quả cần nộp
`devops-training/02-database/lab-04-backup-restore/`:
- `pg-backup.sh`, `pg-restore-test.sh`
- `pg-backup.service`, `pg-backup.timer` (hoặc `crontab.txt`)
- `NOTES.md`: bảng so sánh 3 định dạng, các bước khôi phục bảng `employees`, output `pg-restore-test.sh`, output `systemctl list-timers`, (⭐) các bước PITR/replication.

## Tiêu chí đạt
- [ ] Restore thành công vào database mới, số dòng khớp
- [ ] Khôi phục được riêng bảng `employees` sau khi xóa nhầm
- [ ] Backup tự động chạy theo lịch, có retention, file quyền `600`
- [ ] `pg-restore-test.sh` PASS trên bản backup mới nhất
- [ ] Không có password trong script/unit file
- [ ] Có thông báo khi backup lỗi (tự làm lỗi để kiểm chứng, VD sai tên database)

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. `pg_dump` có khóa bảng không? Dữ liệu trong dump có nhất quán khi đang có giao dịch ghi không? Vì sao?
2. Plain SQL, custom, directory format khác nhau thế nào? Khi nào dùng loại nào?
3. RPO và RTO là gì? Backup hằng ngày lúc 01:30 thì RPO tối đa là bao nhiêu? Muốn RPO vài phút thì cần gì?
4. Backup logic và backup vật lý khác nhau thế nào? Có restore một bản `pg_basebackup` sang PostgreSQL major version khác được không?
5. Quy tắc backup 3-2-1 là gì?
6. Replica có thay thế backup được không? Nêu tình huống replica không cứu được dữ liệu.
7. Backup chứa dữ liệu nhạy cảm (lương, email) — cần bảo vệ thế nào (quyền file, mã hóa, nơi lưu)?
8. Làm sao biết backup đêm qua có chạy và có dùng được không mà không cần đăng nhập server?

<details>
<summary>Gợi ý</summary>

- `pg_restore -l backup.dump > list.txt` → sửa danh sách → `pg_restore -L list.txt ...`.
- Restore một bảng có khóa ngoại: cân nhắc `--data-only` + xóa dữ liệu cũ của bảng trước, hoặc restore vào database tạm rồi `INSERT ... SELECT` qua `dblink`/`postgres_fdw`, hoặc `\copy`.
- Chạy lệnh bằng user postgres trong script: `sudo -u postgres pg_dump ...` hoặc đặt `User=postgres` trong service.
- Thời điểm T cho PITR: `SELECT now();` ngay trước khi xóa nhầm.

</details>

## Tài liệu tham khảo
- https://www.postgresql.org/docs/current/backup.html
- https://www.postgresql.org/docs/current/app-pgdump.html
- https://www.postgresql.org/docs/current/app-pgrestore.html
- https://www.postgresql.org/docs/current/continuous-archiving.html
- https://www.postgresql.org/docs/current/warm-standby.html
