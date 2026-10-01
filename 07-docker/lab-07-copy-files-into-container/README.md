# Lab 07 — Putting a File Into a Running Container

> **Module:** 07 Docker

## Mục tiêu
- Copy file/thư mục giữa host và container.
- Hiểu vì sao thay đổi trong container layer không bền vững và cách làm cho bền vững.

## Kiến thức cần có
- Container layer, volume, bind mount.

## Môi trường
- VM Ubuntu có Docker, image `nginx`.

## Mô tả
Copy file vào container đang chạy.

## Yêu cầu
1. Chạy container nginx
2. Tạo file `index.html` trên host với nội dung tùy ý
3. Copy file vào container thay thế `/usr/share/nginx/html/index.html`
4. Verify bằng cách truy cập nginx

### Bổ sung
- Copy ngược file từ container ra host
- Copy cả thư mục
- Làm sao để thay đổi persist sau khi container restart?
5. Kiểm tra cụ thể: thay đổi còn hay mất khi (a) `docker restart`, (b) `docker rm` rồi `docker run` lại. Giải thích.
6. Làm cho thay đổi bền vững bằng **3 cách**: bind mount, named volume, build image mới (`Dockerfile` hoặc `docker commit`). So sánh.
7. Kiểm tra owner/permission của file sau khi `docker cp` vào container.

## Kết quả cần nộp
Nộp vào `devops-training/07-docker/lab-07-copy-files-into-container/`:
- `index.html`, `Dockerfile` (cách build image)
- `NOTES.md`: lệnh + output từng bước, kết quả thí nghiệm restart/rm, bảng so sánh 3 cách persist

## Tiêu chí đạt
- [ ] `curl localhost:<port>` trả về nội dung `index.html` mới
- [ ] Copy file và thư mục theo cả 2 chiều
- [ ] Kết quả thí nghiệm restart vs rm đúng và giải thích được
- [ ] Demo đủ 3 cách persist, nêu được khi nào dùng cách nào
- [ ] Nêu được vì sao `docker commit` không được khuyến khích

## Câu hỏi tự kiểm tra

Tự trả lời các câu hỏi sau và ghi câu trả lời vào `NOTES.md`.
1. `docker cp` hoạt động được với container đã stop không?
2. `docker diff` cho biết gì? Chạy nó sau khi copy file.
3. Mount bind vào `/usr/share/nginx/html` thì các file có sẵn trong image ở thư mục đó đi đâu? Named volume rỗng thì sao?
4. Vì sao sửa file trực tiếp trong container production là bad practice?

<details>
<summary>Gợi ý</summary>

- `docker cp SRC CONTAINER:DEST`, `docker cp CONTAINER:SRC DEST`.
- Chú ý cú pháp `dir/.` khi copy nội dung thư mục.

</details>

## Tài liệu tham khảo
- https://docs.docker.com/reference/cli/docker/container/cp/
- https://docs.docker.com/engine/storage/volumes/
- https://docs.docker.com/engine/storage/bind-mounts/
