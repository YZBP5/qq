#!/usr/bin/env bash
# qual_exam_menu.sh
# Интерактивная шпаргалка-скрипт для квалификационного экзамена на Ubuntu Desktop/Server.
# Запуск: chmod +x qual_exam_menu.sh && sudo ./qual_exam_menu.sh

set -o pipefail

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
[ -z "$REAL_HOME" ] && REAL_HOME="$HOME"
LOG_DIR="/opt/qual_exam"
BACKUP_DIR="$LOG_DIR/backups"
LOG_FILE="$LOG_DIR/report.txt"
APT_UPDATED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "Нужны права администратора. Перезапускаю через sudo..."
  exec sudo bash "$0" "$@"
fi

mkdir -p "$LOG_DIR" "$BACKUP_DIR"
touch "$LOG_FILE"

log() {
  echo "[$(date '+%F %T')] $*" | tee -a "$LOG_FILE"
}

ok() {
  echo -e "${GREEN}[OK]${NC} $*"
  log "OK: $*"
}

warn() {
  echo -e "${YELLOW}[!]${NC} $*"
  log "WARN: $*"
}

fail() {
  echo -e "${RED}[ERR]${NC} $*"
  log "ERR: $*"
}

run() {
  log "CMD: $*"
  bash -c "$*" 2>&1 | tee -a "$LOG_FILE"
  local rc=${PIPESTATUS[0]}
  if [ "$rc" -ne 0 ]; then
    warn "Команда завершилась с кодом $rc: $*"
  fi
  return "$rc"
}

pause() {
  echo
  read -rp "Нажми Enter для продолжения..." _
}

apt_update_once() {
  if [ "$APT_UPDATED" -eq 0 ]; then
    run "apt update"
    APT_UPDATED=1
  fi
}

apt_install() {
  apt_update_once
  DEBIAN_FRONTEND=noninteractive run "apt install -y $*"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

header() {
  clear
  echo -e "${BLUE}============================================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}============================================================${NC}"
  echo "Отчёт пишется сюда: $LOG_FILE"
  echo
}

append_report_block() {
  {
    echo
    echo "===== $1 ====="
    shift
    "$@"
  } >> "$LOG_FILE" 2>&1
}

safe_backup_file() {
  local f="$1"
  if [ -f "$f" ] && [ ! -f "$f.bak_qual" ]; then
    cp -a "$f" "$f.bak_qual"
    log "Backup file: $f -> $f.bak_qual"
  fi
}

run_as_real_user() {
  local cmd="$*"
  sudo -u "$REAL_USER" bash -lc "$cmd"
}

run_gsettings() {
  local cmd="$*"
  local uid
  uid="$(id -u "$REAL_USER")"
  sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" bash -lc "$cmd" 2>&1 | tee -a "$LOG_FILE"
}

create_desktop_shortcuts() {
  apt_install xdg-user-dirs || true
  local desktop_dir
  desktop_dir="$(sudo -u "$REAL_USER" xdg-user-dir DESKTOP 2>/dev/null || true)"
  [ -z "$desktop_dir" ] && desktop_dir="$REAL_HOME/Desktop"
  mkdir -p "$desktop_dir"
  chown "$REAL_USER:$REAL_USER" "$desktop_dir"

  local files=(
    /usr/share/applications/codeblocks.desktop
    /usr/share/applications/blender.desktop
    /usr/share/applications/virtualbox.desktop
    /var/lib/snapd/desktop/applications/android-studio_android-studio.desktop
    /var/lib/snapd/desktop/applications/eclipse_eclipse.desktop
    /usr/share/applications/gufw.desktop
    /usr/share/applications/org.gnome.Terminal.desktop
  )

  for f in "${files[@]}"; do
    if [ -f "$f" ]; then
      cp "$f" "$desktop_dir/" 2>/dev/null || true
    fi
  done
  chown -R "$REAL_USER:$REAL_USER" "$desktop_dir" 2>/dev/null || true
  chmod +x "$desktop_dir"/*.desktop 2>/dev/null || true
  ok "Ярлыки установленных программ скопированы на рабочий стол пользователя $REAL_USER"
}

install_kernel_utils() {
  header "1. Утилиты ядра, драйверы и службы"
  apt_install linux-tools-common linux-tools-generic sysstat cpufrequtils tuned ubuntu-drivers-common lshw pciutils usbutils inxi || true
  # Пакет linux-tools под конкретное ядро может отсутствовать — это нормально.
  apt_install "linux-tools-$(uname -r)" || true

  cat >/etc/sysctl.d/99-qual-exam.conf <<'SYSCTL'
# Безопасные параметры ядра для демонстрации настройки ОС на экзамене
vm.swappiness=10
fs.inotify.max_user_watches=524288
net.ipv4.tcp_syncookies=1
kernel.dmesg_restrict=1
SYSCTL
  run "sysctl --system"

  if systemctl list-unit-files | grep -q '^tuned.service'; then
    run "systemctl enable --now tuned"
    run "tuned-adm profile balanced"
    append_report_block "tuned profile" tuned-adm active
  fi

  append_report_block "kernel" uname -a
  append_report_block "sysctl qual" cat /etc/sysctl.d/99-qual-exam.conf
  append_report_block "drivers" ubuntu-drivers devices
  append_report_block "hardware lshw short" lshw -short

  echo
  read -rp "Поставить рекомендованные драйверы через ubuntu-drivers autoinstall? Обычно в VirtualBox НЕ нужно. [y/N]: " ans
  if [[ "$ans" =~ ^[YyДд]$ ]]; then
    run "ubuntu-drivers autoinstall"
  else
    warn "Автоустановка драйверов пропущена — для VirtualBox это безопаснее."
  fi
  ok "Критерий: использованы специальные утилиты для настройки ядра/драйверов."
  pause
}

setup_ssh() {
  header "2. Настройка SSH"
  apt_install openssh-server ufw

  mkdir -p /etc/ssh/sshd_config.d
  cat >/etc/ssh/sshd_config.d/99-qual-exam.conf <<'SSHD'
# Экзаменационная базовая настройка SSH
Port 22
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
X11Forwarding yes
AllowTcpForwarding yes
ClientAliveInterval 300
ClientAliveCountMax 2
SSHD

  run "sshd -t"
  run "systemctl enable --now ssh || systemctl enable --now sshd"
  run "systemctl reload ssh || systemctl reload sshd"
  run "ufw allow OpenSSH"
  run "ufw --force enable"

  append_report_block "ssh status" systemctl status ssh --no-pager
  append_report_block "ssh ports" ss -tulpn
  append_report_block "ip addresses" ip -br addr
  ok "SSH настроен. Проверка: systemctl status ssh; ss -tulpn | grep :22"
  pause
}

setup_remote_active_session() {
  header "3. Удалённый доступ к активной сессии через x11vnc"
  apt_install x11vnc net-tools ufw

  if [ -f /etc/gdm3/custom.conf ]; then
    safe_backup_file /etc/gdm3/custom.conf
    if grep -q '^#WaylandEnable=false' /etc/gdm3/custom.conf; then
      sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
    elif ! grep -q '^WaylandEnable=false' /etc/gdm3/custom.conf; then
      echo 'WaylandEnable=false' >> /etc/gdm3/custom.conf
    fi
    warn "Для x11vnc активной сессии лучше Xorg. Если не подключается — выйди из системы/перезагрузи Ubuntu."
  fi

  echo "Придумай пароль VNC. На экзамене можно простой, но не пустой."
  read -rsp "VNC password: " vncpass
  echo
  if [ -z "$vncpass" ]; then
    vncpass="QualExam123"
    warn "Пароль пустой, временно установлен: QualExam123"
  fi
  run "x11vnc -storepasswd '$vncpass' /etc/x11vnc.pass"
  chmod 600 /etc/x11vnc.pass

  cat >/etc/systemd/system/x11vnc.service <<'SERVICE'
[Unit]
Description=x11vnc remote access to active desktop session
After=display-manager.service network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/x11vnc -display :0 -auth guess -forever -loop -noxdamage -repeat -rfbauth /etc/x11vnc.pass -rfbport 5900 -shared
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

  run "systemctl daemon-reload"
  run "systemctl enable --now x11vnc"
  run "ufw allow 5900/tcp"

  append_report_block "x11vnc status" systemctl status x11vnc --no-pager
  append_report_block "vnc port" ss -tulpn
  ok "Удалённый доступ к активной сессии настроен. Подключение: VNC-клиент -> IP_UBUNTU:5900"
  pause
}

setup_network_check() {
  header "4. Интернет-соединение: выбор интерфейса и проверка"
  apt_install network-manager iproute2 iputils-ping dnsutils curl

  echo "Доступные сетевые интерфейсы:"
  ip -br link | tee -a "$LOG_FILE"
  echo
  nmcli device status 2>/dev/null | tee -a "$LOG_FILE" || true
  echo
  read -rp "Введи правильный интерфейс для демонстрации, например enp0s3 или eth0: " iface
  if [ -n "$iface" ]; then
    log "Выбран сетевой интерфейс: $iface"
    run "ip addr show '$iface'"
    if need_cmd nmcli; then
      run "nmcli device connect '$iface'"
    fi
  fi

  run "ip route"
  run "ping -c 4 8.8.8.8"
  run "ping -c 4 google.com"
  run "curl -I --max-time 10 https://ubuntu.com"
  ok "Критерий: выбран интерфейс и продемонстрирована проверка сети."
  pause
}

install_base_software() {
  header "5. Базовое программное обеспечение"
  apt_install curl wget git vim nano htop mc tree unzip zip p7zip-full software-properties-common ca-certificates gnupg lsb-release gdebi synaptic flatpak gnome-software-plugin-flatpak build-essential gnome-tweaks hardinfo neofetch || true
  create_desktop_shortcuts
  append_report_block "base versions" bash -lc 'git --version; gcc --version | head -1; htop --version | head -1; 7z | head -2; neofetch --stdout | head -20'
  ok "Базовое ПО установлено."
  pause
}

install_virtual_printer() {
  header "6. Виртуальный принтер PDF"
  apt_install cups cups-pdf system-config-printer printer-driver-cups-pdf || apt_install cups cups-pdf system-config-printer
  run "systemctl enable --now cups"
  usermod -aG lpadmin "$REAL_USER" 2>/dev/null || true
  run "lpstat -p -d"
  ok "Виртуальный PDF-принтер установлен. Обычно он называется PDF или CUPS-PDF."
  pause
}

make_backup_image_restore() {
  header "7. Резервное копирование, ISO-образ и точка восстановления"
  apt_install rsync tar gzip genisoimage timeshift || true

  local stamp backup_tar iso_stage iso_file
  stamp="$(date '+%Y%m%d_%H%M%S')"
  backup_tar="$BACKUP_DIR/os_config_backup_$stamp.tar.gz"
  iso_stage="$BACKUP_DIR/iso_stage_$stamp"
  iso_file="$LOG_DIR/qual_exam_install_image_$stamp.iso"

  mkdir -p "$iso_stage"

  warn "Создаю быстрый бэкап конфигурации ОС: /etc, /usr/local, часть домашней .config."
  run "tar --exclude='$REAL_HOME/.cache' --exclude='$REAL_HOME/Downloads' --exclude='$REAL_HOME/.local/share/Trash' -czf '$backup_tar' /etc /usr/local '$REAL_HOME/.config' '$LOG_DIR'"

  cp -a "$backup_tar" "$iso_stage/" 2>/dev/null || true
  cp -a "$LOG_FILE" "$iso_stage/report.txt" 2>/dev/null || true
  cat >"$iso_stage/README_restore.txt" <<RESTORE
Экзаменационный установочный/резервный образ.
Дата: $(date)
Пользователь: $REAL_USER
Состав: архив конфигурации ОС, отчёт выполненных действий.
Восстановление примера:
  sudo tar -xzf os_config_backup_*.tar.gz -C /
RESTORE
  run "genisoimage -quiet -J -R -V QUAL_EXAM_OS -o '$iso_file' '$iso_stage'"

  warn "Пробую создать точку восстановления Timeshift. Если не получится, открой: sudo timeshift-gtk"
  run "timeshift --create --comments 'qual_exam_restore_point_$stamp' --tags D"

  run "ls -lh '$BACKUP_DIR' '$LOG_DIR' | sed -n '1,120p'"
  ok "Бэкап и ISO созданы. ISO: $iso_file"
  pause
}

setup_users_auth_logs() {
  header "8. Группы, права, аутентификация, авторизация, журналы"
  apt_install acl sudo libpam-pwquality auditd audispd-plugins rsyslog logrotate samba || true

  # Группы по ролям.
  groupadd -f developers
  groupadd -f testers
  groupadd -f support
  usermod -aG developers,testers,support "$REAL_USER" || true

  mkdir -p /srv/company/{projects,testing,shared,backup}
  chgrp developers /srv/company/projects
  chgrp testers /srv/company/testing
  chgrp support /srv/company/shared /srv/company/backup
  chmod 2770 /srv/company/projects /srv/company/testing /srv/company/backup
  chmod 2775 /srv/company/shared
  setfacl -m g:developers:rwx /srv/company/projects
  setfacl -m g:testers:rwx /srv/company/testing
  setfacl -m g:support:rwx /srv/company/shared /srv/company/backup

  safe_backup_file /etc/security/pwquality.conf
  cat >/etc/security/pwquality.conf <<'PWQ'
# Экзаменационная политика сложности пароля
minlen = 8
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
retry = 3
PWQ

  safe_backup_file /etc/login.defs
  sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
  sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' /etc/login.defs
  sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   7/' /etc/login.defs

  cat >/etc/sudoers.d/qual_exam_support <<'SUDOERS'
# Группа support может смотреть состояние служб и журналы без полного sudo.
Cmnd_Alias SUPPORT_VIEW = /bin/systemctl status *, /usr/bin/systemctl status *, /bin/journalctl *, /usr/bin/journalctl *
%support ALL=(root) NOPASSWD: SUPPORT_VIEW
SUDOERS
  chmod 440 /etc/sudoers.d/qual_exam_support
  run "visudo -cf /etc/sudoers.d/qual_exam_support"

  # Samba как демонстрация обмена данными с другими системами.
  safe_backup_file /etc/samba/smb.conf
  if ! grep -q '^\[qual_shared\]' /etc/samba/smb.conf 2>/dev/null; then
    cat >>/etc/samba/smb.conf <<'SMB'

[qual_shared]
   path = /srv/company/shared
   browseable = yes
   read only = no
   guest ok = yes
   force group = support
   create mask = 0664
   directory mask = 2775
SMB
  fi
  run "systemctl enable --now smbd nmbd || systemctl enable --now smbd"
  run "systemctl restart smbd || true"
  run "ufw allow Samba || true"

  # Журнал мониторинга.
  cat >/etc/audit/rules.d/qual_exam.rules <<'AUDIT'
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers
-w /srv/company/ -p rwxa -k company_access
AUDIT
  run "systemctl enable --now auditd"
  run "augenrules --load || auditctl -R /etc/audit/rules.d/qual_exam.rules"
  run "systemctl enable --now rsyslog"
  run "systemctl restart rsyslog"

  append_report_block "groups" bash -lc "getent group developers testers support; id '$REAL_USER'; ls -ld /srv/company/*; getfacl /srv/company/projects"
  append_report_block "auth policy" bash -lc "cat /etc/security/pwquality.conf; grep '^PASS_' /etc/login.defs"
  append_report_block "audit rules" auditctl -l
  append_report_block "samba share" testparm -s
  ok "Группы, права, авторизация, аутентификация и журналы настроены."
  warn "Чтобы новые группы применились к текущему пользователю, выйди из сессии и зайди заново."
  pause
}

install_android_studio() {
  header "ПО: Android Studio + Java + ADB"
  apt_install openjdk-17-jdk git curl unzip zip adb fastboot qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils cpu-checker || true
  usermod -aG kvm,libvirt "$REAL_USER" 2>/dev/null || true
  if ! need_cmd snap; then
    apt_install snapd
    run "systemctl enable --now snapd"
  fi
  run "snap install android-studio --classic"
  append_report_block "android tools" bash -lc 'java -version; adb version; fastboot --version || true; snap list android-studio || true; kvm-ok || true'
  create_desktop_shortcuts
  ok "Android Studio выбран для разработки Android-приложений."
  pause
}

install_codeblocks_gcc() {
  header "ПО: Code::Blocks + GCC/G++/GFortran"
  apt_install build-essential gcc g++ gfortran gdb cmake make codeblocks codeblocks-contrib valgrind || true
  append_report_block "gcc codeblocks" bash -lc 'gcc --version | head -1; g++ --version | head -1; gfortran --version | head -1; codeblocks --version || true'
  create_desktop_shortcuts
  ok "Code::Blocks и набор компиляторов GCC установлены."
  pause
}

install_eclipse() {
  header "ПО: Eclipse IDE"
  apt_install openjdk-17-jdk snapd || true
  run "systemctl enable --now snapd"
  run "snap install eclipse --classic"
  append_report_block "eclipse" bash -lc 'snap list eclipse || true; java -version'
  create_desktop_shortcuts
  ok "Eclipse IDE установлена."
  pause
}

install_blender() {
  header "ПО: Blender / 3D-графика"
  apt_install blender mesa-utils || true
  append_report_block "blender" bash -lc 'blender --version | head -5 || true; glxinfo -B || true'
  create_desktop_shortcuts
  ok "Blender установлен как ПО для 3D-графики/моделирования."
  pause
}

install_virtualbox() {
  header "ПО: VirtualBox"
  apt_install virtualbox virtualbox-dkms virtualbox-qt dkms linux-headers-generic || true
  usermod -aG vboxusers "$REAL_USER" 2>/dev/null || true
  append_report_block "virtualbox" bash -lc 'vboxmanage --version || virtualbox --help | head -5 || true; getent group vboxusers'
  create_desktop_shortcuts
  ok "VirtualBox установлен как программа-эмулятор/виртуализация ОС на ПК."
  warn "Если Ubuntu сама запущена внутри VirtualBox, вложенная виртуализация может быть недоступна — для критерия достаточно установки и запуска."
  pause
}

install_security_tools() {
  header "ПО: Безопасность"
  apt_install ufw gufw clamav clamav-daemon fail2ban chkrootkit rkhunter lynis || true
  run "systemctl enable --now clamav-freshclam || true"
  run "systemctl enable --now clamav-daemon || true"
  run "systemctl enable --now fail2ban || true"
  run "ufw allow OpenSSH || true"
  run "ufw --force enable || true"
  append_report_block "security versions" bash -lc 'clamscan --version || true; fail2ban-client --version || true; ufw status verbose || true; chkrootkit -V || true; rkhunter --versioncheck || true'
  create_desktop_shortcuts
  ok "Средства защиты установлены: UFW/GUFW, ClamAV, Fail2ban, chkrootkit/rkhunter/lynis."
  pause
}

install_office_graphics_archive() {
  header "ПО: офис, графика, архиватор"
  apt_install libreoffice libreoffice-l10n-ru libreoffice-help-ru gimp inkscape p7zip-full zip unzip || true
  append_report_block "office graphics archive" bash -lc 'libreoffice --version || true; gimp --version || true; inkscape --version || true; 7z | head -2 || true'
  create_desktop_shortcuts
  ok "Офисный пакет, графические редакторы и архиватор установлены."
  pause
}

install_databases() {
  header "ПО: СУБД"
  echo "1) SQLite + DB Browser"
  echo "2) PostgreSQL"
  echo "3) MySQL Server"
  echo "4) Всё"
  read -rp "Выбор: " db
  case "$db" in
    1) apt_install sqlite3 sqlitebrowser ;;
    2) apt_install postgresql postgresql-contrib pgadmin4 || apt_install postgresql postgresql-contrib ; run "systemctl enable --now postgresql" ;;
    3) apt_install mysql-server ; run "systemctl enable --now mysql" ;;
    4) apt_install sqlite3 sqlitebrowser postgresql postgresql-contrib mysql-server ; run "systemctl enable --now postgresql mysql" ;;
    *) warn "Ничего не выбрано" ;;
  esac
  append_report_block "db status" bash -lc 'sqlite3 --version || true; systemctl status postgresql --no-pager || true; systemctl status mysql --no-pager || true'
  create_desktop_shortcuts
  ok "СУБД установлены/проверены."
  pause
}

setup_compatibility() {
  header "10. Совместимость приложений с Ubuntu"
  apt_install x11-utils wmctrl mesa-utils libgl1-mesa-dri || true

  cat >/usr/local/bin/compat-run <<'COMPAT'
#!/usr/bin/env bash
# Запуск старых/проблемных GUI-приложений с отключением масштабирования и принудительным X11.
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb
export GDK_SCALE=1
export GDK_DPI_SCALE=1
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_SCALE_FACTOR=1
export QT_ENABLE_HIGHDPI_SCALING=0
export SDL_VIDEODRIVER=x11
export LIBGL_ALWAYS_SOFTWARE=1
exec "$@"
COMPAT
  chmod +x /usr/local/bin/compat-run

  cat >/usr/local/bin/qual-screen-1024x768-note.sh <<'LOWRES'
#!/usr/bin/env bash
# Пример для демонстрации низкого разрешения.
# Посмотреть мониторы: xrandr
# Установить вручную: xrandr --output ИМЯ_МОНИТОРА --mode 1024x768
xrandr
LOWRES
  chmod +x /usr/local/bin/qual-screen-1024x768-note.sh

  run_gsettings "gsettings set org.gnome.desktop.interface enable-animations false" || true
  run_gsettings "gsettings set org.gnome.mutter check-alive-timeout 60000" || true

  cat >>"$LOG_FILE" <<COMPATREPORT

===== compatibility settings =====
Создан /usr/local/bin/compat-run
Пример запуска:
  compat-run codeblocks
  compat-run blender
Что закрывает:
- ограниченная цветовая палитра/проблемы OpenGL: LIBGL_ALWAYS_SOFTWARE=1;
- низкое разрешение: подготовлен qual-screen-1024x768-note.sh + xrandr;
- проблемы меню и кнопок: принудительный X11 через GDK_BACKEND/QT_QPA_PLATFORM;
- композиция рабочего стола: отключены анимации GNOME, для полной проверки используется Xorg;
- высокое DPI: отключено авто-масштабирование QT/GDK.
COMPATREPORT

  ok "Создан compat-run и применены безопасные настройки совместимости."
  pause
}

make_documentation() {
  header "11. Документация пользователя и обоснование выбора ПО"
  local doc="$LOG_DIR/USER_GUIDE.md"
  cat >"$doc" <<'DOC'
# Руководство пользователя

## 1. Общие сведения
Наименование программного обеспечения: Android Studio / Code::Blocks / Blender / VirtualBox / ClamAV / LibreOffice.
Назначение: установка и первичная настройка рабочего места для разработки мобильных приложений, компиляции программ, работы с 3D-графикой, виртуализации, защиты системы и подготовки документов.

## 2. Обоснование выбора программных ресурсов
Android Studio выбрана как специализированная IDE для разработки приложений Android.
OpenJDK, ADB и Fastboot нужны для сборки, запуска и отладки Android-приложений.
Code::Blocks и GCC выбраны как свободная среда разработки и набор компиляторов для C/C++/Fortran и других задач программирования.
Blender выбран для работы с 3D-графикой и проверки графической подсистемы.
VirtualBox выбран для создания и запуска виртуальных машин с различными операционными системами.
ClamAV, UFW/GUFW, Fail2ban, rkhunter/chkrootkit выбраны для базовой защиты, фильтрации сетевого доступа и проверки системы.
LibreOffice, GIMP/Inkscape и 7-Zip выбраны как базовое офисное, графическое и архивное ПО.

## 3. Запуск программ
Android Studio: меню приложений → Android Studio или команда `android-studio`.
Code::Blocks: меню приложений → Code::Blocks или команда `codeblocks`.
Blender: меню приложений → Blender или команда `blender`.
VirtualBox: меню приложений → Oracle VM VirtualBox или команда `virtualbox`.
ClamAV: проверка папки командой `clamscan -r /home/$USER`.
LibreOffice: меню приложений → LibreOffice или команда `libreoffice`.

## 4. Основные приёмы работы
Android Studio: создать проект → выбрать шаблон → настроить SDK → запустить сборку → проверить приложение через ADB/эмулятор.
Code::Blocks: File → New Project → Console Application → Build and Run.
Blender: создать сцену → добавить объект → настроить материал/камеру → выполнить рендер.
VirtualBox: New → выбрать тип ОС → выделить RAM/диск → подключить ISO → Start.
ClamAV: обновить базы `sudo systemctl restart clamav-freshclam`, проверить `clamscan -r <папка>`.

## 5. Настройка обмена данными
SSH: удалённое подключение к ПК по порту 22.
Samba: общая папка `/srv/company/shared`, сетевой ресурс `[qual_shared]`.
ADB: обмен данными и отладка Android-устройств.
Git: обмен исходным кодом через удалённые репозитории.

## 6. Ожидаемый результат
Пользователь может разрабатывать Android-приложения, компилировать программы, работать с 3D-графикой, запускать виртуальные машины, печатать в PDF, подключаться удалённо, выполнять резервное копирование и использовать средства защиты.

## 7. Проверочные команды
`systemctl status ssh`
`systemctl status x11vnc`
`lpstat -p -d`
`ufw status verbose`
`auditctl -l`
`groups $USER`
`ls -l /opt/qual_exam`
DOC
  chown "$REAL_USER:$REAL_USER" "$doc" 2>/dev/null || true
  ok "Документация создана: $doc"
  echo "Открой/распечатай: $doc"
  pause
}

install_ticket_mobile_dev_all() {
  header "9A. Установка ПО под билет мобильной разработки"
  warn "Это тяжёлый вариант: Android Studio, компиляторы, Blender, VirtualBox, безопасность, базовое ПО."
  read -rp "Продолжить? [y/N]: " ans
  [[ "$ans" =~ ^[YyДд]$ ]] || return
  install_base_software
  install_android_studio
  install_codeblocks_gcc
  install_blender
  install_virtualbox
  install_security_tools
  make_documentation
}

software_menu() {
  while true; do
    header "9. Установка требуемого ПО по билету"
    echo "1) Android Studio + Java + ADB"
    echo "2) Code::Blocks + GCC/G++/GFortran"
    echo "3) Eclipse IDE"
    echo "4) Blender / 3D-графика"
    echo "5) VirtualBox"
    echo "6) Защита: ClamAV + UFW/GUFW + Fail2ban + rkhunter"
    echo "7) LibreOffice + GIMP/Inkscape + 7-Zip"
    echo "8) СУБД: SQLite/PostgreSQL/MySQL"
    echo "9) Всё под примерный билет мобильной разработки"
    echo "0) Назад"
    read -rp "Выбор: " s
    case "$s" in
      1) install_android_studio ;;
      2) install_codeblocks_gcc ;;
      3) install_eclipse ;;
      4) install_blender ;;
      5) install_virtualbox ;;
      6) install_security_tools ;;
      7) install_office_graphics_archive ;;
      8) install_databases ;;
      9) install_ticket_mobile_dev_all ;;
      0) break ;;
      *) warn "Нет такого пункта"; pause ;;
    esac
  done
}

os_required_minimum() {
  header "Обязательная настройка ОС по критериям"
  install_kernel_utils
  setup_ssh
  setup_remote_active_session
  setup_network_check
  install_base_software
  install_virtual_printer
  setup_users_auth_logs
  setup_compatibility
  make_documentation
  ok "Базовые критерии ОС закрыты."
  pause
}

all_safe_without_heavy_apps() {
  header "Выполнить всё безопасное без тяжёлых IDE"
  install_kernel_utils
  setup_ssh
  setup_remote_active_session
  setup_network_check
  install_base_software
  install_virtual_printer
  make_backup_image_restore
  setup_users_auth_logs
  install_security_tools
  install_office_graphics_archive
  setup_compatibility
  make_documentation
  ok "Безопасный полный проход завершён. Тяжёлые приложения ставь отдельно из меню 9."
  pause
}

show_report() {
  header "Отчёт и команды для демонстрации"
  echo "Файл отчёта: $LOG_FILE"
  echo "Документация: $LOG_DIR/USER_GUIDE.md"
  echo
  echo "Быстрые команды для показа преподавателю:"
  cat <<'CMDS'
uname -a
cat /etc/sysctl.d/99-qual-exam.conf
systemctl status ssh --no-pager
systemctl status x11vnc --no-pager
ip -br addr
ping -c 4 8.8.8.8
lpstat -p -d
ls -lh /opt/qual_exam /opt/qual_exam/backups
getent group developers testers support
ls -ld /srv/company/*
getfacl /srv/company/projects
auditctl -l
ufw status verbose
snap list
apt list --installed | grep -E 'codeblocks|blender|virtualbox|clamav|libreoffice|postgresql|mysql|sqlite'
CMDS
  echo
  tail -n 120 "$LOG_FILE"
  pause
}

main_menu() {
  while true; do
    header "QUAL EXAM MENU — Ubuntu"
    echo "1) ОБЯЗАТЕЛЬНАЯ настройка ОС по критериям"
    echo "2) Утилиты ядра/драйверы"
    echo "3) SSH"
    echo "4) Удалённый доступ к активной сессии"
    echo "5) Интернет: интерфейс + проверка"
    echo "6) Базовое ПО"
    echo "7) Виртуальный принтер PDF"
    echo "8) Бэкап ОС + ISO + точка восстановления"
    echo "9) Группы + права + auth + журналы + Samba"
    echo "10) Установка программ по билету"
    echo "11) Совместимость программ"
    echo "12) Документация/обоснование выбора ПО"
    echo "13) ВСЁ безопасное без тяжёлых IDE"
    echo "14) Показать отчёт и команды проверки"
    echo "0) Выход"
    echo
    read -rp "Выбери пункт: " choice
    case "$choice" in
      1) os_required_minimum ;;
      2) install_kernel_utils ;;
      3) setup_ssh ;;
      4) setup_remote_active_session ;;
      5) setup_network_check ;;
      6) install_base_software ;;
      7) install_virtual_printer ;;
      8) make_backup_image_restore ;;
      9) setup_users_auth_logs ;;
      10) software_menu ;;
      11) setup_compatibility ;;
      12) make_documentation ;;
      13) all_safe_without_heavy_apps ;;
      14) show_report ;;
      0|q|Q) ok "Выход. Отчёт: $LOG_FILE"; exit 0 ;;
      *) warn "Нет такого пункта"; pause ;;
    esac
  done
}

log "===== START qual_exam_menu.sh as root, real user: $REAL_USER ====="
main_menu
