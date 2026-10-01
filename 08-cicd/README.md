# 08 — CI/CD (Jenkins, GitHub Actions)

> Công cụ chính: **Jenkins**. GitHub Actions / Azure DevOps học để so sánh.

## Mục tiêu
- Hiểu CI, Continuous Delivery, Continuous Deployment khác nhau thế nào và vì sao cần.
- Tự dựng được Jenkins controller + agent, quản lý user, quyền, credentials an toàn.
- Viết Jenkinsfile declarative: build → test → package (Docker image) → push registry → deploy → smoke test.
- Quản lý version của mỗi lần deploy và rollback được khi lỗi.

## Lý thuyết tự học
- CI/CD: pipeline, artifact, build once – deploy many, immutable artifact, environment promotion (dev → staging → prod).
- Jenkins: kiến trúc controller/agent, executor, workspace, plugin, job types (Freestyle, Pipeline, Multibranch), Jenkinsfile declarative vs scripted.
- Jenkinsfile: `agent`, `stages`, `steps`, `environment`, `parameters`, `when`, `post`, `options`, `input`, `credentials()`, `withCredentials`, `sshagent`, `stash/unstash`, `archiveArtifacts`.
- Trigger: webhook, Poll SCM, cron, upstream job.
- Versioning: semantic versioning, git tag, git short SHA, build number. Chiến lược tag Docker image (vì sao không deploy `latest`).
- Deploy strategy: recreate, rolling, blue/green, canary (mức khái niệm). Rollback và smoke test.
- Bảo mật pipeline: least privilege cho user Jenkins, credentials store, che secret trong log, không chạy build trên controller.
- GitHub Actions: workflow, job, step, runner, secrets, environments, `needs`, matrix. Azure DevOps Pipelines ở mức khái niệm.

Tài liệu: https://www.jenkins.io/doc/book/pipeline/ · https://www.jenkins.io/doc/book/security/ · https://docs.github.com/en/actions

## Môi trường gợi ý

| VM | Vai trò |
|----|---------|
| vm2 `192.168.56.12` | Jenkins controller (+ registry `registry:2` nếu tự host) |
| vm3 `192.168.56.13` | Jenkins agent (build) **và** server deploy target |
| vm1 `192.168.56.11` | Database (từ module 02) |

> Có thể tách deploy target ra VM riêng nếu máy đủ RAM. Jenkins controller cần tối thiểu 2GB RAM.

## Danh sách lab

| Lab | Nội dung |
|-----|----------|
| [lab-01-jenkins-setup](lab-01-jenkins-setup/README.md) | Cài Jenkins, plugin, user/quyền, SSH agent, credentials |
| [lab-02-first-pipeline](lab-02-first-pipeline/README.md) | Jenkinsfile declarative, parameters, post, trigger, multibranch |
| [lab-03-build-test-package](lab-03-build-test-package/README.md) | Build, test, đóng Docker image theo version, push registry |
| [lab-04-deploy-ssh](lab-04-deploy-ssh/README.md) | Deploy qua SSH (systemd & docker compose), approval, smoke test |
| [lab-05-versioning-and-rollback](lab-05-versioning-and-rollback/README.md) | Lịch sử version, rollback tự động & thủ công |
| [lab-06-github-actions](lab-06-github-actions/README.md) ⭐ | Viết lại pipeline bằng GitHub Actions, so sánh với Jenkins |

## Câu hỏi tự kiểm tra cuối module
Tự trả lời trước khi chuyển sang module tiếp theo, ghi câu trả lời vào `devops-training/08-cicd/NOTES.md`.
1. CI, Continuous Delivery, Continuous Deployment khác nhau ở điểm nào? Dự án của bạn đang ở mức nào?
2. Vì sao không nên chạy build trên Jenkins controller (số executor của built-in node nên là 0)?
3. Credentials trong Jenkins được lưu ở đâu, mã hóa thế nào? Làm sao để secret không bị in ra console log?
4. "Build once, deploy many" là gì? Pipeline của bạn có build lại image khi deploy môi trường khác không?
5. Vì sao không deploy tag `latest`? Bạn chọn quy tắc đặt tag image nào và vì sao?
6. Pipeline đang chạy thì agent mất kết nối — chuyện gì xảy ra? Làm sao để deploy không để server ở trạng thái nửa vời?
7. Smoke test khác integration test thế nào? Smoke test của bạn kiểm tra những gì?
8. Rollback ứng dụng thì database migration xử lý thế nào? Thế nào là migration "backward compatible"?
9. Webhook vs Poll SCM: ưu nhược điểm? Khi Jenkins nằm trong mạng nội bộ không nhận được webhook thì làm thế nào?
10. So sánh Jenkins và GitHub Actions: hosting, cấu hình, secrets, chi phí, khi nào chọn cái nào?

## Bài tự luyện debug (break & fix)
Sau khi pipeline của bạn chạy ổn, hãy **tự cố tình làm hỏng** từng thứ dưới đây (mỗi lần một lỗi), chạy lại pipeline, tự chẩn đoán từ console log/log server rồi sửa. Ghi mỗi lần vào `NOTES.md` theo format: **triệu chứng → nguyên nhân → cách sửa**.

- Đổi quyền hoặc xóa private key trong credentials SSH → quan sát stage deploy fail như thế nào.
- Xóa user `jenkins` khỏi group `docker` trên agent rồi chạy stage build image.
- Làm đầy disk agent (`fallocate -l <size> /tmp/bigfile`) → quan sát trạng thái agent và build. Nhớ xóa file sau khi thử.
- Sửa `/health` của app trả 500 rồi chạy pipeline → kiểm tra rollback tự động có hoạt động không.
- Đổi label của agent cho khác label trong Jenkinsfile → quan sát job.
- Làm sai `known_hosts` của target (VD xóa entry rồi thêm host key sai) → quan sát lỗi SSH.
