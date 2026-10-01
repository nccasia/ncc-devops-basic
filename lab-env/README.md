# Môi trường lab

Hầu hết lab cần 1–3 máy Linux. Chuẩn của khóa: **Ubuntu 22.04**, 3 VM trên cùng mạng private.

| VM | IP | Vai trò thường dùng |
|----|----|---------------------|
| vm1 | 192.168.56.11 | Server: PostgreSQL, Nginx, app, Jenkins… |
| vm2 | 192.168.56.12 | Client được phép truy cập |
| vm3 | 192.168.56.13 | Client bị chặn / máy phụ |

## Cách 1 — Vagrant (khuyến nghị)

Yêu cầu chung: máy có ≥ 8GB RAM, bật ảo hóa (VT-x/AMD-V) trong BIOS, cài [Vagrant](https://developer.hashicorp.com/vagrant/install). Chọn **một** hypervisor:

| Hypervisor | Phù hợp khi | Box | IP `192.168.56.x` | Thư mục `/repo` |
|------------|-------------|-----|-------------------|-----------------|
| **VirtualBox** (mặc định) | Windows/Linux/macOS Intel, chưa dùng hypervisor nào | `bento/ubuntu-22.04` | Tự động | Mount từ máy host |
| **VMware** Workstation/Fusion | Đã có VMware, hoặc macOS Apple Silicon | `bento/ubuntu-22.04` | Tự động | Mount từ máy host |
| **Hyper-V** | Windows Pro/Enterprise đang dùng Hyper-V/WSL2/Docker Desktop | `generic/ubuntu2204` | Qua switch `ncc-lab` (script setup) | `git clone` trong VM |

> Không chạy song song 2 hypervisor dùng cùng dải `192.168.56.0/24` (VD host-only của VirtualBox và switch `ncc-lab` của Hyper-V) — sẽ xung đột route.

### 1a. VirtualBox

1. Cài [VirtualBox](https://www.virtualbox.org/wiki/Downloads) ≥ 7.
2. Trên Windows: nếu VirtualBox báo lỗi VT-x, tắt Hyper-V/"Virtual Machine Platform" hoặc chuyển sang cách 1c.
3. Chạy:

```bash
cd lab-env
vagrant up
```

### 1b. VMware Workstation / Fusion

1. Cài VMware Workstation Pro (Windows/Linux) hoặc VMware Fusion (macOS) — bản cá nhân miễn phí.
2. Cài [Vagrant VMware Utility](https://developer.hashicorp.com/vagrant/install/vmware) và plugin:

```bash
vagrant plugin install vagrant-vmware-desktop
```

3. Chạy:

```bash
cd lab-env
vagrant up --provider=vmware_desktop
```

Trên macOS Apple Silicon, Vagrant tự chọn box `arm64`. Để khỏi gõ `--provider` mỗi lần: `export VAGRANT_DEFAULT_PROVIDER=vmware_desktop`.

### 1c. Hyper-V (Windows)

Hyper-V có 2 điểm khác: Vagrant **không tự đặt IP tĩnh** được, và chia sẻ thư mục cần SMB (phải nhập mật khẩu Windows). Repo đã xử lý sẵn:

- `hyperv/setup-network.ps1` tạo switch nội bộ `ncc-lab` (host là `192.168.56.1`, có NAT ra internet).
- Lần `vagrant up` đầu, VM khởi động trên **Default Switch** (DHCP) để cài gói, clone repo vào `/repo` và ghi cấu hình IP tĩnh. Sau đó trigger trong `Vagrantfile` tự chạy `hyperv/connect-lab-switch.ps1`: chuyển VM sang switch `ncc-lab`, khởi động lại với IP `192.168.56.x`.

Các bước:

1. Bật Hyper-V (PowerShell **Run as Administrator**, cần khởi động lại máy):

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

2. Tạo mạng lab (chỉ làm 1 lần, PowerShell Administrator):

```powershell
cd lab-env
.\hyperv\setup-network.ps1
```

3. Tạo VM — luôn chạy Vagrant trong PowerShell **Administrator** (hoặc thêm user vào nhóm *Hyper-V Administrators*):

```powershell
$env:VAGRANT_DEFAULT_PROVIDER = "hyperv"
vagrant up
```

4. Kiểm tra: `vagrant ssh vm1` → `ip a` phải thấy `192.168.56.11`; `ping vm2`, `curl -I https://github.com` thành công.

Code trong `/repo` của VM là bản clone, **không** tự đồng bộ với máy host. Cập nhật bằng `git -C /repo pull`; file bài làm nên để trong repo cá nhân (clone vào VM) hoặc chép qua `scp`.

### Lệnh Vagrant thường dùng

```bash
vagrant up            # create all 3 VMs (first run downloads the box)
vagrant up vm1        # create/start vm1 only
vagrant status
vagrant ssh vm1       # SSH into vm1 (user vagrant, has sudo)
vagrant halt          # shut down VMs, keep data
vagrant destroy -f    # destroy VMs completely
vagrant provision vm1 # re-run the provisioning script
```

Với VirtualBox/VMware, cả repo được mount vào `/repo` trong mọi VM — chạy script của lab trực tiếp, VD `sudo /repo/01-linux/lab-01-file-permissions/check.sh`. Script cần quyền thực thi: nếu clone trên Windows, chạy bằng `bash <script>` hoặc đảm bảo Git không đổi sang CRLF (`git config core.autocrlf input`).

### Snapshot — làm hỏng thì quay lại

```bash
vagrant snapshot save vm1 clean       # snapshot a clean state before starting a lab
vagrant snapshot list
vagrant snapshot restore vm1 clean    # roll back
vagrant snapshot delete vm1 clean
```

Nên chụp snapshot `clean` ngay sau khi `vagrant up` lần đầu, và chụp thêm trước mỗi lab lớn.

## Cách 2 — VM cloud / VM được cấp

Tạo 3 VM Ubuntu 22.04 cùng VPC/subnet (1 vCPU, 1–2GB RAM). Lưu ý:

- IP sẽ khác bảng trên → thay IP tương ứng khi làm bài, ghi rõ trong `NOTES.md`.
- Cài các gói giống provision trong `Vagrantfile`:
  `sudo apt-get install -y curl wget vim git net-tools acl dnsutils traceroute tcpdump jq unzip htop tree ufw`
- Thêm `vm1`, `vm2`, `vm3` vào `/etc/hosts` của từng máy.
- Ngoài `ufw` còn có **Security Group/Firewall của cloud** — khi không kết nối được, kiểm tra cả hai lớp.
- **Không** mở port database/SSH ra `0.0.0.0/0`. Tắt VM khi không dùng để tiết kiệm chi phí.

## Cách 3 — Chỉ 1 máy (WSL2 / 1 VM)

Đủ cho module 01 (trừ lab-05), 03, 04, 06, 07. Các lab cần nhiều máy (02-database lab-02, lab-03; 01-linux lab-05) bắt buộc dùng cách 1 hoặc 2.

## Sự cố thường gặp

| Hiện tượng | Hướng xử lý |
|------------|-------------|
| `VT-x is not available` (VirtualBox/VMware) | Bật ảo hóa trong BIOS; nếu đang bật Hyper-V thì dùng VirtualBox ≥ 7 / VMware ≥ 16, hoặc chuyển sang Hyper-V (1c) |
| `The IP address configured for the host-only network is not within the allowed ranges` | Dùng dải `192.168.56.0/21` (mặc định) hoặc cấu hình `/etc/vbox/networks.conf` |
| `vagrant up` treo ở `SSH auth method` | Mở VirtualBox GUI xem console, kiểm tra RAM máy host |
| VM không ping được nhau | `ip a` kiểm tra card `eth1`/`enp0s8` có IP chưa, `vagrant reload` |
| `vagrant-vmware-desktop` báo không kết nối được utility | Kiểm tra service *Vagrant VMware Utility* đang chạy, cài lại utility rồi `vagrant plugin repair` |
| Hyper-V: `The provider 'hyperv' requires Administrator privileges` | Mở PowerShell bằng *Run as Administrator* |
| Hyper-V: `Switch 'ncc-lab' not found` | Chưa chạy `hyperv\setup-network.ps1` |
| Hyper-V: `New-NetNat` lỗi | Windows thường chỉ cho 1 NAT; xem `Get-NetNat`, xóa NAT cũ không dùng (`Remove-NetNat`) rồi chạy lại script |
| Hyper-V: VM không lên IP `192.168.56.x` / trigger báo timeout | Mở console VM trong Hyper-V Manager, kiểm tra `ip a`, `cat /etc/netplan/99-ncc-lab.yaml`, chạy `sudo netplan apply` |
| Hyper-V: VM có IP nhưng không ra internet | Kiểm tra `Get-NetNat` còn NAT `ncc-lab-nat`, và `vEthernet (ncc-lab)` có IP `192.168.56.1` |
