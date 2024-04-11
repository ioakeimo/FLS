graphical

lang en_US.UTF-8
keyboard --vckeymap=us --xlayouts='us','gr' --switch='grp:alt_shift_toggle'

services --disabled="sshd" --enabled="NetworkManager"
network --bootproto=dhcp --device=link --hostname=fedora --activate
firewall --enabled --service=mdns

timesource --ntp-pool=2.fedora.pool.ntp.org
timezone Europe/Athens --utc

rootpw --lock
selinux --enforcing

bootloader --sdboot --timeout=0

ignoredisk --only-use=nvme0n1
zerombr
clearpart --all --initlabel --disklabel=gpt
autopart

reboot

url --metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch&protocol=https&country=GR,IE,DE,NL

repo --name="rpmfusion-free" --metalink=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-$releasever&arch=$basearch&protocol=https&country=IE,DE,NL
repo --name="rpmfusion-free-updates" --metalink=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-updates-released-$releasever&arch=$basearch&protocol=https&country=IE,DE,NL

repo --name="rpmfusion-nonfree" --metalink=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-$releasever&arch=$basearch&protocol=https&country=IE,DE,NL
repo --name="rpmfusion-nonfree-updates" --metalink=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-updates-released-$releasever&arch=$basearch&protocol=https&country=IE,DE,NL

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
ffmpeg-free
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
EOF

# Mirror management
# Explicitly limit mirrors to https and a selection of countries
sed -ri 's/(^metalink=.*)/\1\&protocol=https\&country=GR,IE,DE,NL/g' /etc/anaconda.repos.d/fedora*
dnf clean all
%end

%post --interpreter=/bin/bash
#!/bin/bash
set -x

# dnf conf
cat >> /etc/dnf/dnf.conf << EOF
max_parallel_downloads=8
install_weak_deps=False
EOF

# Mirror management
# Explicitly limit mirrors to https and a selection of countries
sed -ri 's/(^metalink=.*)/\1\&protocol=https\&country=GR,IE,DE,NL/g' /etc/yum.repos.d/fedora*
dnf clean all

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
