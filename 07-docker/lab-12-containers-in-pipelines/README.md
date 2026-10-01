# Lab 12 — Containers in Pipelines

> **Module:** 07 Docker

## Mục tiêu
- Dùng container làm môi trường build/test đồng nhất, không cần cài toolchain trên máy build.
- Chuyển script build thành pipeline CI.

## Kiến thức cần có
- Lab 01, Bash script. Có tài khoản Docker Hub (hoặc registry riêng — hỏi mentor nếu cần quyền truy cập).
- Liên quan: [module 08 CI/CD](../../08-cicd/README.md) — lab này là bước đệm, pipeline đầy đủ sẽ làm ở module 08.

## Môi trường
- VM Ubuntu có Docker. App NodeJS của lab 01 (thêm script `build` và `test`).
- Template: [`starter/build.sh`](starter/build.sh).

## Yêu cầu
Tạo pipeline đơn giản với các stages:
- Build: Build ứng dụng trong container
- Test: Chạy tests trong container
- Package: Tạo Docker image
- Push: Push lên registry

Có thể dùng
- GitHub Actions
- Jenkins

Template (shell script):
```bash
#!/bin/bash
# build.sh

# Stage 1: Build
docker run --rm -v $(pwd):/app -w /app node:18 npm run build

# Stage 2: Test
docker run --rm -v $(pwd):/app -w /app node:18 npm test

# Stage 3: Package
docker build -t myapp:$VERSION .

# Stage 4: Push
docker push myapp:$VERSION
```

Yêu cầu chi tiết:
1. Hoàn thiện `build.sh` từ template:
   - Dừng ngay khi một stage lỗi (`set -euo pipefail`), in rõ stage đang chạy.
   - `VERSION` mặc định lấy từ git (`git describe`/short SHA), cho phép override qua env.
   - Tên image có registry/namespace (`docker push myapp:...` trần sẽ thất bại — vì sao?), cấu hình qua biến.
   - File sinh ra từ `npm` trong container không bị owner `root` trên host.
   - Cache `node_modules`/npm cache giữa các lần chạy.
2. Viết ít nhất 1 test thật cho app; làm test fail để chứng minh pipeline dừng, không push.
3. Chuyển thành pipeline trên **GitHub Actions hoặc Jenkins** với 4 stage tương ứng. Credential registry lưu trong secret của CI, không nằm trong code.
4. Push 2 tag: `<version>` và `latest` (hoặc tên branch). Giải thích chiến lược tag.

## Kết quả cần nộp
Nộp vào `devops-training/07-docker/lab-12-containers-in-pipelines/`:
- `build.sh`, app + test, `Dockerfile`, file pipeline (`.github/workflows/*.yml` mẫu hoặc `Jenkinsfile`)
- `NOTES.md`: log pipeline pass, log pipeline fail ở stage test, ảnh image trên registry

## Tiêu chí đạt
- [ ] `./build.sh` chạy được trên máy chỉ có Docker (không cài node)
- [ ] Test fail → pipeline dừng, không có image mới trên registry
- [ ] Không có credential trong code/log
- [ ] File trong workspace sau build không thuộc root
- [ ] Image trên registry có tag version truy vết được về commit

## Câu hỏi tự kiểm tra

Tự trả lời các câu hỏi sau và ghi câu trả lời vào `NOTES.md`.
1. Vì sao build trong container giúp "works on my machine" biến mất?
2. Mount `-v $(pwd):/app` có rủi ro gì về permission? Cách xử lý?
3. Stage build trong container vs multi-stage Dockerfile — khác gì, khi nào chọn cách nào?
4. Jenkins agent chạy trong Docker muốn gọi `docker build` thì làm thế nào (DinD vs mount `docker.sock`)? Rủi ro?
5. Vì sao không nên deploy production bằng tag `latest`?

<details>
<summary>Gợi ý</summary>

- `docker run --user "$(id -u):$(id -g)"`, chú ý biến `HOME`/npm cache khi chạy UID không có trong image.
- `docker login --password-stdin`.
- GitHub Actions: `docker/login-action`, `docker/build-push-action`.

</details>

## Tài liệu tham khảo
- https://docs.docker.com/build/ci/github-actions/
- https://www.jenkins.io/doc/book/pipeline/docker/
- https://docs.docker.com/reference/cli/docker/login/
