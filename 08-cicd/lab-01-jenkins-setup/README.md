# Lab 01 — Cài đặt Jenkins, agent và credentials

> **Module:** 08 CI/CD

## Mục tiêu
- Cài và vận hành Jenkins controller như một service production-like.
- Thiết lập user/quyền theo least privilege, không dùng admin để chạy job hằng ngày.
- Kết nối agent qua SSH và chạy build trên agent thay vì controller.
- Quản lý secret bằng Jenkins Credentials.

## Kiến thức cần có
- Module 01 (systemd, user, SSH key), module 07 (Docker) nếu cài Jenkins bằng container.

## Môi trường
- vm2 `192.168.56.12`: Jenkins controller, port 8080.
- vm3 `192.168.56.13`: Jenkins agent.

## Yêu cầu
1. **Cài Jenkins** trên vm2, chọn 1 trong 2 cách và giải thích lý do chọn:
   - Gói `apt` chính thức (Jenkins LTS + OpenJDK 17/21), chạy bằng systemd; hoặc
   - Container `jenkins/jenkins:lts` với volume `jenkins_home` persist, restart policy.
2. Truy cập `http://192.168.56.12:8080`, hoàn tất setup wizard. Cài tối thiểu các plugin: Pipeline, Git, Credentials Binding, SSH Agent, SSH Build Agents, Docker Pipeline, Pipeline Stage View (hoặc Blue Ocean), Role-based Authorization Strategy (hoặc dùng Matrix Authorization).
3. **User và quyền:**
   - Giữ tài khoản `admin` chỉ để quản trị, đặt mật khẩu mạnh.
   - Tạo user `dev-<tên>` chỉ có quyền xem/build job, **không** có quyền Configure System, Manage Credentials, Script Console.
   - Chứng minh: login bằng `dev-<tên>` không vào được *Manage Jenkins*.
4. **Agent qua SSH:**
   - Trên vm3 tạo user `jenkins` (không có sudo), cài Java + Git + Docker, add `jenkins` vào group `docker` (giải thích rủi ro bảo mật của việc này).
   - Tạo SSH keypair dành riêng cho Jenkins, public key đặt vào `~jenkins/.ssh/authorized_keys` trên vm3.
   - Thêm private key vào Jenkins Credentials (kind *SSH Username with private key*), tạo node `agent-vm3` với label `linux docker`, Host Key Verification Strategy **không** dùng "Non verifying".
   - Đặt số executor của built-in node = 0.
5. **Credentials:** tạo thêm 1 credential *Username with password* (giả lập tài khoản registry) và 1 *Secret text*. Viết job thử in secret ra log → quan sát Jenkins che (mask) giá trị thế nào.
6. **Backup:** viết script `backup-jenkins.sh` nén `JENKINS_HOME` (bỏ qua `workspace/`, `caches/`) kèm timestamp. Giải thích những thư mục nào là quan trọng nhất.
7. Mở firewall `ufw` trên vm2: chỉ cho phép 22 và 8080 (từ dải `192.168.56.0/24`).

## Kết quả cần nộp
`devops-training/08-cicd/lab-01-jenkins-setup/`:
- `NOTES.md`: các bước cài đặt, danh sách plugin, ảnh chụp trang Nodes (agent online), ma trận quyền, log job test mask secret
- `backup-jenkins.sh`
- (nếu dùng Docker) `docker-compose.yml` của Jenkins

## Tiêu chí đạt
- [ ] Jenkins chạy lại được sau khi reboot vm2
- [ ] Built-in node có 0 executor, agent `agent-vm3` online với label đúng
- [ ] User dev không có quyền quản trị
- [ ] Private key không xuất hiện trong repo, chỉ nằm trong Jenkins Credentials
- [ ] Secret bị mask (`****`) trong console log
- [ ] Script backup chạy được, file nén không chứa `workspace/`

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Vì sao không nên chạy build trên controller? Nếu một job độc hại chạy trên controller thì nó đọc được gì?
2. `JENKINS_HOME` chứa những gì? Mất `secrets/` thì credentials còn dùng được không?
3. Add user `jenkins` vào group `docker` tương đương cấp quyền gì? Có cách nào an toàn hơn?
4. Host Key Verification Strategy "Non verifying" nguy hiểm thế nào?
5. Jenkins mask secret dựa trên cơ chế gì? Trường hợp nào secret vẫn bị lộ ra log?
6. Agent kết nối kiểu SSH (controller → agent) và kiểu inbound/JNLP (agent → controller) khác nhau thế nào, khi nào dùng kiểu nào?

<details>
<summary>Gợi ý</summary>

- Cài bằng apt: thêm repo `pkg.jenkins.io/debian-stable`, cài Java trước. Mật khẩu khởi tạo ở `/var/lib/jenkins/secrets/initialAdminPassword`.
- Cài bằng Docker: nhớ mount volume cho `/var/jenkins_home`; controller không cần Docker socket nếu build chạy trên agent.
- Host key: dùng "Known hosts file" hoặc "Manually trusted key" — cần `ssh-keyscan` vm3 trước.
- Mask secret: thử `echo $MY_SECRET` trong `withCredentials` và thử `echo $MY_SECRET | base64` — so sánh kết quả.

</details>

## Tài liệu tham khảo
- https://www.jenkins.io/doc/book/installing/linux/
- https://www.jenkins.io/doc/book/installing/docker/
- https://www.jenkins.io/doc/book/managing/nodes/
- https://www.jenkins.io/doc/book/security/controller-isolation/
- https://www.jenkins.io/doc/book/using/using-credentials/
