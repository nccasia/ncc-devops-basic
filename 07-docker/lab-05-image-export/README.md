# Lab 05 — Image Export

> **Module:** 07 Docker

## Mục tiêu
- Chuyển image giữa các máy không có registry (môi trường offline/air-gapped).
- Phân biệt `docker save/load` với `docker export/import`.

## Kiến thức cần có
- Image vs container, layer.

## Môi trường
- VM Ubuntu có Docker, có internet để pull lần đầu.

## Yêu cầu
1. Pull image `nginx:alpine`
2. Export image ra file `nginx-alpine.tar`
3. Xóa image khỏi local
4. Import lại image từ file
5. Chạy container từ image vừa import, truy cập được trang mặc định của nginx
6. Làm lại với cặp `docker export` (từ một container) / `docker import`, chạy container từ image đó và ghi lại điều gì khác biệt (lệnh chạy, metadata, số layer).
7. Nén file tar bằng `gzip`, load trực tiếp từ file nén. So sánh kích thước.

### Câu hỏi bổ sung
- Sự khác biệt giữa `docker save` và `docker export`?
- Khi nào nên dùng cách nào?
- File tar chứa những gì?

## Kết quả cần nộp
Nộp vào `devops-training/07-docker/lab-05-image-export/`:
- `NOTES.md`: lệnh từng bước, output `docker images`, `tar -tf` của 2 file tar, so sánh `docker history` của image sau `load` và sau `import`, trả lời 3 câu hỏi
- **Không** commit file `.tar`

## Tiêu chí đạt
- [ ] Container chạy từ image đã `load` truy cập được nginx
- [ ] Chỉ ra được image từ `import` mất những gì (CMD, ENV, EXPOSE, lịch sử layer…) và cách chạy được nó
- [ ] Liệt kê đúng thành phần trong tar của `save` (manifest, config, layers) và tar của `export`
- [ ] Nêu được use case thực tế cho từng cách

## Câu hỏi tự kiểm tra

Tự trả lời các câu hỏi sau và ghi câu trả lời vào `NOTES.md`.
1. `docker save` một image nhiều tag thì giữ được tag không? Save nhiều image vào một file được không?
2. Vì sao image sau `import` chỉ còn 1 layer?
3. `docker export` có lấy dữ liệu trong volume không?
4. Trong thực tế, muốn chuyển image sang server không có internet, bạn làm quy trình thế nào? Còn cách nào khác (private registry)?

<details>
<summary>Gợi ý</summary>

- `docker save -o`, `docker load -i`, `docker export`, `docker import --change`.
- `tar -tvf file.tar | head`.

</details>

## Tài liệu tham khảo
- https://docs.docker.com/reference/cli/docker/image/save/
- https://docs.docker.com/reference/cli/docker/container/export/
- https://docs.docker.com/reference/cli/docker/image/import/
