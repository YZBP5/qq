#!/usr/bin/env bash
set -euo pipefail

echo "=== 01: Настройка ядра Ubuntu через специальные утилиты ==="

if ! command -v apt >/dev/null 2>&1; then
    echo "Ошибка: этот скрипт рассчитан на Ubuntu/Debian-системы."
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

echo "[1/5] Обновление списка пакетов..."
$SUDO apt update

echo "[2/5] Установка утилит для работы с параметрами ядра..."
PACKAGES=(
    procps
    sysstat
    linux-tools-common
    linux-tools-generic
)

for pkg in "${PACKAGES[@]}"; do
    if apt-cache show "$pkg" >/dev/null 2>&1; then
        echo "Устанавливаю пакет: $pkg"
        $SUDO apt install -y "$pkg"
    else
        echo "Пакет $pkg не найден в репозиториях, пропускаю."
    fi
done

echo "[3/5] Создание безопасного файла параметров ядра..."

SYSCTL_FILE="/etc/sysctl.d/99-exam-kernel-tuning.conf"

if [ -f "$SYSCTL_FILE" ]; then
    echo "Найден старый файл настроек, создаю резервную копию..."
    $SUDO cp "$SYSCTL_FILE" "${SYSCTL_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
fi

$SUDO tee "$SYSCTL_FILE" >/dev/null <<'EOF'
# Настройки ядра для квалификационного экзамена
# Файл создан скриптом 01_kernel_utils.sh

# Меньше использовать swap, если хватает оперативной памяти
vm.swappiness = 10

# Увеличение лимита наблюдения за файлами
# Полезно для IDE, редакторов кода и разработки
fs.inotify.max_user_watches = 524288

# Защита от SYN-flood атак
net.ipv4.tcp_syncookies = 1

# Ограничение просмотра системных сообщений ядра обычными пользователями
kernel.dmesg_restrict = 1

# Ограничение раскрытия адресов ядра
kernel.kptr_restrict = 1
EOF

echo "[4/5] Применение параметров ядра..."
$SUDO sysctl --system

echo "[5/5] Включение системного мониторинга sysstat..."

if [ -f /etc/default/sysstat ]; then
    $SUDO sed -i 's/^ENABLED=.*/ENABLED="true"/' /etc/default/sysstat
fi

$SUDO systemctl enable --now sysstat 2>/dev/null || true
$SUDO systemctl enable --now sysstat-collect.timer 2>/dev/null || true
$SUDO systemctl enable --now sysstat-summary.timer 2>/dev/null || true

echo
echo "=== Проверка установленных утилит ==="

echo "sysctl:"
command -v sysctl || true

echo
echo "mpstat:"
command -v mpstat || true

echo
echo "uname:"
uname -a

echo
echo "Проверка активных параметров ядра:"
sysctl vm.swappiness
sysctl fs.inotify.max_user_watches
sysctl net.ipv4.tcp_syncookies
sysctl kernel.dmesg_restrict
sysctl kernel.kptr_restrict

echo
echo "=== Готово ==="
echo "Настройки ядра применены безопасно."
echo "Для полной проверки после перезапуска можно выполнить:"
echo "sudo reboot"
