# Lab 06 — systemd service & timer

> **Module:** 01 Linux

## Mục tiêu
- Viết unit file để chạy một ứng dụng như service: user riêng, tự khởi động cùng hệ thống, tự restart khi crash.
- Đọc log bằng `journalctl`.
- Dùng systemd timer thay cho cron.
- Đây là nền tảng cho module [04-app-deploy](../../04-app-deploy/README.md).

## Kiến thức cần có
- `systemctl start/stop/restart/status/enable/disable/daemon-reload`, `journalctl -u -f --since`.
- Cấu trúc unit file: `[Unit]`, `[Service]`, `[Install]`; `Type=`, `ExecStart=`, `User=`, `Restart=`, `WorkingDirectory=`, `Environment=`/`EnvironmentFile=`.
- Đã làm BT5 ở [lab-04](../lab-04-bash-scripting/README.md).

## Môi trường
- vm1.

## Yêu cầu

### Phần 1 — Service cho một app đơn giản
1. Viết script `/opt/heartbeat/heartbeat.sh`: cứ mỗi 10 giây ghi ra stdout một dòng `heartbeat <timestamp> <hostname>`; đọc biến môi trường `HEARTBEAT_INTERVAL` (mặc định 10) và `HEARTBEAT_MESSAGE`. Khi nhận `SIGTERM` in `shutting down` rồi thoát exit code 0.
2. Tạo **system user** `heartbeat` (không login được, không có home cần thiết). Script và thư mục thuộc root, user heartbeat chỉ có quyền đọc/thực thi.
3. Viết `/etc/systemd/system/heartbeat.service`:
   - Chạy bằng user `heartbeat`.
   - Biến môi trường lấy từ `/etc/heartbeat/heartbeat.env`.
   - `Restart=on-failure`, `RestartSec=5`.
   - Khởi động cùng hệ thống, sau khi network sẵn sàng.
4. Kiểm chứng và ghi lại output:
   - `systemctl status heartbeat` đang `active (running)`, process chạy bằng user `heartbeat` (`ps -o user,pid,cmd -C heartbeat.sh` hoặc tương đương).
   - `journalctl -u heartbeat -f` thấy log.
   - `kill -9 <pid>` → service tự restart sau 5 giây. `systemctl stop` → **không** restart (giải thích vì sao).
   - Reboot VM → service tự chạy lại.
   - Đổi `HEARTBEAT_INTERVAL=3` trong env file → áp dụng (cần lệnh gì?).
5. Thêm hardening cơ bản và giải thích từng dòng: `NoNewPrivileges=yes`, `ProtectSystem=strict`, `ProtectHome=yes`, `PrivateTmp=yes`. Chạy `systemd-analyze security heartbeat` trước/sau, so sánh điểm.

### Phần 2 — Timer thay cron cho script backup (BT5)
6. Tạo `backup.service` (`Type=oneshot`) chạy `bt5-backup.sh` backup `/projects` (hoặc thư mục tùy chọn) vào `/var/backups/projects`.
7. Tạo `backup.timer` chạy hằng ngày lúc 02:00, `Persistent=true`, `RandomizedDelaySec=10min`.
8. Kiểm chứng: `systemctl list-timers`, chạy thử ngay `systemctl start backup.service`, xem log bằng `journalctl -u backup.service`.
9. So sánh systemd timer với cron (ít nhất 4 điểm) trong `NOTES.md`.

### Phần 3 — ⭐ Service bị lỗi
10. Tự tạo 3 lỗi trong unit file (VD: `ExecStart` đường dẫn tương đối, `User=` không tồn tại, script không có quyền thực thi), ghi lại thông báo lỗi trong `systemctl status`/`journalctl` và cách đọc ra nguyên nhân.

## Kết quả cần nộp
`devops-training/01-linux/lab-06-systemd-service/`:
- `heartbeat.sh`, `heartbeat.service`, `heartbeat.env.example`
- `backup.service`, `backup.timer`
- `install.sh`: cài đặt toàn bộ (copy file, tạo user, `daemon-reload`, `enable --now`), idempotent
- `NOTES.md`: output kiểm chứng các bước, so sánh timer vs cron, output `systemd-analyze security`.

## Tiêu chí đạt
- [ ] Service chạy bằng user `heartbeat`, không phải root
- [ ] Tự restart khi bị kill, không restart khi stop chủ động
- [ ] Tự chạy sau reboot
- [ ] Cấu hình qua `EnvironmentFile`, không hardcode trong unit
- [ ] Timer chạy đúng lịch, `list-timers` hiển thị lần chạy tiếp theo
- [ ] `install.sh` chạy được trên VM sạch

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. `/etc/systemd/system`, `/lib/systemd/system`, `/run/systemd/system` khác nhau thế nào? Override unit của package bằng cách nào (`systemctl edit`)?
2. `Type=simple`, `forking`, `oneshot`, `notify` khác nhau thế nào? Chọn loại nào cho một app Python/Java chạy foreground?
3. `Restart=on-failure` khác `always`? `StartLimitBurst`/`StartLimitIntervalSec` để làm gì?
4. `systemctl enable` thực chất tạo ra cái gì? `WantedBy=multi-user.target` nghĩa là gì?
5. `After=network.target` khác `After=network-online.target` + `Wants=network-online.target`?
6. Vì sao không nên chạy app bằng root? System user khác user thường thế nào (UID, shell)?
7. Log của service lưu ở đâu? Làm sao giới hạn dung lượng journal?
8. `Persistent=true` trong timer giải quyết vấn đề gì mà cron không làm được?

<details>
<summary>Gợi ý</summary>

- `useradd --system --no-create-home --shell /usr/sbin/nologin heartbeat`.
- Bắt signal trong Bash: `trap 'echo shutting down; exit 0' TERM`. Lưu ý `sleep` chạy foreground sẽ trì hoãn trap — thử `sleep N & wait $!`.
- `OnCalendar=*-*-* 02:00:00`; kiểm tra biểu thức bằng `systemd-analyze calendar`.
- Với `ProtectSystem=strict`, service chỉ ghi được vào đường dẫn khai báo ở `ReadWritePaths=`.

</details>

## Tài liệu tham khảo
- `man systemd.service`, `man systemd.unit`, `man systemd.exec`, `man systemd.timer`
- https://wiki.archlinux.org/title/Systemd
- https://wiki.archlinux.org/title/Systemd/Timers
