# Lab 11 — Extract Layers From an Image

> **Module:** 07 Docker

## Mục tiêu
- Hiểu cấu trúc vật lý của image: manifest, config, layer tarball.
- Hiểu union filesystem: layer sau thêm/sửa/xóa file của layer trước thế nào (whiteout).

## Kiến thức cần có
- Lab 05 (`docker save`), lab 08 (metadata). `tar`, `jq`.

## Môi trường
- VM Ubuntu có Docker, `jq`. Tùy chọn: [`dive`](https://github.com/wagoodman/dive) để đối chiếu.

## Yêu cầu
- Chọn image bất kỳ (ví dụ: `node:18-alpine`)
- List tất cả layers của image
- Extract từng layer ra thư mục riêng
- Xác định mỗi layer thêm/xóa những file gì

Yêu cầu chi tiết:
1. Dùng `docker save` và đọc `manifest.json` để biết thứ tự layer (không đoán theo tên file). Chú ý định dạng mới (OCI layout: `index.json`, `blobs/sha256/`) trên Docker bản mới.
2. Script `extract-layers.sh <image> <outdir>`: extract mỗi layer vào `outdir/layer-<N>/`, in kích thước từng layer.
3. Ghép mỗi layer với dòng tương ứng trong `docker history` (instruction đã tạo ra layer đó).
4. Phát hiện file bị **xóa** ở layer sau qua whiteout file (`.wh.<tên>`, `.wh..wh..opq`).
5. Tự build một image nhỏ có 3 layer: layer tạo file, layer sửa file đó, layer xóa file đó. Chạy script trên image này để chứng minh whiteout.

### Output mong đợi
```
Layer 1: base alpine (5.2MB)
  + /bin, /etc, /lib, ...
Layer 2: node installation (45MB)
  + /usr/local/bin/node
  + /usr/local/lib/node_modules
```

## Kết quả cần nộp
Nộp vào `devops-training/07-docker/lab-11-extract-layers/`:
- `extract-layers.sh`, `Dockerfile.whiteout`
- `NOTES.md`: output với `node:18-alpine` và với image whiteout, giải thích cấu trúc file tar
- **Không** commit thư mục layer đã extract

## Tiêu chí đạt
- [ ] Thứ tự layer lấy từ manifest, đúng với `docker history`
- [ ] Output đúng định dạng mong đợi, có kích thước và mô tả nguồn gốc layer
- [ ] Phát hiện đúng file bị xóa qua whiteout trong image tự build
- [ ] Giải thích được vì sao xóa file ở layer sau không làm image nhỏ đi

## Câu hỏi tự kiểm tra

Tự trả lời các câu hỏi sau và ghi câu trả lời vào `NOTES.md`.
1. `diff_ids` trong config và digest của layer trong manifest khác nhau thế nào (nén vs không nén)?
2. Overlay2 trên host lưu layer ở đâu (`/var/lib/docker/overlay2`)? `lowerdir`, `upperdir`, `merged` là gì?
3. Whiteout và opaque whiteout khác nhau thế nào?
4. Hai image dùng chung base có tốn gấp đôi dung lượng disk không? Vì sao?
5. Lộ secret ở một layer giữa rồi xóa ở layer sau — secret có còn lấy được không? Chứng minh.

<details>
<summary>Gợi ý</summary>

- `mkdir img && docker save node:18-alpine | tar -x -C img && jq . img/manifest.json`
- Một layer là một tarball: `tar -tf` để liệt kê, `tar -xf -C` để extract.
- So sánh với `dive node:18-alpine`.

</details>

## Tài liệu tham khảo
- https://github.com/opencontainers/image-spec/blob/main/layer.md
- https://github.com/opencontainers/image-spec/blob/main/image-layout.md
- https://docs.docker.com/engine/storage/drivers/overlayfs-driver/
- https://github.com/wagoodman/dive
