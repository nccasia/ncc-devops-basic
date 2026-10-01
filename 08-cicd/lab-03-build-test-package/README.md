# Lab 03 — Build, test, đóng gói Docker image và push registry

> **Module:** 08 CI/CD

## Mục tiêu
- Xây dựng phần CI hoàn chỉnh: build → test → package → push.
- Gắn version nhất quán cho artifact và Docker image.
- Làm việc với container registry bằng credentials an toàn.

## Kiến thức cần có
- Lab 02, module 07 (Dockerfile multi-stage, lab-12 containers in pipelines).
- App BE từ module 04 (Flask / .NET / Spring Boot) đã có Dockerfile.

## Môi trường
- Jenkins + agent `agent-vm3` (có Docker).
- Registry, chọn 1:
  - Docker Hub **private repository** (tài khoản mentor cấp), hoặc
  - Registry tự host: container `registry:2` trên vm2, port 5000, có **basic auth** (htpasswd). Nếu không dùng TLS phải khai báo `insecure-registries` trên agent và deploy target — ghi rõ đây là cấu hình chỉ dùng cho lab.

## Yêu cầu
1. Chọn **1 BE** từ module 04. Pipeline gồm các stage:
   - `Checkout`
   - `Build`: build app **bên trong container** (VD `maven:3-eclipse-temurin-17`, `mcr.microsoft.com/dotnet/sdk:8.0`, `python:3.12-slim`) — agent không cần cài sẵn SDK.
   - `Test`: chạy unit test, publish kết quả test (JUnit XML) bằng `junit` step để Jenkins hiển thị biểu đồ test.
   - `Package`: `docker build` image.
   - `Push`: login registry bằng credentials, push image, logout.
   - `Archive`: `archiveArtifacts` file artifact (`.jar` / thư mục publish `.zip` / wheel…) kèm `fingerprint: true`.
2. **Versioning** — image được tag đồng thời:
   - `<registry>/<app>:<semver>-<build_number>` (semver đọc từ file `VERSION` trong repo, VD `1.2.0`)
   - `<registry>/<app>:<git_short_sha>`
   - Chỉ khi build trên `main`: thêm tag `latest` (và giải thích vì sao vẫn không dùng `latest` để deploy).
3. Gắn **OCI labels** vào image: `org.opencontainers.image.revision` (git sha), `org.opencontainers.image.version`, `org.opencontainers.image.created` — truyền qua `--build-arg`. Kiểm tra bằng `docker inspect`.
4. Push xong phải xóa image local trên agent để tránh đầy disk (`post { always }`).
5. Test fail → pipeline dừng, **không** được push image.
6. ⭐ Thêm stage `Scan` dùng `trivy image` — fail pipeline khi có lỗ hổng `CRITICAL`.

## Kết quả cần nộp
`devops-training/08-cicd/lab-03-build-test-package/`:
- `Jenkinsfile`, `Dockerfile`, file `VERSION`
- `NOTES.md`: ảnh chụp Stage View, trang Test Result, danh sách tag trên registry (`curl -u ... https://<registry>/v2/<app>/tags/list` hoặc ảnh Docker Hub), output `docker inspect` phần labels
- (nếu tự host) `docker-compose.yml` của registry — **không** nộp file `htpasswd`

## Tiêu chí đạt
- [ ] Agent không cài SDK, build/test chạy trong container
- [ ] Jenkins hiển thị kết quả test (số test pass/fail)
- [ ] Image trên registry có đủ tag theo quy tắc, labels đúng
- [ ] Mật khẩu registry chỉ nằm trong Jenkins Credentials, không xuất hiện trong log
- [ ] Test fail thì không có image mới trên registry
- [ ] Artifact được archive và fingerprint

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Vì sao nên build/test trong container thay vì cài SDK lên agent?
2. Cùng một commit build 2 lần có ra image giống hệt nhau không (digest)? Tag và digest khác nhau thế nào? Deploy theo digest có lợi gì?
3. `docker login` lưu credential ở đâu trên agent? Rủi ro gì và xử lý ra sao?
4. Vì sao `latest` không phù hợp để deploy/rollback?
5. Fingerprint trong Jenkins dùng để làm gì?
6. Cache layer Docker trên agent giúp gì? Khi agent là ephemeral (mỗi build một máy mới) thì cache thế nào?

<details>
<summary>Gợi ý</summary>

- Login an toàn: `withCredentials([usernamePassword(...)])` + `echo "$PASS" | docker login --password-stdin ...` (dùng nháy đơn trong `sh '...'` để Groovy không nội suy secret).
- Plugin Docker Pipeline: `docker.image('maven:...').inside { ... }` và `docker.withRegistry(url, credId) { img.push(tag) }`.
- Maven/dotnet/pytest đều xuất được JUnit XML (`surefire-reports`, `--logger trx` + converter hoặc `JunitXml`, `pytest --junitxml`).

</details>

## Tài liệu tham khảo
- https://www.jenkins.io/doc/book/pipeline/docker/
- https://distribution.github.io/distribution/about/deploying/
- https://github.com/opencontainers/image-spec/blob/main/annotations.md
- https://semver.org/
