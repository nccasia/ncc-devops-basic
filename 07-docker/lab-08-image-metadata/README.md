# Lab 08 — Lấy thông tin metadata của Docker image

> **Module:** 07 Docker

## Mục tiêu
- Đọc metadata của image: config, layer, history.
- Viết script xử lý JSON bằng `jq`.

## Kiến thức cần có
- `docker image inspect`, `docker history`, `jq` cơ bản.

## Môi trường
- VM Ubuntu có Docker, `jq`. Tùy chọn: `skopeo` hoặc `crane` để đọc metadata trên registry mà không cần pull.

## Yêu cầu
Từ image `python:3.11-slim`, tìm các thông tin sau:
- Base image là gì?
- WORKDIR mặc định
- Exposed ports
- Environment variables được set sẵn
- CMD/ENTRYPOINT mặc định
- Kích thước các layers
- Ngày tạo image

### Output format
Tạo script xuất ra JSON chứa tất cả thông tin trên.

Yêu cầu thêm cho script:
1. Nhận tên image làm tham số: `./image-meta.sh python:3.11-slim`. Tự pull nếu image chưa có local.
2. Output JSON hợp lệ (kiểm tra bằng `jq .`), các trường rỗng trả `null`/`[]` thay vì lỗi. Gợi ý cấu trúc:
   ```json
   {
     "image": "python:3.11-slim",
     "id": "sha256:...",
     "created": "...",
     "architecture": "amd64",
     "base_image": "...",
     "workdir": "...",
     "exposed_ports": [],
     "env": {},
     "entrypoint": null,
     "cmd": ["python3"],
     "total_size_bytes": 0,
     "layers": [{ "created_by": "...", "size_bytes": 0 }]
   }
   ```
3. Chạy script với ít nhất 3 image khác: `nginx:alpine`, `node:18-alpine`, `alpine`.
4. ⭐ Lấy cùng thông tin trực tiếp từ registry bằng `skopeo inspect --config` hoặc `crane config` (không pull).

## Kết quả cần nộp
Nộp vào `devops-training/07-docker/lab-08-image-metadata/`:
- `image-meta.sh`
- `output/*.json` cho 4 image
- `NOTES.md`: cách xác định base image và giải thích vì sao thông tin này không có sẵn trực tiếp

## Tiêu chí đạt
- [ ] Script chạy được với image bất kỳ, output JSON hợp lệ
- [ ] Đủ 7 thông tin được yêu cầu
- [ ] Kích thước layer khớp với `docker history`
- [ ] Giải thích được cách suy ra base image (history, label OCI, Dockerfile gốc trên GitHub…)

## Câu hỏi tự kiểm tra

Tự trả lời các câu hỏi sau và ghi câu trả lời vào `NOTES.md`.
1. Image ID, digest (`RepoDigests`) và tag khác nhau thế nào? Cái nào bất biến?
2. Vì sao một số dòng trong `docker history` có size `0B`? Dòng `<missing>` nghĩa là gì?
3. `Created` của image là ngày build hay ngày bạn pull?
4. Image multi-arch (manifest list) là gì? `docker image inspect` trả về kiến trúc nào?
5. Label `org.opencontainers.image.*` dùng để làm gì?

<details>
<summary>Gợi ý</summary>

- `docker image inspect IMAGE | jq '.[0].Config'`
- `docker history --no-trunc --format '{{json .}}' IMAGE`
- `jq -n --arg ... --argjson ...` để dựng JSON.

</details>

## Tài liệu tham khảo
- https://docs.docker.com/reference/cli/docker/image/inspect/
- https://jqlang.github.io/jq/manual/
- https://github.com/containers/skopeo
- https://github.com/google/go-containerregistry/tree/main/cmd/crane
- https://github.com/opencontainers/image-spec/blob/main/annotations.md
