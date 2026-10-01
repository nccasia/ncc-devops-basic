# Lab 06 ⭐ — Viết lại pipeline bằng GitHub Actions

> **Module:** 08 CI/CD · *Bài nâng cao, không bắt buộc để pass module*

> ⚠️ **Quy tắc:** chạy workflow trên repo cá nhân của bạn. Không đưa key/credential thật của server nào vào secrets khi chưa được duyệt — dùng key riêng cho VM lab.

## Mục tiêu
- Hiểu mô hình workflow/job/step/runner của GitHub Actions.
- Chuyển pipeline Jenkins (lab 03–04) sang GitHub Actions với secrets và environments.
- So sánh được Jenkins, GitHub Actions và Azure DevOps Pipelines.

## Kiến thức cần có
- Lab 03, 04. YAML cơ bản.

## Môi trường
- Repo app trên GitHub cá nhân của bạn. Runner: GitHub-hosted cho build/test; với bước deploy vào VM nội bộ (`192.168.56.x`) GitHub-hosted runner **không** truy cập được → dùng **self-hosted runner** cài trên vm3 (hỏi mentor trước khi đăng ký runner).

## Yêu cầu
1. Tạo `.github/workflows/ci.yml`:
   - Trigger: `push` và `pull_request` vào `main`, thêm `workflow_dispatch`.
   - Job `test`: checkout, setup ngôn ngữ (có cache dependency), chạy test.
   - Job `build`: `needs: test`, build và push image lên registry (GHCR hoặc registry lab 03) với tag giống quy tắc lab 03. Chỉ push khi là `push` vào `main` (không push với PR).
2. Tạo `.github/workflows/deploy.yml` (hoặc job `deploy` trong cùng file):
   - Chạy trên self-hosted runner (label tự đặt).
   - Dùng **Environments** `staging` và `production`; `production` có *required reviewers* (thay cho `input` của Jenkins).
   - Secrets (SSH key, env app) đặt ở mức environment, không ở mức repo nếu không cần.
   - Smoke test sau deploy.
3. Đặt `permissions:` tối thiểu cho `GITHUB_TOKEN` (VD `contents: read`, `packages: write` chỉ ở job cần).
4. Viết bảng so sánh trong NOTES.md: Jenkins vs GitHub Actions vs Azure DevOps Pipelines theo các tiêu chí: hosting/vận hành, cú pháp, secrets, approval, agent/runner, plugin/marketplace, chi phí, phù hợp khi nào.

## Kết quả cần nộp
`devops-training/08-cicd/lab-06-github-actions/`:
- Các file workflow `.yml`
- `NOTES.md`: link workflow run, ảnh chụp approval environment, bảng so sánh

## Tiêu chí đạt
- [ ] PR chỉ chạy test, không push image
- [ ] Push `main` → test → build/push image → deploy staging tự động
- [ ] Production cần reviewer approve
- [ ] `GITHUB_TOKEN` có `permissions` tối thiểu, secrets không lộ trong log
- [ ] Có bảng so sánh 3 công cụ

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. GitHub-hosted runner và self-hosted runner khác nhau thế nào về bảo mật? Vì sao không nên gắn self-hosted runner vào repo public?
2. Workflow chạy từ PR của fork có đọc được secrets không? Vì sao?
3. `needs`, `if`, `environment` trong Actions tương ứng với gì trong Jenkinsfile?
4. Pin action theo tag (`@v4`) và theo commit SHA khác nhau thế nào về supply-chain security?
5. Nếu phải chọn 1 công cụ cho dự án khách hàng dùng Azure toàn bộ, bạn chọn gì và vì sao?

<details>
<summary>Gợi ý</summary>

- Build/push image: `docker/login-action`, `docker/metadata-action` (sinh tag), `docker/build-push-action`.
- Điều kiện chỉ push trên main: `if: github.event_name == 'push' && github.ref == 'refs/heads/main'`.
- Azure DevOps: tham khảo `azure-pipelines.yml` với `stages`, `environments` + approvals — chỉ cần so sánh lý thuyết.

</details>

## Tài liệu tham khảo
- https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions
- https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment
- https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions
- https://learn.microsoft.com/en-us/azure/devops/pipelines/
