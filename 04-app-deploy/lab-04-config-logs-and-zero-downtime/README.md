# Lab 04 ⭐ — Config, Logs, Releases & Rollback

> **Module:** 04 Deploy App Server · **Không bắt buộc** (rất nên làm trước Capstone)

## Mục tiêu
- Tách biệt code, config và secret; một artifact chạy được ở nhiều môi trường.
- Quản lý log: journald, log file của app, log rotation.
- Deploy nhiều version theo mô hình `releases/` + symlink `current`, rollback trong vài giây.
- Giảm downtime khi deploy.

## Kiến thức cần có
- Ít nhất 1 trong lab 01–03 của module này đã chạy ổn định.

## Môi trường
- vm2, dùng app đã deploy ở lab 01 (Flask) — hoặc app .NET/Spring tương ứng.

## Yêu cầu

### Phần A — Config & secret
1. Liệt kê toàn bộ config của app, phân loại: config không nhạy cảm (port, số worker, log level) và secret (DB password).
2. Tách thành 2 file: `/etc/<app>/<app>.env` (config) và `/etc/<app>/<app>.secret.env` (secret, quyền chặt hơn). Unit file nạp cả hai.
3. ⭐ Dùng `systemd-creds` hoặc `LoadCredential=` để truyền DB password thay vì biến môi trường. Giải thích vì sao env var không phải nơi lý tưởng cho secret.

### Phần B — Logs
4. Cấu hình journald giới hạn dung lượng (`SystemMaxUse`) và kiểm tra bằng `journalctl --disk-usage`.
5. Cấu hình access log của gunicorn (hoặc app khác) ghi ra `/var/log/<app>/access.log`. Viết cấu hình **logrotate**: xoay vòng hằng ngày, giữ 7 bản, nén, app không mất log sau khi rotate. Test bằng `logrotate -f`.
6. Viết lệnh/script lọc nhanh: lỗi 5xx trong 1 giờ gần nhất, log của service từ lần boot trước (`journalctl -b -1`).

### Phần C — Releases & rollback
7. Cấu trúc thư mục:
   ```
   /opt/<app>/
   ├── releases/
   │   ├── 20261001-0900-a1b2c3d/
   │   └── 20261002-1400-e4f5a6b/
   ├── shared/          # venv dùng chung hoặc file dùng chung giữa các release (nếu có)
   └── current -> releases/20261002-1400-e4f5a6b
   ```
   Unit file trỏ vào `/opt/<app>/current`.
8. Viết `deploy.sh <source-dir|artifact>`: tạo release mới (tên = timestamp + git short SHA hoặc version), cài dependencies, chạy smoke test trên port tạm, chuyển symlink **atomic**, restart/reload service, kiểm tra `/health`; nếu fail → tự quay về release cũ.
9. Viết `rollback.sh [release]`: không tham số → về release liền trước; có tham số → về release chỉ định.
10. Giữ tối đa 5 release gần nhất, tự dọn bản cũ.
11. ⭐ Zero downtime: dùng `systemctl reload` (gunicorn nhận `HUP` để reload worker) hoặc chạy 2 instance trên 2 port + Nginx upstream để chuyển đổi. Chứng minh bằng vòng lặp `curl` liên tục trong lúc deploy không có request lỗi.

## Kết quả cần nộp
`devops-training/04-app-deploy/lab-04-config-logs-and-zero-downtime/`:
- `NOTES.md`: giải thích thiết kế, output deploy thành công / deploy lỗi tự rollback / rollback thủ công, kết quả test downtime
- `deploy.sh`, `rollback.sh`, unit file, file logrotate, `journald.conf` drop-in

## Tiêu chí đạt
- [ ] Secret tách riêng, quyền chặt hơn config thường
- [ ] logrotate chạy được, app tiếp tục ghi log sau khi rotate
- [ ] `deploy.sh` tạo release mới và chuyển `current` atomic (`ln -sfn` + `mv -T` hoặc tương đương)
- [ ] Deploy một bản lỗi (VD `/health` trả 500) → script tự rollback, service vẫn chạy bản cũ
- [ ] `rollback.sh` hoạt động trong < 10 giây
- [ ] Chỉ giữ 5 release gần nhất

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Vì sao `ln -sfn` chưa thật sự atomic? Cách nào atomic hoàn toàn?
2. Vì sao lưu secret trong biến môi trường có rủi ro (`/proc/<pid>/environ`, log crash, child process)?
3. logrotate có 2 cách để app ghi tiếp sau khi rotate: `copytruncate` và `postrotate` gửi signal. So sánh.
4. Release có chứa migration DB thì rollback code có đủ không? Nguyên tắc migration tương thích ngược (expand/contract)?
5. `systemctl reload` khác `restart` với gunicorn thế nào? App .NET/Java có reload được không?
6. Đặt tên release theo timestamp, version semver hay git SHA — ưu nhược điểm?

<details>
<summary>Gợi ý</summary>

- Atomic symlink: tạo symlink tạm `current.tmp` rồi `mv -T current.tmp current`.
- gunicorn: `ExecReload=/bin/kill -s HUP $MAINPID`; tìm hiểu `--preload` ảnh hưởng thế nào tới reload code.
- Smoke test trước khi chuyển symlink: chạy release mới trên port tạm (VD `5099`), `curl /health`, rồi dừng.
- `journalctl -u <app> --since "1 hour ago" -p err`.

</details>

## Tài liệu tham khảo
- https://www.freedesktop.org/software/systemd/man/systemd.exec.html#Credentials
- https://linux.die.net/man/8/logrotate
- https://docs.gunicorn.org/en/stable/signals.html
- https://capistranorb.com/documentation/getting-started/structure/ (mô hình releases/current kinh điển)
