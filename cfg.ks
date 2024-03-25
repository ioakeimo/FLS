# Use graphical install
graphical

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us','gr' --switch='grp:alt_shift_toggle'
# System language
lang en_US.UTF-8

# Network information
network --bootproto=dhcp --device=link --hostname=zenbook --activate

# Firewall configuration
firewall --enabled --service=mdns

# System timezone
timesource --ntp-pool=2.fedora.pool.ntp.org
timezone Europe/Athens --utc

# Shutdown after installation
shutdown

# SELinux configuration
selinux --enforcing

# Do not configure the X Window System
skipx

# Use systemd-boot instead of GRUB
bootloader --sdboot --timeout=0

# Disk and partitioning
ignoredisk --only-use=nvme0n1
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel --disklabel=gpt
autopart

# System services
services --disabled="sshd" --enabled="NetworkManager,ModemManager"

# Use network installation
url --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch"
# Repos
repo --name="Fedora $releasever - $basearch" --metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
repo --name="Fedora $releasever - $basearch - Updates" --metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch
repo --name="Fedora $releasever - $basearch - Test Updates" --metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-f$releasever&arch=$basearch

repo --name="Fedora $releasever openh264 (From Cisco) - $basearch" --metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-cisco-openh264-$releasever&arch=$basearch

repo --name="RPM Fusion for Fedora $releasever - Free" --metalink=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-$releasever&arch=$basearch
repo --name="RPM Fusion for Fedora $releasever - Free - Updates" --metalink=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-updates-released-$releasever&arch=$basearch
repo --name="RPM Fusion for Fedora $releasever - Free - Test Updates" --metalink=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-updates-testing-$releasever&arch=$basearch

repo --name="RPM Fusion for Fedora $releasever - Nonfree" --metalink=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-$releasever&arch=$basearch
repo --name="RPM Fusion for Fedora $releasever - Nonfree - Updates" --metalink=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-updates-released-$releasever&arch=$basearch
repo --name="RPM Fusion for Fedora $releasever - Nonfree - Test Updates" --metalink=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-updates-testing-$releasever&arch=$basearch

%packages
@^kde-desktop-environment

# Remove unneeded packages
-akonadi*
-krfb
-mariadb*
-kwrite

# Add software
git 
vim
vlc
chromium
gwenview
foliate

# Add media codecs
ffpmeg-free
libavcodec-freeworld
intel-media-driver
%end

%pre
#!/bin/bash
set -x

# dnf conf
cat >> /etc/dnf/dnf.conf << EOF
max_parallel_downloads=8
install_weak_deps=False
deltarpm=False
ip_resolve=4
excludepkgs=xorg-x11-*
EOF
%end

%post --interpreter=/bin/bash
#!/bin/bash
set -x

# dnf conf
cat >> /etc/dnf/dnf.conf << EOF
max_parallel_downloads=8
install_weak_deps=False
deltarpm=False
excludepkgs=xorg-x11-*
EOF

# dns conf
install -o root -g root -m 0755 -d /etc/systemd/resolved.conf.d
cat > /etc/systemd/resolved.conf.d/privacy.conf << EOF
# Quad9 IP Adress Configuration Used: ============================
# Secured w/ECS: Malware blocking, DNSSEC Validation, ECS enabled
# IPv4 ============
# 9.9.9.11
# 149.112.112.11
# IPv6 ============
# 2620:fe::11
# 2620:fe::fe:11
# ================================================================

# Cloudflare IP Adress Configuration Used: =======================
# Block malware
# IPv4 ============
# 1.1.1.2
# 1.0.0.2
# IPv6 ============
# 2606:4700:4700::1112
# 2606:4700:4700::1002
# ================================================================

[Resolve]
DNS=9.9.9.11 2620:fe::11 149.112.112.11 2620:fe::fe:11
FallbackDNS=1.1.1.2 2606:4700:4700::1112 1.0.0.2 2606:4700:4700::1002
DNSSEC=allow-downgrade
DNSOverTLS=opportunistic
Domains=~.

EOF

# Disable rpmfusion repositories after initial installation
dnf config-manager --disable rpmfusion-\*
%end