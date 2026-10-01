# Lab 02 — Deploy ASP.NET Core (.NET 8) với Kestrel + systemd + Nginx

> **Module:** 04 Deploy App Server

## Mục tiêu
- Phân biệt .NET SDK và Runtime, build app bằng `dotnet publish`.
- Chạy Kestrel sau Nginx, cấu hình qua biến môi trường `ASPNETCORE_*`.
- Chạy app như systemd service bằng user riêng.

## Kiến thức cần có
- Module 01, 02, 03. Lab 01 của module này (nếu đã làm) — quy trình tương tự.

## Môi trường
- Máy build: máy cá nhân hoặc vm2 (cài .NET 8 **SDK**). Server: vm2 chỉ cần .NET 8 **Runtime** (`aspnetcore-runtime-8.0`).
- vm1: PostgreSQL `trainingdb`.
- Source: [`starter/`](starter/) — `Program.cs`, `EmployeesApi.csproj`, `app.env.example`.

## Yêu cầu
1. Cài .NET 8 SDK trên máy build, chạy thử app bằng `dotnet run`.
2. Build bằng `dotnet publish -c Release` theo kiểu **framework-dependent**. Quan sát thư mục output: file nào là entrypoint? Kích thước?
3. ⭐ Build thêm bản **self-contained** cho `linux-x64` và so sánh kích thước, yêu cầu trên server.
4. Trên vm2: cài **chỉ runtime** (`aspnetcore-runtime-8.0`), tạo system user `dotnetapp`, copy output publish vào `/opt/dotnetapp/`.
5. Env file `/etc/dotnetapp/dotnetapp.env` chứa thông tin DB, `ASPNETCORE_URLS=http://127.0.0.1:5001`, `ASPNETCORE_ENVIRONMENT=Production`.
6. Viết systemd unit `dotnetapp.service`: `User`, `WorkingDirectory`, `EnvironmentFile`, `ExecStart=/usr/bin/dotnet /opt/dotnetapp/EmployeesApi.dll`, `Restart=on-failure`, `KillSignal=SIGINT`, `SyslogIdentifier`.
7. Cấu hình Nginx `dotnet.training.local` → `127.0.0.1:5001`. Cấu hình app nhận đúng IP client và scheme từ Nginx (Forwarded Headers Middleware) — chứng minh bằng log.
8. Thử `kill -9`, reboot, tắt DB như lab 01.
9. Chạy `../check.sh http://dotnet.training.local dotnetapp 5001` trên vm2.

## Kết quả cần nộp
`devops-training/04-app-deploy/lab-02-dotnet/`:
- `NOTES.md`: các bước, so sánh framework-dependent vs self-contained, output `check.sh`, log `journalctl`
- `dotnetapp.service`, `dotnet.training.local.conf`, `dotnetapp.env.example`
- `Program.cs` nếu có sửa (VD thêm Forwarded Headers)

## Tiêu chí đạt
- [ ] `check.sh` PASS toàn bộ
- [ ] Server chỉ cài runtime, không cài SDK
- [ ] App nhận đúng IP client thật từ `X-Forwarded-For`
- [ ] Không có password trong repo, không commit `bin/`, `obj/`, `publish/`

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. .NET SDK, ASP.NET Core Runtime, .NET Runtime khác nhau thế nào?
2. Framework-dependent vs self-contained: ưu/nhược điểm, khi nào dùng cái nào?
3. Kestrel là gì? Vì sao Microsoft khuyến nghị đặt reverse proxy trước Kestrel?
4. Thứ tự ưu tiên cấu hình trong ASP.NET Core (appsettings.json, appsettings.{Environment}.json, env var, command line)?
5. Vì sao dùng `KillSignal=SIGINT`? App xử lý graceful shutdown thế nào?
6. Vì sao cần `ForwardedHeaders` middleware và `KnownProxies`? Rủi ro nếu tin mọi proxy?
7. Biến môi trường `ConnectionStrings__Default` ánh xạ vào config key nào? (quy ước `__`)

<details>
<summary>Gợi ý</summary>

- Cài .NET trên Ubuntu: https://learn.microsoft.com/dotnet/core/install/linux-ubuntu
- `dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish-sc`
- Forwarded Headers: `app.UseForwardedHeaders(new ForwardedHeadersOptions { ForwardedHeaders = ... })`.
- `journalctl -u dotnetapp -f` khi start để thấy log khởi động của Kestrel ("Now listening on: ...").

</details>

## Tài liệu tham khảo
- https://learn.microsoft.com/aspnet/core/host-and-deploy/linux-nginx
- https://learn.microsoft.com/aspnet/core/host-and-deploy/proxy-load-balancer
- https://learn.microsoft.com/dotnet/core/deploying/
- https://www.npgsql.org/doc/
