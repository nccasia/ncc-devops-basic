# Lab 10 — Inspect

> **Module:** 07 Docker

## Mục tiêu
- Thành thạo `docker inspect` và Go template của `--format`.
- Liên hệ container với process thật trên host.

## Kiến thức cần có
- Lab 07, 09. Go template cơ bản.

## Môi trường
- VM Ubuntu có Docker.

## Yêu cầu
Chạy container nginx (có publish port, gắn volume, set biến môi trường, đặt restart policy) và dùng `docker inspect` để tìm:
- IP address của container
- MAC address
- Mounted volumes
- Port mappings
- Environment variables
- Network mode
- Restart policy
- Container PID trên host

### Format output
Sử dụng `--format` với script bất kỳ để extract từng thông tin.

Yêu cầu thêm:
1. Script `inspect.sh <container>` in mỗi thông tin trên 1 dòng dạng `KEY: value`, chỉ dùng `--format` (không dùng `jq`) cho phần extract.
2. Xử lý trường hợp container gắn **nhiều network** (IP/MAC phải in đủ từng network).
3. Dùng PID tìm được để chứng minh đó là process nginx trên host (`ps`, `/proc/<pid>`), và xem namespace của nó (`ls -l /proc/<pid>/ns`).
4. ⭐ Viết thêm phiên bản dùng `jq` và so sánh.

## Kết quả cần nộp
Nộp vào `devops-training/07-docker/lab-10-inspect/`:
- `run.sh` (lệnh tạo container), `inspect.sh`
- `NOTES.md`: output script, bằng chứng PID trên host, so sánh namespace với một process thường

## Tiêu chí đạt
- [ ] Đủ 8 thông tin, đúng với thực tế
- [ ] Script không lỗi khi container không có volume/biến môi trường
- [ ] In đúng khi container ở 2 network
- [ ] Chứng minh được PID trên host và namespace khác với host

## Câu hỏi tự kiểm tra

Tự trả lời các câu hỏi sau và ghi câu trả lời vào `NOTES.md`.
1. `{{range}}`, `{{index}}`, `{{json}}`, `{{.Field}}` trong Go template dùng thế nào?
2. Vì sao container có PID 1 bên trong nhưng PID khác trên host?
3. `docker inspect` trên container và trên image khác nhau thế nào?
4. Restart policy `always` vs `unless-stopped` vs `on-failure`?

<details>
<summary>Gợi ý</summary>

- `docker inspect --format '{{json .NetworkSettings.Networks}}' c | jq` để xem cấu trúc trước khi viết template.
- `.State.Pid`, `.HostConfig.RestartPolicy`, `.Mounts`, `.NetworkSettings.Ports`.

</details>

## Tài liệu tham khảo
- https://docs.docker.com/reference/cli/docker/inspect/
- https://docs.docker.com/engine/cli/formatting/
- https://pkg.go.dev/text/template
