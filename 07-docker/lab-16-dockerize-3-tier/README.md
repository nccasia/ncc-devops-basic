# Lab 16 — Dockerize ứng dụng 3 tầng (FE + BE + DB)

> **Module:** 07 Docker · **Bắt buộc** — cầu nối sang [09 Capstone](../../09-capstone/README.md)

## Mục tiêu
- Đóng gói toàn bộ ứng dụng 3 tầng bằng Docker Compose ở mức gần production.
- Áp dụng tổng hợp: Dockerfile tối ưu, network tách lớp, volume, healthcheck, non-root, quản lý secret.

## Kiến thức cần có
- Toàn bộ lab 01–15. BE đã deploy ở [module 04](../../04-app-deploy/README.md), FE ở [module 06](../../06-frontend-static/README.md), DB ở [module 02](../../02-database/README.md).

## Môi trường
- VM Ubuntu có Docker + Compose v2.
- Source BE (Flask/.NET/Spring Boot) và FE (React/Vue/Angular) bạn đã dùng ở module 04, 06 — có thể dùng lại làm source cho capstone.

## Kiến trúc yêu cầu

```
                 ┌──────────────────────── network: frontend ───────────────────────┐
 client ──:80/:443──▶ nginx (reverse proxy)                                          │
                 │      ├── /        → fe  (static files)                             │
                 │      └── /api/*   → be  ─────────┐                                 │
                 └─────────────────────────────────┼─────────────────────────────────┘
                                                   │  network: backend (internal)
                                                   └──▶ db (PostgreSQL) ── volume: db-data
```

## Yêu cầu
1. **BE**: Dockerfile multi-stage, chạy non-root, đọc cấu hình DB từ env, có endpoint `/api/health` kiểm tra kết nối DB.
2. **FE**: Dockerfile multi-stage — stage build bằng Node, stage chạy serve file tĩnh (nginx/nginx-unprivileged hoặc tương đương). SPA routing không lỗi 404 khi refresh trang con.
3. **DB**: PostgreSQL image chính thức, pin version, dữ liệu trong named volume, script khởi tạo DB/user (user ứng dụng **không** phải superuser — áp dụng kiến thức module 02).
4. **Nginx reverse proxy**: một endpoint duy nhất — `/api/*` → BE, `/*` → FE. Chỉ service này publish port ra host.
5. **Network**: tách `frontend` và `backend`; `backend` là `internal: true`. `db` chỉ nằm ở `backend`; nginx **không** nói chuyện trực tiếp được với `db`.
6. **Healthcheck** cho `db`, `be`, `fe`; `depends_on` với `condition: service_healthy`.
7. **Secret**: password DB không nằm trong `docker-compose.yml` hay image; dùng `.env` (có `.env.example`) hoặc compose `secrets:`.
8. `restart: unless-stopped`, giới hạn log (`logging.options`), ⭐ giới hạn tài nguyên (`deploy.resources.limits`).
9. Image tag theo version (không dùng `latest`), build bằng `docker compose build` với biến `APP_VERSION`.
10. Viết `Makefile` hoặc script với các lệnh: `up`, `down`, `logs`, `backup-db`, `restore-db`.

## Kết quả cần nộp
Nộp vào `devops-training/07-docker/lab-16-dockerize-3-tier/`:
- `be/`, `fe/` (source + Dockerfile + `.dockerignore`), `nginx/`, `db/init/`, `docker-compose.yml`, `.env.example`, `Makefile`
- `NOTES.md`: sơ đồ, cách chạy, output `docker compose ps`, ảnh Chrome DevTools tab Network khi FE gọi `/api/*`, kết quả kiểm tra cô lập network, kích thước từng image

## Tiêu chí đạt
- [ ] `cp .env.example .env && docker compose up -d --build` chạy được từ repo sạch
- [ ] Truy cập `http://<vm-ip>/` ra FE, FE gọi được BE qua `/api/*`, BE đọc/ghi được DB
- [ ] Refresh trang con của SPA không bị 404
- [ ] Chỉ nginx publish port; `docker compose exec nginx` không kết nối được `db:5432`
- [ ] Tất cả service `healthy`; mọi container (trừ những image chính thức bắt buộc) chạy non-root
- [ ] `docker compose down && docker compose up -d` → dữ liệu DB còn nguyên
- [ ] Không có secret trong compose, image (`docker history`) hay git
- [ ] `backup-db` / `restore-db` hoạt động

## Câu hỏi tự kiểm tra

Tự trả lời các câu hỏi sau và ghi câu trả lời vào `NOTES.md`.
1. Vì sao chỉ nên có một entrypoint (nginx) publish port? Lợi ích về bảo mật và CORS?
2. `internal: true` chặn những gì? BE có còn ra internet được không?
3. Khi BE khởi động nhanh hơn DB sẵn sàng thì chuyện gì xảy ra nếu không có healthcheck? App nên tự retry không?
4. Biến môi trường của FE (VD URL API) được "đóng" vào lúc build hay lúc chạy? Hệ quả khi deploy nhiều môi trường?
5. Muốn rollback về version trước thì làm thế nào với setup này?
6. So sánh với cách deploy systemd + nginx ở module 04: ưu/nhược điểm của mỗi cách?

<details>
<summary>Gợi ý</summary>

- Image `nginxinc/nginx-unprivileged` chạy nginx non-root ở port 8080.
- Script trong `/docker-entrypoint-initdb.d/` của Postgres chỉ chạy khi volume dữ liệu **trống**.
- `pg_isready` cho healthcheck DB.
- Backup: `docker compose exec -T db pg_dump ...`.

</details>

## Tài liệu tham khảo
- https://docs.docker.com/compose/how-tos/networking/
- https://docs.docker.com/reference/compose-file/networks/#internal
- https://docs.docker.com/compose/how-tos/use-secrets/
- https://hub.docker.com/_/postgres
- https://hub.docker.com/r/nginxinc/nginx-unprivileged
