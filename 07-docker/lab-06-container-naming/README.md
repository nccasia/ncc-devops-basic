# Lab 06 — Container Naming

> **Module:** 07 Docker

## Mục tiêu
- Xử lý conflict tên container trong script tự động hóa (deploy script, CI).
- Viết script idempotent: chạy nhiều lần cho cùng một kết quả.

## Kiến thức cần có
- Bash script (module 01), `docker ps -a`, `docker rm`.

## Môi trường
- VM Ubuntu có Docker.

## Tình huống
Chạy lệnh sau nhiều lần:

```bash
docker run -d --name myapp nginx
```

Lần thứ 2 trở đi bị lỗi:
```
docker: Error response from daemon: Conflict. The container name "/myapp" is already in use
```

## Yêu cầu
1. Viết script bash tự động xử lý conflict này với 3 cách:
   - Xóa container cũ trước khi tạo mới
   - Tạo tên unique (thêm timestamp/random)
   - Dùng `--rm` flag
2. Giải thích ưu/nhược điểm của mỗi cách
3. Trong môi trường production, cách nào được recommend?
4. Yêu cầu chung cho script:
   - Nhận tham số chọn cách (VD `./run-myapp.sh remove|unique|rm`), báo lỗi + usage khi sai tham số.
   - `set -euo pipefail`, kiểm tra Docker daemon đang chạy.
   - Cách "xóa container cũ": dừng container **gracefully** trước khi xóa, và không lỗi khi container chưa tồn tại.
   - Chạy script 3 lần liên tiếp cho mỗi cách, không lỗi.
5. Với cách tên unique: viết thêm lệnh dọn dẹp các container `myapp-*` cũ, chỉ giữ lại N container mới nhất.

## Kết quả cần nộp
Nộp vào `devops-training/07-docker/lab-06-container-naming/`:
- `run-myapp.sh`, `cleanup.sh`
- `NOTES.md`: output chạy 3 lần mỗi cách, bảng ưu/nhược điểm, đề xuất cho production

## Tiêu chí đạt
- [ ] Mỗi cách chạy 3 lần liên tiếp không lỗi
- [ ] Script có usage, xử lý tham số sai, exit code đúng
- [ ] Cách `--rm` giải thích đúng: `--rm` giải quyết được gì và **không** giải quyết được gì khi container đang chạy
- [ ] Bảng ưu/nhược điểm có tính đến downtime, rác container, log/debug sau khi container chết
- [ ] Đề xuất production có lý lẽ (compose, orchestrator, restart policy…)

## Câu hỏi tự kiểm tra

Tự trả lời các câu hỏi sau và ghi câu trả lời vào `NOTES.md`.
1. `docker stop` vs `docker kill` vs `docker rm -f`? Container có bao nhiêu giây để tắt khi `stop`?
2. Dùng `--rm` thì khi container crash bạn mất gì? Ảnh hưởng thế nào tới việc debug?
3. Xóa container cũ rồi tạo mới gây downtime bao lâu? Làm sao giảm downtime?
4. `docker compose up -d` xử lý chuyện tên container thế nào khi chạy lại nhiều lần?
5. Lọc container theo tên/label bằng `docker ps --filter` như thế nào? Vì sao label đáng tin hơn tên?

<details>
<summary>Gợi ý</summary>

- `docker ps -aq --filter "name=^myapp$"` (chú ý filter `name` là match chuỗi con).
- `date +%Y%m%d%H%M%S`, `$RANDOM`, `openssl rand -hex 4`.

</details>

## Tài liệu tham khảo
- https://docs.docker.com/reference/cli/docker/container/run/
- https://docs.docker.com/reference/cli/docker/container/ls/#filter
