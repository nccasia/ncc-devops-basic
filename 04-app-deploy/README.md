# 04 — Deploy App Server (Python Flask, .NET, Java Spring Boot)

> **Môi trường:** vm2 (192.168.56.12) chạy app + Nginx, vm1 (192.168.56.11) chạy PostgreSQL `trainingdb`

## Mục tiêu

- Build và chạy ứng dụng backend của 3 hệ sinh thái phổ biến: Python, .NET, Java.
- Chạy app như một **service** của hệ điều hành: systemd unit, user riêng, tự khởi động lại, đọc config từ biến môi trường.
- Đặt Nginx làm reverse proxy phía trước app (kiến thức module 03).
- Kết nối app với database từ xa (kiến thức module 02), quản lý secret đúng cách.
- Đọc log, chẩn đoán khi service không lên.

## Bắt buộc

- Làm **ít nhất 2 trong 3** lab ngôn ngữ (lab-01, lab-02, lab-03). Khuyến khích làm cả 3.
- Lab-04 ⭐ không bắt buộc nhưng rất nên làm trước khi vào [Capstone](../09-capstone/README.md) (phần versioning & rollback).

## Lý thuyết cần tự học

- systemd: unit file (`[Unit]`, `[Service]`, `[Install]`), `Type=`, `Restart=`, `User=`, `WorkingDirectory=`, `Environment=`/`EnvironmentFile=`, `systemctl daemon-reload`, `journalctl -u`
- Hardening cơ bản: `NoNewPrivileges`, `ProtectSystem`, `PrivateTmp`, system user (`useradd --system`)
- Python: virtualenv, `pip`, WSGI, gunicorn (worker, `--bind`, số worker = `2*CPU+1`)
- .NET: SDK vs Runtime, `dotnet publish` (framework-dependent vs self-contained), Kestrel, `ASPNETCORE_URLS`, `ASPNETCORE_ENVIRONMENT`
- Java: JDK vs JRE, Maven lifecycle (`package`), fat jar, `java -jar`, JVM heap (`-Xms`, `-Xmx`), Spring profiles, externalized configuration
- 12-factor app: config qua env, log ra stdout, stateless process
- Connection string PostgreSQL, connection pool

Tài liệu: https://www.freedesktop.org/software/systemd/man/systemd.service.html · https://12factor.net/ · https://docs.gunicorn.org/ · https://learn.microsoft.com/aspnet/core/host-and-deploy/linux-nginx · https://docs.spring.io/spring-boot/reference/deployment/installing.html

## Chuẩn bị database chung

Tất cả lab trong module dùng chung bảng `employees` và `departments` trong database `trainingdb` trên vm1 — chính là dữ liệu từ [`02-database/lab-01-install-and-configure/starter/seed.sql`](../02-database/lab-01-install-and-configure/starter/seed.sql). Nếu chưa import, chạy trên vm1 (lưu ý script sẽ `DROP` rồi tạo lại 2 bảng):

```bash
psql -h localhost -U training_owner -d trainingdb -f /repo/02-database/lab-01-install-and-configure/starter/seed.sql
```

App chỉ cần đọc, nên tạo user riêng theo nguyên tắc least privilege:

```sql
CREATE USER app_reader WITH PASSWORD '<set-a-strong-password>';
GRANT CONNECT ON DATABASE trainingdb TO app_reader;
GRANT USAGE ON SCHEMA public TO app_reader;
GRANT SELECT ON employees, departments TO app_reader;
```

`GET /api/employees` của các starter app chạy query JOIN 2 bảng và trả về `id, full_name, email, department` (tên phòng ban).

Nhớ cấu hình `pg_hba.conf` + firewall trên vm1 cho phép vm2 kết nối (đã học ở module 02).

## Yêu cầu chung cho mọi lab ngôn ngữ

| Hạng mục | Yêu cầu |
|----------|---------|
| Endpoint | `GET /health` → `{"status":"ok"}`; `GET /api/employees` → danh sách nhân viên (JSON) đọc từ DB |
| User | App chạy bằng system user riêng (VD `flaskapp`), **không** phải root, không login shell |
| Thư mục | Code/binary tại `/opt/<app>/`, owner hợp lý |
| Config | Thông tin DB đọc từ biến môi trường, đặt trong `/etc/<app>/<app>.env` (quyền `640`, owner `root:<app-group>`) |
| Service | systemd unit `/etc/systemd/system/<app>.service`, `Restart=on-failure`, enable khi boot |
| Network | App chỉ listen `127.0.0.1:<port>`; Nginx public port 80 proxy vào |
| Log | Xem được log qua `journalctl -u <app>` |

Port gợi ý: Flask `5000`, .NET `5001`, Spring Boot `8080`. Domain gợi ý: `flask.training.local`, `dotnet.training.local`, `spring.training.local`.

## Danh sách lab

| Lab | Nội dung | Bắt buộc |
|-----|----------|----------|
| [lab-01-python-flask](lab-01-python-flask/README.md) | Flask + gunicorn + systemd + Nginx | ✅ (chọn 2/3) |
| [lab-02-dotnet](lab-02-dotnet/README.md) | ASP.NET Core minimal API + Kestrel + systemd + Nginx | ✅ (chọn 2/3) |
| [lab-03-java-spring-boot](lab-03-java-spring-boot/README.md) | Spring Boot fat jar + systemd + Nginx | ✅ (chọn 2/3) |
| [lab-04-config-logs-and-zero-downtime](lab-04-config-logs-and-zero-downtime/README.md) | Tách config/secret, log rotation, releases + symlink, rollback | ⭐ |

Script kiểm tra chung (chạy trên vm2): [`check.sh`](check.sh) — `./check.sh http://flask.training.local flaskapp 5000`

Cả 3 starter app đọc cùng bộ biến môi trường: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` (mẫu: `starter/app.env.example` trong mỗi lab).

## Câu hỏi tự kiểm tra cuối module

Tự trả lời các câu dưới đây vào `devops-training/04-app-deploy/module-questions.md` sau khi xong các lab.

1. Vì sao không chạy app bằng root? Nếu app cần listen port 80 mà không chạy root thì có những cách nào?
2. `Restart=always` khác `Restart=on-failure` thế nào? `StartLimitBurst`/`StartLimitIntervalSec` dùng để làm gì?
3. Sửa unit file xong mà service vẫn chạy cấu hình cũ — vì sao?
4. Vì sao không hardcode connection string trong code? So sánh `Environment=` trong unit file với `EnvironmentFile=`.
5. So sánh cách 3 runtime xử lý concurrency: gunicorn workers (process), Kestrel (thread pool/async), Tomcat embedded (thread pool).
6. Framework-dependent vs self-contained (.NET), fat jar (Java), virtualenv (Python): mỗi cách đóng gói phụ thuộc gì trên server?
7. App khởi động trong 1 giây rồi chết liên tục. Trình bày các bước điều tra.
8. JVM heap `-Xmx` nên đặt bao nhiêu so với RAM máy? Chuyện gì xảy ra khi đặt quá lớn/quá nhỏ?

## Bài tự luyện debug (break & fix)

Sau khi app chạy ổn định, bạn tự cố tình làm hỏng từng điểm dưới đây (mỗi lần một lỗi), quan sát triệu chứng, tự chẩn đoán bằng `systemctl status`, `journalctl`, `ss`, `curl`, rồi sửa lại. Ghi vào `devops-training/04-app-deploy/break-and-fix.md` theo bảng: **Kịch bản → Triệu chứng → Cách chẩn đoán (lệnh, dòng log) → Nguyên nhân → Cách sửa**.

- Đổi quyền env file thành `600 root:root` rồi restart service.
- Sai password DB trong env file; hoặc xóa rule `pg_hba.conf` cho vm2 trên vm1. `/health` và `/api/employees` phản ứng khác nhau thế nào?
- Sửa unit file (VD đổi port) nhưng quên `systemctl daemon-reload`.
- Cho app listen `0.0.0.0` và mở firewall port app — tự đánh giá rủi ro, rồi đưa về đúng cấu hình.
- Đổi `WorkingDirectory` sang thư mục sai.
- Đặt `-Xmx` lớn hơn RAM của VM (lab Java) và gọi API liên tục — tìm dấu vết trong `dmesg`/`journalctl -k`.

Mẹo: luôn bắt đầu bằng `systemctl status <app>` (xem exit code, số lần restart) và `journalctl -u <app> -n 50 --no-pager`.
