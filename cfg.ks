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

ignoredisk --only-use=nvme0n1|vd*
zerombr
clearpart --all --initlabel --disklabel=gpt
autopart

reboot

url --metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch&protocol=https&country=GR,IE,DE,NL
repo --name="updates"
repo --name="fedora-cisco-openh264"

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
%end

%pre --interpreter=/bin/bash --log=/tmp/kickstart-preinstallation.log
echo "=================================="
echo "Running pre-installation scripts:"
echo "=================================="

echo "Writing dnf configuration..."
cat >> /etc/dnf/dnf.conf << EOF
max_parallel_downloads=8
install_weak_deps=False
EOF

# Mirror management
echo "Explicitly limiting mirrors to https and a selection of countries..."
set -x
sed -ri 's/(^metalink=.*)/\1\&protocol=https\&country=GR,IE,DE,NL/g' /etc/anaconda.repos.d/fedora*
{ set +x; } 2> /dev/null

echo "Cleaning dnf caches..."
set -x
dnf clean all
{ set +x; } 2> /dev/null

echo "Pre-installation scripts done."
%end

%post --interpreter=/bin/bash --log=/root/kickstart-postinstallation.log
echo "Copying pre-installation script logs to target system..."
cat > /root/kickstart-preinstallation.log << EOF
%include /tmp/kickstart-preinstallation.log
EOF

echo "=================================="
echo "Running post-installation scripts:"
echo "=================================="

echo "Writing dnf configuration..."
cat >> /etc/dnf/dnf.conf << EOF
max_parallel_downloads=8
install_weak_deps=False
EOF

# Mirror/Repo management
echo "Removing unneeded pre-existing repositories..."
set -x
for repomatch in "copr" "nvidia" "steam" "google"; do
  rm -f /etc/yum.repos.d/*"$repomatch"*
done

for testrepo in /etc/yum.repos.d/*testing*; do
  rm -f "$testrepo"
done
{ set +x; } 2> /dev/null

echo "Explicitly limiting mirrors to https and a selection of countries in target system..."
set -x
sed -ri 's/(^metalink=.*)/\1\&protocol=https\&country=GR,IE,DE,NL/g' /etc/yum.repos.d/fedora*
{ set +x; } 2> /dev/null

echo "Setting up additional repositories:"
echo "Setting up RPMFusion Free (and Updates) repository..."
cat > /etc/yum.repos.d/rpmfusion-free.repo << EOF
[rpmfusion-free]
name=RPM Fusion for Fedora \$releasever - Free
metalink=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-\$releasever&arch=\$basearch&protocol=https&country=GR,IE,DE,NL
enabled=1
type=rpm-md
gpgcheck=1
repo_gpgcheck=0
gpgkey=file:///usr/share/distribution-gpg-keys/rpmfusion/RPM-GPG-KEY-rpmfusion-free-fedora-\$releasever
includepkgs=ffmpeg,ffmpeg-libs,libavdevice,x264-libs,x265-libs

[rpmfusion-free-updates]
name=RPM Fusion for Fedora \$releasever - Free - Updates
metalink=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-updates-released-\$releasever&arch=\$basearch&protocol=https&country=GR,IE,DE,NL
enabled=1
type=rpm-md
gpgcheck=1
repo_gpgcheck=0
gpgkey=file:///usr/share/distribution-gpg-keys/rpmfusion/RPM-GPG-KEY-rpmfusion-free-fedora-\$releasever
includepkgs=ffmpeg,ffmpeg-libs,libavdevice,x264-libs,x265-libs

EOF


echo "Setting up RPMFusion NonFree (and Updates) repository..."
cat > /etc/yum.repos.d/rpmfusion-nonfree.repo << EOF
[rpmfusion-nonfree]
name=RPM Fusion for Fedora \$releasever - Nonfree
metalink=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-\$releasever&arch=\$basearch&protocol=https&country=GR,IE,DE,NL
enabled=1
enabled_metadata=1
type=rpm-md
gpgcheck=1
repo_gpgcheck=0
gpgkey=file:///usr/share/distribution-gpg-keys/rpmfusion/RPM-GPG-KEY-rpmfusion-nonfree-fedora-\$releasever
includepkgs=intel-media-driver

[rpmfusion-nonfree-updates]
name=RPM Fusion for Fedora \$releasever - Nonfree - Updates
metalink=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-updates-released-\$releasever&arch=\$basearch&protocol=https&country=GR,IE,DE,NL
enabled=1
type=rpm-md
gpgcheck=1
repo_gpgcheck=0
gpgkey=file:///usr/share/distribution-gpg-keys/rpmfusion/RPM-GPG-KEY-rpmfusion-nonfree-fedora-\$releasever
includepkgs=intel-media-driver

EOF


echo "Setting up Microsoft VSCode repository..."
cat > /etc/yum.repos.d/vscode.repo << EOF
[vscode]
name=Microsoft VSCode
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=file:///usr/share/distribution-gpg-keys/microsoft/microsoft.gpg

EOF


echo "Setting up  Brave Browser repository..."
cat > /etc/yum.repos.d/brave-browser.repo << EOF
[brave-browser]
name=Brave Browser
baseurl=https://brave-browser-rpm-release.s3.brave.com/\$basearch
enabled=1
gpgcheck=1
gpgkey=file:///usr/share/distribution-gpg-keys/brave/brave-core.asc

EOF


echo "Importing GPG keys for installed repositories..."
set -x
rpmkeys --import /usr/share/distribution-gpg-keys/rpmfusion/RPM-GPG-KEY-rpmfusion-free-fedora-$(rpm -E %fedora)
rpmkeys --import /usr/share/distribution-gpg-keys/rpmfusion/RPM-GPG-KEY-rpmfusion-nonfree-fedora-$(rpm -E %fedora)
rpmkeys --import /usr/share/distribution-gpg-keys/microsoft/microsoft.gpg
rpmkeys --import /usr/share/distribution-gpg-keys/brave/brave-core.asc
{ set +x; } 2> /dev/null


echo "Cleaning and refreshing dnf caches..."
set -x
dnf clean all
dnf -y check-update --refresh
{ set +x; } 2> /dev/null

echo "Installing packages..."
set -x
dnf -y swap ffmpeg-free ffmpeg --allowerasing
dnf -y install intel-media-driver code brave-browser
{ set +x; } 2> /dev/null

echo "Writting dns configuration through systemd-resolved..."
set -x
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
{ set +x; } 2> /dev/null

echo "Post-installation scripts done."
%end
