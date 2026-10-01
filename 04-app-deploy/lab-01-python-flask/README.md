# Lab 01 — Deploy Python Flask với gunicorn + systemd + Nginx

> **Module:** 04 Deploy App Server

## Mục tiêu
- Đóng gói môi trường Python bằng virtualenv, chạy app qua WSGI server gunicorn.
- Chạy app như systemd service bằng user riêng, config qua env file.
- Đặt Nginx reverse proxy phía trước, kết nối PostgreSQL trên vm1.

## Kiến thức cần có
- Module 01 (systemd, user/permission), 02 (PostgreSQL remote access), 03 (reverse proxy).

## Môi trường
- vm2: app + Nginx. vm1: PostgreSQL `trainingdb` với bảng `employees` (xem [README module](../README.md#chuẩn-bị-database-chung)).
- Source: [`starter/`](starter/) — `app.py`, `requirements.txt`, `app.env.example`.

## Yêu cầu
1. Cài `python3-venv`. Tạo system user `flaskapp` (không login shell, không home hoặc home tại `/opt/flaskapp`).
2. Copy source vào `/opt/flaskapp/app`, tạo virtualenv tại `/opt/flaskapp/venv`, cài dependencies. Owner thư mục là `flaskapp` nhưng user này **không** được ghi vào code (chỉ đọc) — giải thích cách bạn phân quyền.
3. Chạy thử bằng tay: `gunicorn --bind 127.0.0.1:5000 app:app` với user `flaskapp`, `curl` được `/health` và `/api/employees`.
4. Tạo env file `/etc/flaskapp/flaskapp.env` (quyền `640`, `root:flaskapp`) chứa thông tin DB.
5. Viết systemd unit `flaskapp.service`:
   - `User=flaskapp`, `WorkingDirectory`, `EnvironmentFile`
   - `ExecStart` gọi gunicorn trong venv, số worker tính theo CPU (`2*CPU+1`), bind `127.0.0.1:5000`
   - `Restart=on-failure`, enable khi boot
   - ⭐ hardening: `NoNewPrivileges=true`, `ProtectSystem=strict`, `PrivateTmp=true`
6. Cấu hình Nginx `flask.training.local` → `127.0.0.1:5000`, có header proxy như module 03.
7. Thử: `kill -9` process master gunicorn → systemd tự khởi động lại. Reboot vm2 → service tự lên.
8. Thử: tắt PostgreSQL trên vm1 → `/api/employees` trả `503`, `/health` vẫn `200`. Đọc log qua `journalctl`.
9. Chạy `../check.sh http://flask.training.local flaskapp 5000` trên vm2.

## Kết quả cần nộp
`devops-training/04-app-deploy/lab-01-python-flask/`:
- `NOTES.md`: các bước, output `systemctl status`, `ss -tlnp`, `journalctl -u flaskapp -n 30`, output `check.sh`, kết quả bước 7–8
- `flaskapp.service`, `flask.training.local.conf`, `flaskapp.env.example` (không có password thật)

## Tiêu chí đạt
- [ ] `check.sh` PASS toàn bộ
- [ ] App tự restart sau `kill -9` và sau reboot
- [ ] `/health` không phụ thuộc DB, `/api/employees` trả `503` khi DB chết (không treo, không 502)
- [ ] Env file quyền `640`, không có password trong repo
- [ ] User `flaskapp` không ghi được vào thư mục code

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Vì sao không dùng `flask run` (development server) cho production?
2. WSGI là gì? gunicorn master và worker làm nhiệm vụ gì?
3. Vì sao số worker gợi ý là `2*CPU+1`? Khi nào nên dùng worker class `gthread`/`gevent`?
4. Vì sao phải dùng virtualenv thay vì `pip install` toàn hệ thống (gợi ý: PEP 668 trên Ubuntu 24.04)?
5. App mở connection DB mỗi request — vấn đề gì khi tải cao? Giải pháp?
6. Nếu worker xử lý request quá 30s thì gunicorn làm gì? Liên quan gì tới `proxy_read_timeout` của Nginx?
7. `Type=simple`, `Type=exec`, `Type=notify` khác nhau thế nào?

<details>
<summary>Gợi ý</summary>

- `useradd --system --shell /usr/sbin/nologin --home-dir /opt/flaskapp flaskapp`
- `nproc` để biết số CPU.
- Chạy lệnh bằng user khác: `sudo -u flaskapp ...`.
- `systemd-analyze security flaskapp` chấm điểm hardening của unit.
- Nếu `ProtectSystem=strict` làm app lỗi, đọc kỹ log: app cần ghi vào đâu? (`ReadWritePaths=`)

</details>

## Tài liệu tham khảo
- https://flask.palletsprojects.com/en/stable/deploying/gunicorn/
- https://docs.gunicorn.org/en/stable/design.html
- https://docs.gunicorn.org/en/stable/deploy.html#systemd
- https://www.psycopg.org/psycopg3/docs/
