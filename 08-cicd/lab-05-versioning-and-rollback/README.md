# Lab 05 — Quản lý version deploy và rollback

> **Module:** 08 CI/CD

## Mục tiêu
- Lưu vết được: môi trường nào đang chạy version nào, deploy lúc nào, ai deploy.
- Rollback tự động khi deploy lỗi và rollback thủ công về version bất kỳ.
- Hiểu giới hạn của rollback (database, config, dữ liệu).

## Kiến thức cần có
- Lab 04 (pipeline deploy 2 cách đã chạy, có smoke test).

## Môi trường
- Như lab 04.

## Yêu cầu
1. **Lịch sử deploy** trên server: mỗi lần deploy thành công ghi 1 dòng vào `/opt/<app>/deploy-history.log` theo format:
   ```
   2026-10-01T09:15:02+07:00 | env=production | version=1.2.0-45 | sha=a1b2c3d | method=compose | by=dev-quang | status=SUCCESS
   ```
   Lần deploy lỗi/rollback cũng phải được ghi với `status=FAILED` / `status=ROLLBACK`.
   File `/opt/<app>/CURRENT_VERSION` luôn chứa version đang chạy.
2. **Giữ release:** chỉ giữ 5 release gần nhất (cách systemd) / 5 tag gần nhất được tham chiếu (cách compose). Release đang chạy và release trước đó không bao giờ bị xóa.
3. **Rollback tự động:** nếu smoke test sau deploy fail:
   - Tự động quay về version trước đó (đọc từ `CURRENT_VERSION` trước khi deploy).
   - Chạy lại smoke test cho version cũ.
   - Pipeline vẫn kết thúc **FAILURE** (không được báo xanh) và log rõ đã rollback về version nào.
4. **Rollback thủ công:** tạo job/pipeline `rollback-<app>` với parameter:
   - `TARGET_ENV` (staging / production)
   - `VERSION` — danh sách version lấy động từ lịch sử (dùng *Active Choices* plugin hoặc `string` parameter có validate version tồn tại trên registry/server)
   Rollback cũng phải qua smoke test và ghi vào lịch sử.
5. **Kịch bản kiểm chứng** (ghi lại trong NOTES.md):
   - Deploy v1 → v2 thành công.
   - Deploy v3 cố tình lỗi (VD `/health` trả 500 hoặc app crash khi khởi động) → tự rollback về v2.
   - Rollback thủ công về v1.
   - In `deploy-history.log` sau toàn bộ kịch bản.
6. **Database:** nếu app có migration, viết trong NOTES.md chiến lược của bạn: migration chạy ở đâu trong pipeline, làm gì khi rollback app mà schema đã đổi (expand/contract).
7. ⭐ Tạo git tag `release/<version>` tự động khi deploy production thành công.

## Kết quả cần nộp
`devops-training/08-cicd/lab-05-versioning-and-rollback/`:
- `Jenkinsfile` (deploy) và `Jenkinsfile.rollback`
- Script `rollback.sh`, script dọn release cũ
- `NOTES.md`: kịch bản kiểm chứng kèm log, nội dung `deploy-history.log`, chiến lược DB migration

## Tiêu chí đạt
- [ ] Lịch sử deploy đầy đủ trường, ghi cả trường hợp lỗi và rollback
- [ ] Deploy lỗi → tự rollback, app trở lại hoạt động, pipeline đỏ
- [ ] Rollback thủ công về version chỉ định thành công, có smoke test
- [ ] Không xóa nhầm release đang chạy/release trước đó
- [ ] Có giải thích chiến lược DB khi rollback

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Rollback và roll-forward (fix nhanh rồi deploy tiếp) — khi nào nên chọn cách nào?
2. Rollback app về version cũ nhưng DB đã chạy migration xóa cột thì chuyện gì xảy ra? Expand/contract giải quyết thế nào?
3. Vì sao rollback tự động vẫn phải để pipeline FAILURE?
4. Nguồn sự thật (source of truth) về version đang chạy nên là gì: Jenkins, file trên server, registry, hay git tag? Ưu nhược điểm?
5. Config/secret thay đổi giữa 2 version thì rollback có tự quay lại config cũ không? Làm sao version hóa config?
6. Blue/green deployment giúp rollback nhanh hơn như thế nào?

<details>
<summary>Gợi ý</summary>

- Đọc version cũ ở đầu stage deploy, lưu vào `env.PREVIOUS_VERSION` để dùng trong `catchError`/`post { failure }`.
- Dùng `catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') { ... }` để chạy tiếp bước rollback mà vẫn giữ trạng thái đỏ.
- Cách systemd: rollback = trỏ lại symlink `current` + restart. Cách compose: rollback = đổi `IMAGE_TAG` + `up -d`.
- Dọn release: `ls -1dt releases/* | tail -n +6` — nhớ loại trừ target của `current`.

</details>

## Tài liệu tham khảo
- https://www.jenkins.io/doc/pipeline/steps/workflow-basic-steps/#catcherror-catch-error-and-set-build-result-to-failure
- https://plugins.jenkins.io/uno-choice/
- https://martinfowler.com/bliki/BlueGreenDeployment.html
- https://www.prisma.io/dataguide/types/relational/expand-and-contract-pattern
