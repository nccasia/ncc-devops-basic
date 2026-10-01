# Lab 14 — Xem lịch sử và events của Docker

> **Module:** 07 Docker

## Mục tiêu
- Dùng logs, events, history, disk usage để vận hành và điều tra sự cố.
- Viết script giám sát event và cảnh báo khi container crash.

## Kiến thức cần có
- Bash script (module 01: BT6 monitor), lab 10.

## Môi trường
- VM Ubuntu có Docker, `jq`.

## Yêu cầu
1. Xem logs của container (theo dõi realtime, lọc theo thời gian, giới hạn số dòng, kèm timestamp)
2. Xem Docker events trong 1 giờ qua (lọc theo container, theo loại event)
3. Xem lịch sử của image
4. Xem disk usage history (`docker system df`, `-v`), dọn dẹp tài nguyên không dùng một cách an toàn

### Commands cần thành thạo
```bash
docker logs [OPTIONS] CONTAINER
docker events [OPTIONS]
docker history IMAGE
docker system df
```

5. Viết script monitor Docker events real-time và alert khi có container crash:
   - Chỉ alert khi container `die` với **exit code ≠ 0** (không alert khi `docker stop` bình thường — kiểm tra lại exit code 143/137 và quyết định cách xử lý, ghi rõ trong NOTES).
   - Nội dung alert: thời gian, tên container, image, exit code, 20 dòng log cuối.
   - Ghi alert ra file log; ⭐ gửi alert qua webhook (Slack/Mezon/Discord/Telegram) — URL webhook lấy từ biến môi trường.
   - Chạy được như một `systemd` service, tự khởi động lại khi script chết.
6. Tạo container "crash" để test: thoát với code 1, bị OOM kill (`--memory`), và container có restart policy liên tục crash.
7. Cấu hình log rotation cho Docker (`/etc/docker/daemon.json`: `max-size`, `max-file`) và giải thích vì sao cần.

## Kết quả cần nộp
Nộp vào `devops-training/07-docker/lab-14-logs-events-history/`:
- `docker-crash-monitor.sh`, `docker-crash-monitor.service`, `daemon.json`
- `NOTES.md`: lệnh + output cho mục 1–4, log alert của 3 kịch bản crash

## Tiêu chí đạt
- [ ] Thành thạo các option chính của 4 lệnh (`-f`, `--since`, `--tail`, `-t`, `--filter`, `--format`)
- [ ] Script alert đúng 3 kịch bản crash, không alert khi stop bình thường
- [ ] Alert chứa đủ thông tin, có log cuối của container
- [ ] Service systemd chạy ổn định, có `Restart=`
- [ ] Log rotation được áp dụng (chứng minh bằng `docker inspect` `LogConfig`)

## Câu hỏi tự kiểm tra

Tự trả lời các câu hỏi sau và ghi câu trả lời vào `NOTES.md`.
1. Log container lưu ở đâu trên host với driver `json-file`? Khi nào `docker logs` không xem được log?
2. App ghi log ra file trong container thay vì stdout/stderr thì có vấn đề gì?
3. Exit code 137, 143, 139, 1 thường có nghĩa gì? Làm sao biết container bị OOM kill?
4. `docker system prune` vs `prune -a` vs `prune --volumes` — xóa những gì? Khi nào nguy hiểm?
5. `daemon.json` thay đổi log option có áp dụng cho container đang chạy không?

<details>
<summary>Gợi ý</summary>

- `docker events --filter event=die --format '{{json .}}'`
- Exit code có trong `.Actor.Attributes.exitCode` của event.
- `docker inspect --format '{{.State.OOMKilled}}'`.

</details>

## Tài liệu tham khảo
- https://docs.docker.com/reference/cli/docker/system/events/
- https://docs.docker.com/engine/logging/drivers/json-file/
- https://docs.docker.com/reference/cli/docker/system/prune/
