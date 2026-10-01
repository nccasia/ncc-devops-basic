# Lab 04 — Deploy tự động qua SSH, approval và smoke test

> **Module:** 08 CI/CD

## Mục tiêu
- Tự động deploy lên server Linux qua SSH theo 2 cách: artifact + systemd và docker compose.
- Thêm cổng phê duyệt (manual approval) trước môi trường production.
- Xác minh deploy bằng smoke test và fail pipeline khi app không khỏe.

## Kiến thức cần có
- Lab 03 (artifact + image đã có version trên registry).
- Module 04 (systemd unit cho app), module 07 (docker compose).

## Môi trường
- Deploy target: vm3 `192.168.56.13` (hoặc VM riêng). Tạo user `deploy` trên target — **không** dùng `root`, không dùng chung key với agent.
- DB trên vm1 `192.168.56.11` (từ module 02), app kết nối bằng user DB riêng với quyền tối thiểu.
- Hai "môi trường" giả lập trên cùng target: `staging` (port 8081) và `production` (port 8080) — hoặc 2 VM nếu đủ tài nguyên.

## Yêu cầu
1. **Credentials:** tạo SSH key riêng cho user `deploy`, lưu vào Jenkins Credentials. Dùng `sshagent` để chạy lệnh/scp. Biến cấu hình app (DB password…) lưu trong Jenkins Credentials (Secret file / Secret text) và được ghi vào file env trên server với quyền `600`.
2. **Cách A — artifact + systemd:**
   - Copy artifact của build vào `/opt/<app>/releases/<version>/`.
   - Cập nhật symlink `/opt/<app>/current` → release mới (atomic).
   - Restart service systemd. User `deploy` chỉ được phép `sudo systemctl restart|status <app>` (cấu hình `sudoers.d` giới hạn đúng lệnh, không `NOPASSWD: ALL`).
3. **Cách B — docker compose:**
   - Trên server có `/opt/<app>/docker-compose.yml` dùng biến `IMAGE_TAG`.
   - Pipeline chỉ cập nhật `IMAGE_TAG` rồi `docker compose pull && docker compose up -d` — **không** build image trên server.
4. Pipeline chọn cách deploy qua parameter `DEPLOY_METHOD` (`systemd` / `compose`).
5. **Luồng môi trường:**
   - Tự động deploy `staging` sau khi build xong.
   - Stage `Approve production` dùng `input` — chỉ user thuộc nhóm/role được chỉ định mới bấm được, timeout 30 phút (hết giờ → abort, không deploy).
   - Deploy `production` **dùng lại đúng artifact/image** đã deploy staging, không build lại.
6. **Smoke test** sau mỗi lần deploy: gọi `GET /health` (và `GET /api/employees`) có retry (VD 10 lần, cách 3s), yêu cầu HTTP 200. Fail → stage fail.
7. Ghi `post` thông báo kết quả (echo hoặc gửi webhook Mezon/Slack/email nếu mentor cho phép).

## Kết quả cần nộp
`devops-training/08-cicd/lab-04-deploy-ssh/`:
- `Jenkinsfile`
- `deploy/` : script deploy (`deploy-systemd.sh`, `deploy-compose.sh`), systemd unit, `docker-compose.yml`, file `sudoers.d` mẫu, `.env.example`
- `NOTES.md`: sơ đồ luồng pipeline, ảnh chụp stage approval, log smoke test pass và fail, `ls -l /opt/<app>/releases` sau 3 lần deploy

## Tiêu chí đạt
- [ ] Deploy bằng user `deploy`, quyền sudo giới hạn đúng lệnh cần thiết
- [ ] Cả 2 cách deploy đều chạy được qua parameter
- [ ] Đổi symlink `current` là atomic, release cũ vẫn còn trên server
- [ ] Production chỉ deploy sau khi được approve bởi người có quyền
- [ ] Production dùng đúng version đã chạy ở staging
- [ ] Smoke test fail → pipeline đỏ
- [ ] Không có secret nào trong repo hay console log

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Vì sao dùng symlink `current` thay vì copy đè file vào thư mục chạy? `ln -sfn` có thực sự atomic không?
2. `docker compose up -d` khi đổi tag image làm gì với container cũ? Có downtime không? Làm sao giảm downtime?
3. Giới hạn quyền sudo cho user `deploy` như thế nào là đủ? Nếu cho `sudo systemctl *` thì có rủi ro gì?
4. `input` step chiếm executor trong lúc chờ không? Nên đặt `input` ở đâu (trong hay ngoài `agent`)?
5. Smoke test chỉ check `/health` có đủ không? `/health` nên kiểm tra những gì (liveness vs readiness)?
6. Nếu deploy production giữa chừng bị đứt SSH thì server ở trạng thái nào? Thiết kế script deploy sao cho idempotent?

<details>
<summary>Gợi ý</summary>

- Atomic symlink: tạo symlink tạm rồi `mv -T` đè lên `current`.
- `input` với `submitter: 'release-managers'` và đặt trong stage có `agent none` để không giữ executor.
- Retry smoke test: `retry(10) { sleep 3; sh 'curl -fsS http://.../health' }` hoặc vòng lặp bash với `curl --retry`.
- Biến môi trường app: `withCredentials([file(credentialsId: 'app-env-prod', variable: 'ENV_FILE')])` rồi `scp` lên server.

</details>

## Tài liệu tham khảo
- https://www.jenkins.io/doc/pipeline/steps/ssh-agent/
- https://www.jenkins.io/doc/pipeline/steps/pipeline-input-step/
- https://docs.docker.com/compose/how-tos/environment-variables/
- `man sudoers`
