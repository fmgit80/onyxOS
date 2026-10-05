#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

# DNF5 Speedup
sed -i '/^\[main\]/a max_parallel_downloads=10' /etc/dnf/dnf.conf

# 1. Abilitazione del repository COPR per DankMaterialShell (DMS) e llama-cpp
echo "--- Abilitazione COPR ---"
dnf -y install dnf-plugins-core
dnf copr enable -y avengemedia/danklinux
dnf copr enable -y avengemedia/dms
dnf copr enable -y sneed/llama-cpp-vulkan

# 2. Installazione dei pacchetti richiesti
echo "--- Installazione pacchetti di sistema ---"
# --- core di WAYLAND & XDG PORTALS ---
dnf install -y \
    wayland-utils \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-wlr \
    lxpolkit \
    gnome-keyring \
    xdg-utils \
    xwayland-satellite \
    xorg-x11-server-Xwayland
# --- AUDIO & PIPEWIRE ---
dnf install -y \
    pipewire \
    pipewire-utils \
    pipewire-alsa \
    pipewire-jack-audio-connection-kit \
    pipewire-pulseaudio \
    wireplumber \
    pavucontrol
# --- GRAFICA (MESA & VULKAN) ---
dnf install -y \
    mesa-dri-drivers \
    mesa-vulkan-drivers \
    vulkan-loader \
    vulkan-tools \
    clinfo
# --- RETE, WI-FI & BLUETOOTH ---
dnf install -y \
    NetworkManager \
    NetworkManager-wifi \
    linux-firmware \
    iwlwifi-mvm-firmware \
    iwlwifi-dvm-firmware \
    iwlwifi-mld-firmware \
    iwlegacy-firmware \
    bluez \
    bluez-tools \
    blueman
# --- DESKTOP ENVIRONMENT (NIRI + NOCTALIA) ---
dnf install -y \
    meson gcc-c++ just \
    wayland-devel wayland-protocols-devel \
    libEGL-devel mesa-libGLES-devel \
    freetype-devel fontconfig-devel \
    cairo-devel pango-devel harfbuzz-devel \
    libxkbcommon-devel glib2-devel \
    libsecret-devel libsodium-devel \
    sdbus-cpp-devel pipewire-devel wireplumber-devel \
    pam-devel polkit-devel libcurl-devel libwebp-devel \
    libjxl-devel libsndfile-devel librsvg2-devel \
    libqalculate-devel libxml2-devel \
    md4c-devel tomlplusplus-devel \
    json-devel stb_image_resize2-devel stb_image_write-devel \
    jemalloc-devel \
    gdm \
    niri \
    dms \
    quickshell \
    matugen cliphist danksearch dgop dankcalendar-git
# --- UTILITY AGGIUNTIVE E COMPATIBILITÀ ---
dnf install -y \
    alacritty \
    kitty \
    cliphist \
    wl-clipboard
# --- PODMAN ---
dnf install -y \
    shadow-utils slirp4netns fuse-overlayfs \
    podman \
    podman-compose
# --- DOCKER ---
dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
dnf remove -y docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine
dnf install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    docker-ce-rootless-extras
# --- LLAMA-CPP ---
dnf install -y \
    llama-cpp \

# 3. Abilitazione dei servizi di sistema essenziali
systemctl enable gdm
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable podman.socket
systemctl enable docker
echo "--- Abilitazione servizi utente globali ---"
mkdir -p /usr/lib/systemd/user/graphical-session.target.wants

# Abilita LXPolkit per la sessione grafica
ln -s /usr/lib/systemd/user/lxpolkit.service /usr/lib/systemd/user/graphical-session.target.wants/lxpolkit.service
# Se niri e dms espongono dei servizi systemd utente propri, abilitali così:
if [ -f /usr/lib/systemd/user/niri.service ]; then
    ln -s /usr/lib/systemd/user/niri.service /usr/lib/systemd/user/graphical-session.target.wants/niri.service
fi

if [ -f /usr/lib/systemd/user/dms.service ]; then
    ln -s /usr/lib/systemd/user/dms.service /usr/lib/systemd/user/graphical-session.target.wants/dms.service
fi

# 4. Configurazione Automatica dei dotfiles in /etc/skel
mkdir -p /etc/skel/.config/niri
cp -rf /ctx/dot_config/niri/config.kdl /etc/skel/.config/niri/
mkdir -p /etc/skel/.config/noctalia
cp -rf /ctx/dot_config/noctalia /etc/skel/.config/noctalia
mkdir -p /etc/skel/.config/kitty
cp -rf /ctx/dot_config/kitty /etc/skel/.config/kitty

# 5. Installazione e configurazione del Display Manager (sddm)
#systemctl enable sddm

# 7. Installazione di NetBird
#cat > /etc/yum.repos.d/netbird.repo <<EOF
#[netbird]
#name=netbird
#baseurl=https://pkgs.netbird.io/yum/
#enabled=1
#gpgcheck=1
#gpgkey=https://pkgs.netbird.io/yum/repodata/repomd.xml.key
#repo_gpgcheck=1
#EOF
#dnf install -y netbird
#systemctl enable netbird

# 8. Installa il pacchetto Flatpak di sistema
dnf -y install flatpak
flatpak remote-add --system --if-not-exists flathub https://flathub.org
if flatpak remote-list | grep -q "fedora"; then
    flatpak remote-delete fedora
fi

# 9. CONFIGURAZIONE XDG DESKTOP PORTALS PER NIRI ---
#mkdir -p /etc/skel/.config/xdg-desktop-portal
#cat > /etc/skel/.config/xdg-desktop-portal/niri-portals.conf << 'EOF'
#[preferred]
#default=gtk
#org.freedesktop.impl.portal.ScreenCast=gnome
#org.freedesktop.impl.portal.Screenshot=gnome
#org.freedesktop.impl.portal.Secret=gnome-keyring
#EOF
#ln -sf niri-portals.conf /etc/skel/.config/xdg-desktop-portal/portals.conf

# 10. Pulizia della cache per ridurre il peso dell'immagine finale
dnf clean all
rm -rf /tmp/* /var/tmp/*
rm -rf /run/dnf /run/selinux-policy
rm -rf /var/lib/dnf
