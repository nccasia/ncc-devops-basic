# Capstone — Self-checklist trước khi demo

Tự rà từng mục dưới đây trên **hệ thống thật** (không phải "nhớ là đã làm"). Mỗi mục bạn phải chỉ ra được bằng chứng: lệnh, output, file config hoặc ảnh chụp. Mục có ⭐ là nâng cao, không bắt buộc.

Gợi ý: copy file này vào `docs/self-checklist.md` trong bài nộp và tick dần theo tiến độ.

## 1. Source code & Database
- [ ] BE có `GET /api/health` trả trạng thái app **và** kết nối DB
- [ ] CRUD 1 resource đọc/ghi DB thật
- [ ] Toàn bộ cấu hình BE đọc từ biến môi trường, không hardcode host/password
- [ ] FE gọi BE bằng đường dẫn tương đối `/api/...`, đã build bản production
- [ ] DB có 3 user tách quyền: `app_user` (DML), `migration_user` (DDL), `readonly_user` (SELECT); app không dùng superuser
- [ ] Giải thích được từng `GRANT` trong `docs/decisions.md`
- [ ] DB chỉ chấp nhận kết nối từ IP của BE (`pg_hba.conf`/`bind-address` + firewall)
- [ ] Backup tự động hằng ngày (cron/systemd timer) và **đã thử restore** thành công

## 2. Deploy Linux thuần (systemd + Nginx)
- [ ] BE chạy bằng systemd với user hệ thống riêng, không login shell
- [ ] Unit có `Restart=`, `EnvironmentFile` quyền `600`, `enable` để tự chạy sau reboot
- [ ] `kill -9` process BE → systemd tự khởi động lại
- [ ] Nginx serve FE static và reverse proxy BE, có SPA fallback, header `X-Forwarded-*`
- [ ] Cấu trúc `releases/` + symlink `current`, deploy không cần sửa tay trên server
- [ ] Reboot server → toàn bộ hệ thống tự lên lại

## 3. Deploy Docker / Compose
- [ ] Dockerfile multi-stage cho BE và FE, có `.dockerignore`, chạy non-root
- [ ] Kích thước image hợp lý (ghi lại size và so sánh với base image)
- [ ] Compose: chỉ Nginx publish port; BE và DB không publish port
- [ ] Network nội bộ, volume cho dữ liệu DB, healthcheck + `depends_on: condition: service_healthy`
- [ ] Server chỉ `pull` image theo tag version từ registry, không build trên server
- [ ] `docker compose down && docker compose up -d` không mất dữ liệu

## 4. HTTPS & một endpoint
- [ ] Cert self-signed (hoặc ký bởi CA nội bộ) có SAN đúng domain
- [ ] HTTP (80) redirect sang HTTPS (443)
- [ ] Chỉ bật TLS 1.2 / 1.3
- [ ] `/api/*` → BE, `/*` → FE trên cùng domain — hoạt động ở **cả 2** cách deploy
- [ ] F5 ở một route con của SPA không bị 404
- [ ] Có header HSTS, `X-Content-Type-Options`, `X-Frame-Options`
- [ ] Giải thích được vì sao không cần CORS
- [ ] Private key của cert **không** có trong repo

## 5. CI/CD Jenkins
- [ ] Jenkinsfile nằm trong repo, build chạy trên agent (built-in node 0 executor)
- [ ] Push `main` → pipeline tự chạy
- [ ] Build → test (Jenkins hiển thị kết quả test) → image có version → push registry
- [ ] Test fail → không push image, không deploy
- [ ] Deploy **tất cả** service: BE, FE, migration DB
- [ ] Deploy được theo cả 2 cách (systemd / compose)
- [ ] Smoke test sau deploy, fail → pipeline đỏ
- [ ] Production cần approval; production dùng đúng image/artifact đã chạy ở staging
- [ ] Mọi secret qua Jenkins Credentials, console log hiển thị `****`

## 6. Versioning & rollback
- [ ] Mỗi lần deploy có version duy nhất (semver + build number / git sha)
- [ ] Lịch sử deploy ghi: thời gian, môi trường, version, commit, người deploy, trạng thái
- [ ] Deploy lỗi → **rollback tự động**, app trở lại version trước, pipeline vẫn FAILURE
- [ ] Rollback thủ công về version bất kỳ trong 5 version gần nhất, có smoke test
- [ ] Có chiến lược DB migration khi rollback (ghi trong `docs/decisions.md`)

## 7. Bảo mật & vận hành
- [ ] Không có secret trong repo và lịch sử git (đã quét bằng `git log -p | grep -i` hoặc gitleaks)
- [ ] Có `.env.example`, `.gitignore` đầy đủ
- [ ] Mỗi service chạy bằng user riêng; user `deploy` chỉ sudo đúng lệnh cần thiết
- [ ] SSH tắt đăng nhập bằng password và đăng nhập root
- [ ] Firewall app server chỉ mở 22/80/443; DB server chỉ mở cổng DB cho IP BE và 22
- [ ] Log Nginx có logrotate; log BE xem được qua `journalctl` và `docker compose logs`
- [ ] Log không chứa password/token

## 8. Chrome DevTools
- [ ] `docs/devtools-report.md` có 1 request thành công đầy đủ: headers, payload, response, timing
- [ ] Có ảnh tab Security với thông tin certificate
- [ ] Tự tái hiện và giải thích ≥ 4 tình huống lỗi trong [devtools-checklist.md](devtools-checklist.md) (có 502 và CORS hoặc mixed content)

## 9. Tài liệu
- [ ] README đủ để một người khác dựng lại hệ thống từ đầu (nhờ bạn cùng khóa thử làm theo)
- [ ] `docs/runbook.md`: deploy, rollback, restore DB, xử lý sự cố thường gặp
- [ ] `docs/decisions.md`: các lựa chọn kỹ thuật và lý do
- [ ] Sơ đồ kiến trúc khớp với hệ thống thực tế

## 10. Tự luyện debug (break & fix)
Tự cố tình gây từng lỗi dưới đây, chẩn đoán và sửa, ghi vào `docs/runbook.md` theo format **triệu chứng → nguyên nhân → cách sửa**:
- [ ] Sai password DB trong file env → BE không kết nối được DB
- [ ] Sai `proxy_pass` (thừa/thiếu `/`) → `/api` trả 404
- [ ] Đổi quyền thư mục FE → 403
- [ ] Xóa rule cho IP BE trong `pg_hba.conf` → BE bị từ chối kết nối
- [ ] Dừng container/service DB → health check fail
- [ ] Cert sai SAN hoặc hết hạn

## ⭐ Nâng cao
- [ ] Monitoring (Prometheus + Grafana / Uptime Kuma) có alert
- [ ] Blue/green hoặc zero-downtime deploy chứng minh được
- [ ] Quét image bằng Trivy trong pipeline, fail khi có CRITICAL
- [ ] GitHub Actions song song với Jenkins (trên repo cá nhân)
- [ ] Ansible/IaC dựng server từ đầu
