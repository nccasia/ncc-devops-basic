# Lab 02 — Jenkinsfile declarative đầu tiên

> **Module:** 08 CI/CD

## Mục tiêu
- Viết pipeline-as-code bằng Jenkinsfile declarative, lưu cùng source code.
- Sử dụng `environment`, `parameters`, `when`, `post`, `options`.
- Cấu hình trigger tự động (webhook hoặc Poll SCM) và Multibranch Pipeline.

## Kiến thức cần có
- Lab 01 (Jenkins + agent đã chạy).
- Git branch, Groovy cơ bản (cú pháp map/string).

## Môi trường
- Jenkins từ lab 01, agent label `linux`.
- Một repo Git chứa app BE của bạn (từ module 04). Dùng một repo riêng trên tài khoản cá nhân (VD `devops-training-app`, khuyến nghị private) hoặc repo Git tự host trong lab (Gitea/GitLab trên VM).

## Yêu cầu
1. Copy [`starter/Jenkinsfile`](starter/Jenkinsfile) vào root repo app, hoàn thành các `TODO`:
   - Chạy trên agent có label `linux`, không chạy trên controller.
   - `options`: timeout 20 phút, giữ tối đa 10 build, timestamps, không cho chạy song song (`disableConcurrentBuilds`).
   - `parameters`: `TARGET_ENV` (choice: `dev`, `staging`), `SKIP_TESTS` (boolean, mặc định false).
   - `environment`: `APP_NAME`, `GIT_SHORT_SHA` (lấy từ git), `VERSION = <build number>-<git short sha>`.
   - Stage `Checkout`, `Info` (in version, branch, người trigger), `Test` (bỏ qua khi `SKIP_TESTS=true` bằng `when`), `Notify`.
   - `post`: `success`/`failure`/`always` — in trạng thái, `cleanWs()` trong `always`.
2. Tạo job Pipeline "Pipeline script from SCM" trỏ tới repo, chạy thành công với cả 2 giá trị `TARGET_ENV`.
3. **Trigger:** cấu hình 1 trong 2:
   - GitHub webhook (nếu Jenkins được truy cập từ GitHub, ví dụ qua tunnel do mentor cấp), hoặc
   - Poll SCM `H/5 * * * *` — giải thích ý nghĩa ký tự `H`.
   Chứng minh: push 1 commit → build tự chạy.
4. **Multibranch:** tạo Multibranch Pipeline cho repo. Tạo branch `feature/xyz`, thêm điều kiện `when { branch 'main' }` cho stage `Notify` → chứng minh stage đó chỉ chạy ở `main`.
5. Cố tình làm test fail → quan sát `post { failure }` và trạng thái build. Sau đó sửa lại.
6. ⭐ Tách logic lặp lại vào một Jenkins Shared Library nhỏ (1 hàm `printBuildInfo()`).

## Kết quả cần nộp
`devops-training/08-cicd/lab-02-first-pipeline/`:
- `Jenkinsfile` hoàn chỉnh
- `NOTES.md`: cấu hình job, ảnh chụp Stage View (thành công + thất bại), bằng chứng build tự trigger, multibranch với 2 branch

## Tiêu chí đạt
- [ ] Không còn `TODO` trong Jenkinsfile, pipeline chạy trên agent
- [ ] Parameters hoạt động, `SKIP_TESTS=true` thì stage Test hiển thị "skipped"
- [ ] `VERSION` có dạng `<build>-<sha>` và in ra đúng
- [ ] Push commit → build tự chạy
- [ ] Multibranch phát hiện branch mới, stage `Notify` chỉ chạy trên `main`
- [ ] Workspace được dọn sau build

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Declarative khác scripted pipeline thế nào? Khi nào cần block `script { }`?
2. `environment` khai báo ở mức pipeline và mức stage khác nhau thế nào?
3. Lần đầu thêm `parameters` vào Jenkinsfile, vì sao build đầu tiên chưa hiện form nhập tham số?
4. `H/5 * * * *` khác `*/5 * * * *` thế nào? Vì sao Jenkins khuyến khích `H`?
5. Jenkinsfile nằm trong repo có lợi gì so với cấu hình job trên UI? Rủi ro gì (ai sửa được pipeline)?
6. Thứ tự chạy của các điều kiện trong `post` là gì?

<details>
<summary>Gợi ý</summary>

- Lấy short SHA: `sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()` — đặt trong `script {}` hoặc gán ở `environment` bằng closure.
- Người trigger: plugin *Build User Vars* hoặc `currentBuild.getBuildCauses()`.
- Dùng *Pipeline Syntax* → *Snippet Generator* và *Declarative Directive Generator* ngay trong Jenkins.

</details>

## Tài liệu tham khảo
- https://www.jenkins.io/doc/book/pipeline/syntax/
- https://www.jenkins.io/doc/book/pipeline/multibranch/
- https://www.jenkins.io/doc/book/pipeline/shared-libraries/
