# Lab 13 — Hiểu về CMD và ENTRYPOINT

> **Module:** 07 Docker

## Mục tiêu
- Phân biệt `CMD` và `ENTRYPOINT`, shell form và exec form.
- Biết override từng loại và hiểu ảnh hưởng tới PID 1 / signal.

## Kiến thức cần có
- Dockerfile cơ bản, lab 08 (inspect image).

## Môi trường
- VM Ubuntu có Docker.

## Yêu cầu
1. Tìm CMD/ENTRYPOINT mặc định của các images:
   - `alpine`
   - `ubuntu`
   - `nginx`
   - `python`
   - `node`
2. Chạy container không chỉ định command, observe behavior
3. Override CMD vs ENTRYPOINT
4. Tự viết 4 Dockerfile nhỏ cho 4 tổ hợp: chỉ `CMD`, chỉ `ENTRYPOINT`, `ENTRYPOINT` + `CMD` (exec form), `ENTRYPOINT` shell form + `CMD`. Với mỗi image, chạy `docker run img` và `docker run img arg1 arg2`, ghi lại lệnh thực sự được thực thi.
5. Thí nghiệm signal: tạo image chạy một process dài (VD `sleep` hoặc script `trap SIGTERM`) bằng shell form và exec form; đo thời gian `docker stop` ở mỗi trường hợp và giải thích.
6. Viết một `docker-entrypoint.sh` theo pattern phổ biến: làm vài bước khởi tạo rồi `exec "$@"`.

### Câu hỏi
- Image nào không có default command?
- Sự khác biệt giữa CMD và ENTRYPOINT?
- Cách override mỗi loại?

## Kết quả cần nộp
Nộp vào `devops-training/07-docker/lab-13-cmd-vs-entrypoint/`:
- 4 Dockerfile + Dockerfile thí nghiệm signal + `docker-entrypoint.sh`
- `NOTES.md`: bảng CMD/ENTRYPOINT của 5 image, bảng kết quả 4 tổ hợp, số liệu `time docker stop`, trả lời câu hỏi

## Tiêu chí đạt
- [ ] Bảng CMD/ENTRYPOINT 5 image lấy bằng lệnh (có lệnh trong NOTES)
- [ ] Giải thích đúng hành vi khi chạy không có command (VD vì sao `ubuntu` thoát ngay khi không có `-it`)
- [ ] Bảng 4 tổ hợp đúng với tài liệu "Understand how CMD and ENTRYPOINT interact"
- [ ] Số liệu `docker stop` chứng minh khác biệt shell vs exec form
- [ ] `docker-entrypoint.sh` dùng `exec "$@"` và giải thích vì sao cần `exec`

## Câu hỏi tự kiểm tra

Tự trả lời các câu hỏi sau và ghi câu trả lời vào `NOTES.md`.
1. `docker run --entrypoint` override được gì? Truyền tham số cho entrypoint mới thế nào?
2. Shell form `CMD node app.js` thực chất chạy lệnh gì? PID 1 là process nào?
3. Vì sao `docker stop` với shell form thường mất ~10 giây?
4. `tini` / `docker run --init` giải quyết vấn đề gì (zombie, signal)?
5. Image `nginx` có cả `ENTRYPOINT` và `CMD` — mỗi cái làm nhiệm vụ gì?

<details>
<summary>Gợi ý</summary>

- `docker image inspect --format '{{json .Config.Entrypoint}} {{json .Config.Cmd}}' IMAGE`
- `docker exec <c> ps -ef` (hoặc `cat /proc/1/cmdline`) để xem PID 1.

</details>

## Tài liệu tham khảo
- https://docs.docker.com/reference/dockerfile/#understand-how-cmd-and-entrypoint-interact
- https://docs.docker.com/reference/dockerfile/#shell-and-exec-form
- https://github.com/krallin/tini
