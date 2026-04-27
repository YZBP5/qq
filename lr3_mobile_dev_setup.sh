#!/usr/bin/env bash

set -e

# ==========================================================
# ЛР №3 — установка ПО для мобильной разработки
# Ubuntu / Linux Mint
#
# Что делает:
# 1. Обновляет систему
# 2. Ставит базовое ПО
# 3. Ставит Android Studio
# 4. Ставит JDK, GCC, G++, Clang, CMake
# 5. Ставит ADB / Fastboot
# 6. Ставит Mesa 3D / OpenGL utilities
# 7. Ставит QEMU/KVM + Virt-Manager
# 8. Ставит LibreOffice, GIMP, Inkscape, 7-Zip
# 9. Ставит PostgreSQL и SQLite Browser
# 10. Ставит UFW, ClamAV, Fail2Ban, Auditd
# 11. Ставит Timeshift
# 12. Ставит виртуальный PDF-принтер CUPS-PDF
# 13. Создает группу developers и пользователя devuser
# 14. Создает папку /opt/mobile_projects и права доступа
# 15. Настраивает аудит доступа к папке проекта
# 16. Создает файл проверки ~/lr3_check.txt
# 17. Создает заготовку отчета ~/LR3_REPORT.md
# ==========================================================

echo "=========================================================="
echo " ЛР №3 — автоматическая установка ПО для мобильной разработки"
echo "=========================================================="

if [ "$EUID" -ne 0 ]; then
    echo "[INFO] Скрипт запущен не от root. Перезапускаю через sudo..."
    exec sudo bash "$0" "$@"
fi

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
REAL_HOME="$(eval echo ~"$REAL_USER")"

echo "[INFO] Основной пользователь: $REAL_USER"
echo "[INFO] Домашняя папка: $REAL_HOME"

LOG_FILE="$REAL_HOME/lr3_install.log"
CHECK_FILE="$REAL_HOME/lr3_check.txt"
REPORT_FILE="$REAL_HOME/LR3_REPORT.md"

touch "$LOG_FILE"
chown "$REAL_USER:$REAL_USER" "$LOG_FILE"

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log ""
log "========== ЭТАП 1. Обновление системы =========="

apt update
apt -y upgrade

log ""
log "========== ЭТАП 2. Подготовка Snap для Android Studio =========="

# В Linux Mint Snap может быть заблокирован файлом nosnap.pref
if [ -f /etc/apt/preferences.d/nosnap.pref ]; then
    log "[INFO] Найден запрет Snap в Linux Mint. Удаляю /etc/apt/preferences.d/nosnap.pref"
    rm -f /etc/apt/preferences.d/nosnap.pref
    apt update
fi

apt install -y snapd

systemctl enable --now snapd || true
systemctl enable --now snapd.socket || true

log ""
log "========== ЭТАП 3. Установка базового ПО =========="

apt install -y \
    curl \
    wget \
    git \
    unzip \
    zip \
    p7zip-full \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    nano \
    vim \
    htop \
    tree \
    net-tools \
    dnsutils \
    iputils-ping

log ""
log "========== ЭТАП 4. Установка средств разработки =========="

apt install -y \
    build-essential \
    gcc \
    g++ \
    clang \
    gdb \
    cmake \
    make \
    ninja-build \
    pkg-config \
    openjdk-17-jdk

log ""
log "========== ЭТАП 5. Установка Android tools =========="

apt install -y \
    adb \
    fastboot

log ""
log "========== ЭТАП 6. Установка Mesa 3D / OpenGL =========="

apt install -y \
    mesa-utils \
    libglu1-mesa-dev \
    libgl1-mesa-dri \
    libglx-mesa0

log ""
log "========== ЭТАП 7. Установка виртуализации QEMU/KVM =========="

apt install -y \
    qemu-kvm \
    qemu-system-x86 \
    virt-manager \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils

systemctl enable --now libvirtd || true
systemctl enable --now virtlogd || true

log ""
log "========== ЭТАП 8. Установка офисного пакета, графики, архиватора =========="

apt install -y \
    libreoffice \
    gimp \
    inkscape \
    file-roller

log ""
log "========== ЭТАП 9. Установка СУБД =========="

apt install -y \
    sqlitebrowser \
    postgresql \
    postgresql-contrib

systemctl enable --now postgresql || true

log ""
log "========== ЭТАП 10. Установка диагностических утилит =========="

apt install -y \
    inxi \
    lshw \
    neofetch \
    hardinfo \
    lm-sensors

log ""
log "========== ЭТАП 11. Установка средств защиты =========="

apt install -y \
    ufw \
    gufw \
    clamav \
    clamav-daemon \
    fail2ban \
    auditd \
    audispd-plugins

systemctl enable --now auditd || true
systemctl enable --now fail2ban || true
systemctl enable --now clamav-daemon || true

log ""
log "========== ЭТАП 12. Настройка Firewall UFW =========="

ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# SSH оставляем открытым, чтобы не отрезать доступ в виртуалке/сервере
ufw allow 22/tcp

ufw --force enable

log ""
log "========== ЭТАП 13. Установка Timeshift =========="

apt install -y timeshift || log "[WARN] Timeshift не удалось установить через apt. Можно поставить вручную позже."

log ""
log "========== ЭТАП 14. Установка виртуального PDF-принтера =========="

apt install -y cups printer-driver-cups-pdf

systemctl enable --now cups || true

# Добавляем пользователя в группу администрирования принтеров
usermod -aG lpadmin "$REAL_USER" || true

log ""
log "========== ЭТАП 15. Установка Android Studio =========="

if snap list android-studio >/dev/null 2>&1; then
    log "[INFO] Android Studio уже установлен."
else
    snap install android-studio --classic
fi

log ""
log "========== ЭТАП 16. Настройка групп и прав доступа =========="

groupadd -f developers

# Создаем учебного пользователя, если его еще нет
if id "devuser" >/dev/null 2>&1; then
    log "[INFO] Пользователь devuser уже существует."
else
    useradd -m -s /bin/bash devuser
    echo "devuser:12345" | chpasswd
    log "[INFO] Создан пользователь devuser с паролем 12345"
fi

usermod -aG developers devuser
usermod -aG developers "$REAL_USER"

# Добавляем основного пользователя в группы виртуализации
usermod -aG libvirt,kvm "$REAL_USER" || true

mkdir -p /opt/mobile_projects
chown -R root:developers /opt/mobile_projects
chmod -R 2770 /opt/mobile_projects

log ""
log "========== ЭТАП 17. Настройка аудита папки проекта =========="

cat > /etc/audit/rules.d/mobile_projects.rules <<EOF
-w /opt/mobile_projects -p rwxa -k mobile_projects_access
EOF

augenrules --load || true
auditctl -w /opt/mobile_projects -p rwxa -k mobile_projects_access || true

log ""
log "========== ЭТАП 18. Создание точки восстановления Timeshift =========="

if command -v timeshift >/dev/null 2>&1; then
    timeshift --create --comments "LR3 initial setup" --tags D || log "[WARN] Timeshift не смог создать снимок. Возможно, нужна ручная настройка GUI."
else
    log "[WARN] Timeshift не найден, снимок не создан."
fi

log ""
log "========== ЭТАП 19. Создание файла проверки =========="

{
    echo "=========================================================="
    echo " ЛР №3 — результат установки"
    echo " Дата: $(date)"
    echo " Пользователь: $REAL_USER"
    echo "=========================================================="
    echo ""

    echo "=== ОС ==="
    lsb_release -a 2>/dev/null || cat /etc/os-release
    echo ""

    echo "=== Java ==="
    java -version 2>&1
    javac -version 2>&1
    echo ""

    echo "=== Компиляторы ==="
    gcc --version | head -n 1
    g++ --version | head -n 1
    clang --version | head -n 1
    cmake --version | head -n 1
    echo ""

    echo "=== Android tools ==="
    adb version 2>&1 || true
    fastboot --version 2>&1 || true
    echo ""

    echo "=== Android Studio ==="
    snap list android-studio 2>/dev/null || echo "Android Studio не найден в snap list"
    echo ""

    echo "=== Mesa / OpenGL ==="
    glxinfo -B 2>/dev/null | grep -E "OpenGL vendor|OpenGL renderer|OpenGL version" || echo "glxinfo доступен, но OpenGL не проверен в headless-среде"
    echo ""

    echo "=== Виртуализация ==="
    qemu-system-x86_64 --version 2>&1 | head -n 1
    virsh --version 2>&1
    echo ""

    echo "=== СУБД ==="
    psql --version 2>&1
    sqlitebrowser --version 2>&1 || true
    echo ""

    echo "=== Защита ==="
    ufw status verbose 2>&1
    systemctl is-active clamav-daemon 2>&1 || true
    systemctl is-active fail2ban 2>&1 || true
    systemctl is-active auditd 2>&1 || true
    echo ""

    echo "=== Пользователи и группы ==="
    id "$REAL_USER" 2>&1
    id devuser 2>&1
    ls -ld /opt/mobile_projects
    echo ""

    echo "=== Принтеры ==="
    lpstat -p 2>&1 || true
    echo ""

    echo "=== Timeshift ==="
    timeshift --list 2>&1 || true
    echo ""

    echo "=== Аудит ==="
    auditctl -l 2>&1 || true
    echo ""

} > "$CHECK_FILE"

chown "$REAL_USER:$REAL_USER" "$CHECK_FILE"

log ""
log "========== ЭТАП 20. Создание заготовки отчета =========="

cat > "$REPORT_FILE" <<'EOF'
# Лабораторная работа №3  
## Анализ рисков

## Тема
Установка и настройка программного обеспечения для отдела разработки мобильных приложений.

## Цель работы
Получить навыки управления внедрением программного продукта, выполнить установку и базовую настройку программного обеспечения, необходимого для разработки мобильных приложений.

## Выбранное программное обеспечение

| Назначение | Программное обеспечение |
|---|---|
| Операционная система | Ubuntu / Linux Mint |
| Среда разработки Android | Android Studio |
| Комплект разработки Java | OpenJDK 17 |
| Компиляторы | GCC, G++, Clang |
| Инструменты сборки | CMake, Make, Ninja |
| Android-инструменты | ADB, Fastboot |
| Эмулятор 3D-графики | Mesa 3D / mesa-utils |
| Эмулятор операционных систем | QEMU/KVM, Virt-Manager |
| Графический редактор | GIMP, Inkscape |
| Офисный пакет | LibreOffice |
| Архиватор | 7-Zip / p7zip |
| Утилиты диагностики | inxi, lshw, neofetch, hardinfo |
| СУБД | PostgreSQL, SQLite Browser |
| Средства защиты | UFW, ClamAV, Fail2Ban, Auditd |
| Резервное копирование | Timeshift |
| Виртуальный принтер | CUPS-PDF |

## Обоснование выбора

Android Studio выбрана как основная интегрированная среда разработки для создания приложений под Android.  
OpenJDK необходим для запуска и сборки Java/Kotlin-проектов.  
GCC, G++, Clang, CMake и Ninja используются для компиляции программных компонентов и работы с нативными библиотеками.  
ADB и Fastboot применяются для взаимодействия с Android-устройствами и эмуляторами.  
Mesa 3D используется для проверки работы 3D-графики.  
QEMU/KVM и Virt-Manager позволяют создавать и запускать виртуальные машины.  
UFW, ClamAV, Fail2Ban и Auditd обеспечивают базовую защиту системы, контроль доступа и журналирование событий.  
Timeshift используется для создания точки восстановления системы.  
CUPS-PDF используется как виртуальный принтер для сохранения документов в PDF.

## Выполненные действия

1. Выполнено обновление операционной системы.
2. Установлено базовое программное обеспечение.
3. Установлена Android Studio.
4. Установлены средства разработки и компиляторы.
5. Установлены средства Android SDK: ADB и Fastboot.
6. Установлены средства проверки 3D-графики.
7. Установлены QEMU/KVM и Virt-Manager.
8. Установлены LibreOffice, GIMP, Inkscape и 7-Zip.
9. Установлены PostgreSQL и SQLite Browser.
10. Установлены и настроены средства защиты.
11. Настроен firewall UFW.
12. Создана группа developers и пользователь devuser.
13. Создана рабочая папка /opt/mobile_projects.
14. Настроены права доступа к рабочей папке.
15. Настроен аудит доступа к рабочей папке.
16. Установлен виртуальный PDF-принтер CUPS-PDF.
17. Создана точка восстановления системы Timeshift.

## Руководство пользователя: Android Studio

### Назначение программы
Android Studio предназначена для разработки, сборки, тестирования и отладки мобильных приложений под Android.

### Запуск программы
Для запуска Android Studio необходимо открыть меню приложений и выбрать Android Studio.  
Также программу можно запустить через терминал командой:

```bash
android-studio
