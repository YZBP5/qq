# Шпора для квалификационного экзамена по Ubuntu

Этот файл нужен как шпаргалка для экзамена: что выполнить, где найти результат в Ubuntu и какими командами показать преподавателю, что пункт выполнен.

Подходит для Ubuntu в VirtualBox. Команды выполняются в терминале. Там, где требуется изменение системы, используется `sudo`.

---

## 0. Перед началом

Обновить систему:

```bash
sudo apt update
sudo apt upgrade -y
```

Посмотреть версию Ubuntu:

```bash
lsb_release -a
```

Посмотреть версию ядра:

```bash
uname -a
```

---

# 1. Использованы специальные утилиты для настройки ядра

## Как сделать

Установить утилиты:

```bash
sudo apt install -y tuned linux-tools-generic ubuntu-drivers-common
```

Включить `tuned`:

```bash
sudo systemctl enable --now tuned
sudo tuned-adm profile balanced
```

Создать файл параметров ядра:

```bash
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-exam-kernel.conf
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.d/99-exam-kernel.conf
echo "net.ipv4.tcp_syncookies=1" | sudo tee -a /etc/sysctl.d/99-exam-kernel.conf
echo "kernel.dmesg_restrict=1" | sudo tee -a /etc/sysctl.d/99-exam-kernel.conf
sudo sysctl --system
```

Проверить драйверы:

```bash
ubuntu-drivers devices
```

## Как показать преподавателю

```bash
uname -a
tuned-adm active
cat /etc/sysctl.d/99-exam-kernel.conf
sysctl vm.swappiness fs.inotify.max_user_watches net.ipv4.tcp_syncookies kernel.dmesg_restrict
ubuntu-drivers devices
```

## Где искать

```text
/etc/sysctl.conf
/etc/sysctl.d/
```

Что сказать:

```text
Использованы специальные утилиты sysctl, tuned и ubuntu-drivers. Через sysctl применены параметры ядра, tuned включён в профиле balanced, драйверы проверены через ubuntu-drivers.
```

---

# 2. SSH настроен

## Как сделать

```bash
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
sudo ufw allow ssh
```

Открыть конфигурацию SSH:

```bash
sudo nano /etc/ssh/sshd_config
```

Желательные параметры:

```text
Port 22
PermitRootLogin no
PasswordAuthentication yes
```

После изменения перезапустить SSH:

```bash
sudo systemctl restart ssh
```

## Как показать преподавателю

```bash
systemctl status ssh --no-pager
ss -tulpn | grep :22
ssh localhost
```

Если `ssh localhost` просит пароль или подключается, значит SSH работает.

## Где искать

```text
/etc/ssh/sshd_config
/etc/ssh/sshd_config.d/
```

Что сказать:

```text
SSH-сервер установлен, включён в автозагрузку, служба активна, порт 22 прослушивается.
```

---

# 3. Настроен удалённый доступ к активной сессии

## Вариант через настройки Ubuntu

Открыть:

```text
Настройки → Общий доступ → Удалённый рабочий стол
```

Включить:

```text
Удалённый рабочий стол
Удалённое управление
```

## Вариант через терминал, x11vnc

Установить:

```bash
sudo apt install -y x11vnc
```

Задать пароль:

```bash
x11vnc -storepasswd
```

Запустить удалённый доступ:

```bash
x11vnc -display :0 -auth guess -forever -shared
```

## Как показать преподавателю

В новом терминале:

```bash
ss -tulpn | grep 5900
ps aux | grep x11vnc
```

## Где искать

```text
Настройки → Общий доступ → Удалённый рабочий стол
```

Что сказать:

```text
Удалённый доступ к активной пользовательской сессии настроен через удалённый рабочий стол Ubuntu или x11vnc. Порт 5900 открыт для VNC-подключения.
```

---

# 4. Выбран правильный сетевой интерфейс

## Как сделать

Посмотреть интерфейсы:

```bash
ip -br addr
```

Посмотреть через NetworkManager:

```bash
nmcli device status
```

В VirtualBox чаще всего интерфейс называется:

```text
enp0s3
eth0
```

## Как показать преподавателю

```bash
ip -br addr
ip route
nmcli device status
```

## Где искать

```text
Настройки → Сеть
```

Что сказать:

```text
Активный сетевой интерфейс получил IP-адрес. Через него выполняется подключение к сети и интернету.
```

---

# 5. Продемонстрирована проверка сетевого соединения

## Как показать преподавателю

Проверить доступность IP:

```bash
ping -c 4 8.8.8.8
```

Проверить DNS:

```bash
ping -c 4 google.com
```

Проверить HTTP/HTTPS:

```bash
curl -I https://ubuntu.com
```

Что сказать:

```text
Проверка соединения выполнена через ping до IP-адреса, ping по доменному имени и curl до сайта. Интернет-соединение работает.
```

---

# 6. Установлено базовое программное обеспечение

## Как сделать

```bash
sudo apt install -y git curl wget nano vim htop tree p7zip-full unrar zip unzip libreoffice gimp vlc build-essential
```

## Как показать преподавателю

```bash
git --version
curl --version
wget --version
htop --version
7z
libreoffice --version
gimp --version
gcc --version
```

Или общим списком:

```bash
dpkg -l | grep -Ei "git|curl|wget|htop|p7zip|libreoffice|gimp|vlc|build-essential"
```

## Где искать

```text
Меню приложений Ubuntu → LibreOffice
Меню приложений Ubuntu → GIMP
Меню приложений Ubuntu → VLC
```

Что сказать:

```text
Установлен базовый набор программ: офисный пакет, графический редактор, архиватор, редакторы, сетевые утилиты и инструменты сборки.
```

---

# 7. Установлен виртуальный принтер

## Как сделать

```bash
sudo apt install -y cups printer-driver-cups-pdf system-config-printer
sudo systemctl enable --now cups
```

## Как показать преподавателю

```bash
systemctl status cups --no-pager
lpstat -p -d
```

Если установлен PDF-принтер, будет что-то похожее:

```text
printer PDF is idle
```

## Где искать

```text
Настройки → Принтеры
```

Или открыть графическую настройку:

```bash
system-config-printer
```

Что сказать:

```text
Установлен виртуальный PDF-принтер через CUPS. Он позволяет печатать документы в PDF-файл.
```

---

# 8. Выбор программных ресурсов обоснован

Команды здесь не нужны. Это объясняется словами в отчёте или устно.

## Универсальный текст

```text
Выбранное программное обеспечение соответствует задачам пользователя.
LibreOffice используется для работы с документами.
GIMP используется для обработки графики.
p7zip используется для работы с архивами.
OpenSSH используется для удалённого администрирования.
CUPS-PDF используется для создания PDF-документов через виртуальный принтер.
UFW, ClamAV и Fail2ban используются для базовой защиты системы.
```

## Для билета про Android-разработку

```text
Android Studio выбрана как основная среда разработки Android-приложений.
OpenJDK и Android Debug Bridge необходимы для сборки, запуска и отладки приложений.
Code::Blocks и GCC/G++ используются для компиляции программ на C/C++.
Blender используется как средство работы с 3D-графикой.
VirtualBox используется для создания виртуальных машин и эмуляции других операционных систем.
ClamAV, UFW и Fail2ban используются для защиты системы.
```

---

# 9. Выполнено резервное копирование установленной ОС

## Как сделать простой бэкап

Создать папку:

```bash
mkdir -p ~/exam_backup
```

Сделать резервную копию важных системных и пользовательских данных:

```bash
sudo tar -czvf ~/exam_backup/system_backup.tar.gz /etc /home/$USER /var/log
```

## Как показать преподавателю

```bash
ls -lh ~/exam_backup
file ~/exam_backup/system_backup.tar.gz
```

## Где искать

```text
Домашняя папка → exam_backup
```

Что сказать:

```text
Выполнено резервное копирование конфигурационных файлов системы, пользовательских данных и журналов. Архив находится в папке exam_backup.
```

---

# 10. Создан установочный образ системы

## Как сделать ISO-образ из резервной папки

Установить утилиту:

```bash
sudo apt install -y genisoimage
```

Создать ISO:

```bash
genisoimage -o ~/exam_system_image.iso ~/exam_backup
```

## Как показать преподавателю

```bash
ls -lh ~/exam_system_image.iso
file ~/exam_system_image.iso
```

## Где искать

```text
Домашняя папка → exam_system_image.iso
```

Что сказать:

```text
Создан ISO-образ с резервными файлами системы и пользовательскими настройками.
```

---

# 11. Созданы точки восстановления системы

## Как сделать через Timeshift

```bash
sudo apt install -y timeshift
sudo timeshift --create --comments "exam restore point" --tags D
```

## Как показать преподавателю

```bash
sudo timeshift --list
```

## Где искать

Открыть графически:

```bash
sudo timeshift-gtk
```

Или:

```text
Меню приложений → Timeshift
```

Что сказать:

```text
Создана точка восстановления системы через Timeshift. Её можно использовать для отката состояния системы.
```

---

# 12. Созданы группы пользователей

## Как сделать

```bash
sudo groupadd developers
sudo groupadd testers
sudo groupadd support
```

Добавить текущего пользователя в группы:

```bash
sudo usermod -aG developers,testers,support $USER
```

Важно: после добавления пользователя в группы желательно выйти из системы и зайти снова.

## Как показать преподавателю

```bash
getent group developers
getent group testers
getent group support
id $USER
```

Что сказать:

```text
Созданы группы developers, testers и support. Пользователь добавлен в эти группы для разграничения доступа.
```

---

# 13. Права доступа к ресурсам соответствуют служебным обязанностям

## Как сделать

Создать рабочие папки:

```bash
sudo mkdir -p /srv/company/projects
sudo mkdir -p /srv/company/testing
sudo mkdir -p /srv/company/support
```

Назначить группы:

```bash
sudo chgrp developers /srv/company/projects
sudo chgrp testers /srv/company/testing
sudo chgrp support /srv/company/support
```

Настроить права:

```bash
sudo chmod 770 /srv/company/projects
sudo chmod 770 /srv/company/testing
sudo chmod 770 /srv/company/support
```

Установить ACL:

```bash
sudo apt install -y acl
sudo setfacl -m g:developers:rwx /srv/company/projects
sudo setfacl -m g:testers:rwx /srv/company/testing
sudo setfacl -m g:support:rwx /srv/company/support
```

## Как показать преподавателю

```bash
ls -ld /srv/company/*
getfacl /srv/company/projects
getfacl /srv/company/testing
getfacl /srv/company/support
```

## Где искать

```text
Файловый менеджер → Другие места → Компьютер → srv → company
```

Что сказать:

```text
Права доступа разграничены по группам. Разработчики имеют доступ к projects, тестировщики к testing, поддержка к support.
```

---

# 14. Выполнена настройка аутентификации и авторизации

## Как сделать политику паролей

Установить модуль качества паролей:

```bash
sudo apt install -y libpam-pwquality
```

Открыть файл:

```bash
sudo nano /etc/security/pwquality.conf
```

Добавить или изменить параметры:

```text
minlen = 8
ucredit = -1
lcredit = -1
dcredit = -1
ocredit = -1
retry = 3
```

Настроить срок действия пароля:

```bash
sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' /etc/login.defs
sudo sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   7/' /etc/login.defs
```

Ограничить права sudo для группы support:

```bash
echo "%support ALL=(ALL) /usr/bin/systemctl, /usr/bin/apt" | sudo tee /etc/sudoers.d/exam_support
sudo chmod 440 /etc/sudoers.d/exam_support
sudo visudo -cf /etc/sudoers.d/exam_support
```

## Как показать преподавателю

```bash
cat /etc/security/pwquality.conf
grep '^PASS_' /etc/login.defs
sudo cat /etc/sudoers.d/exam_support
sudo visudo -cf /etc/sudoers.d/exam_support
```

## Где искать

```text
/etc/security/pwquality.conf
/etc/login.defs
/etc/sudoers.d/
```

Что сказать:

```text
Настроены требования к сложности паролей, срок действия паролей и ограничение административных прав через sudoers.
```

---

# 15. Журнал мониторинга настроен

## Как сделать

Установить auditd:

```bash
sudo apt install -y auditd audispd-plugins
sudo systemctl enable --now auditd
```

Добавить правила аудита:

```bash
echo "-w /etc/passwd -p wa -k passwd_changes" | sudo tee /etc/audit/rules.d/exam.rules
echo "-w /etc/group -p wa -k group_changes" | sudo tee -a /etc/audit/rules.d/exam.rules
echo "-w /etc/sudoers -p wa -k sudoers_changes" | sudo tee -a /etc/audit/rules.d/exam.rules
sudo augenrules --load
```

## Как показать преподавателю

```bash
systemctl status auditd --no-pager
sudo auditctl -l
journalctl -n 30 --no-pager
```

## Где искать

```text
/etc/audit/rules.d/exam.rules
/var/log/audit/audit.log
```

Что сказать:

```text
Настроен журнал мониторинга через auditd. Отслеживаются изменения файлов пользователей, групп и sudoers.
```

---

# 16. Установлено требуемое программное обеспечение

Раздел для билета про Android-разработку.

---

## 16.1 Android Studio

### Как сделать

```bash
sudo snap install android-studio --classic
```

### Как показать

```bash
snap list android-studio
```

Запуск:

```bash
android-studio
```

Где искать:

```text
Меню приложений → Android Studio
```

---

## 16.2 Java и ADB

### Как сделать

```bash
sudo apt install -y openjdk-17-jdk android-tools-adb
```

### Как показать

```bash
java -version
javac -version
adb version
```

---

## 16.3 Code::Blocks и компиляторы

### Как сделать

```bash
sudo apt install -y codeblocks build-essential gcc g++ make cmake
```

### Как показать

```bash
codeblocks --version
gcc --version
g++ --version
make --version
cmake --version
```

Запуск:

```bash
codeblocks
```

Где искать:

```text
Меню приложений → Code::Blocks
Code::Blocks → Settings → Compiler
```

---

## 16.4 Blender

### Как сделать

```bash
sudo apt install -y blender
```

### Как показать

```bash
blender --version
```

Запуск:

```bash
blender
```

Где искать:

```text
Меню приложений → Blender
```

---

## 16.5 VirtualBox

### Как сделать

```bash
sudo apt install -y virtualbox
```

### Как показать

```bash
virtualbox --help
vboxmanage --version
```

Запуск:

```bash
virtualbox
```

Где искать:

```text
Меню приложений → VirtualBox
```

---

## 16.6 Защитное ПО

### Как сделать

```bash
sudo apt install -y ufw clamav clamav-daemon fail2ban
```

Включить UFW:

```bash
sudo ufw enable
```

Включить Fail2ban:

```bash
sudo systemctl enable --now fail2ban
```

Обновить базы ClamAV:

```bash
sudo freshclam
```

### Как показать

```bash
sudo ufw status verbose
clamscan --version
systemctl status fail2ban --no-pager
fail2ban-client status
```

Что сказать:

```text
Для защиты системы установлены UFW, ClamAV и Fail2ban. UFW отвечает за фильтрацию сетевых подключений, ClamAV за проверку файлов, Fail2ban за защиту сетевых служб от перебора паролей.
```

---

# 17. Выполнена стартовая настройка интерфейса программы

## Android Studio

Запуск:

```bash
android-studio
```

Что показать:

```text
Android Studio открыта.
Выбрана стандартная тема.
Установлен Android SDK.
Создан или открыт стартовый проект.
```

Где искать:

```text
Android Studio → Settings → Appearance
Android Studio → Settings → Languages & Frameworks → Android SDK
```

---

## Code::Blocks

Запуск:

```bash
codeblocks
```

Что показать:

```text
Code::Blocks открывается.
Компилятор GCC определён.
Можно создать C/C++ проект.
```

Где искать:

```text
Code::Blocks → Settings → Compiler
```

---

## Blender

Запуск:

```bash
blender
```

Что показать:

```text
Blender запускается.
Интерфейс открыт.
3D-сцена отображается корректно.
```

---

# 18. Выполнена настройка обмена данными с другими системами

Можно показать через SSH, Samba, Git и ADB.

---

## 18.1 SSH

Показать:

```bash
systemctl status ssh --no-pager
ssh localhost
```

---

## 18.2 Samba-общая папка

### Как сделать

```bash
sudo apt install -y samba
sudo mkdir -p /srv/share
sudo chmod 777 /srv/share
```

Открыть конфиг:

```bash
sudo nano /etc/samba/smb.conf
```

В конец добавить:

```text
[exam_share]
path = /srv/share
read only = no
browseable = yes
guest ok = yes
```

Перезапустить Samba:

```bash
sudo systemctl restart smbd
```

### Как показать

```bash
testparm -s
systemctl status smbd --no-pager
```

Где искать:

```text
Файлы → Другие места → Сеть
```

---

## 18.3 Git

```bash
git --version
git config --global user.name "Exam User"
git config --global user.email "exam@example.com"
git config --list
```

---

## 18.4 ADB

```bash
adb version
adb devices
```

Что сказать:

```text
Обмен данными настроен через SSH, Samba, Git и ADB. SSH используется для удалённого подключения, Samba для сетевой папки, Git для обмена исходным кодом, ADB для связи с Android-устройствами и эмуляторами.
```

---

# 19. Совместимость программного обеспечения с ОС

Эти пункты похожи на Windows, но в Ubuntu можно показать аналоги: разрешение, масштабирование, отключение анимаций и запуск программ с параметрами масштаба.

---

## 19.1 Ограниченная цветовая палитра и проблемы отображения

Проверить дисплей:

```bash
xrandr
```

Где искать:

```text
Настройки → Дисплеи
```

---

## 19.2 Низкое разрешение

Через настройки:

```text
Настройки → Дисплеи → Разрешение → 1024×768
```

Через терминал сначала узнать имя монитора:

```bash
xrandr
```

Пример для `Virtual-1`:

```bash
xrandr --output Virtual-1 --mode 1024x768
```

Пример для `HDMI-1`:

```bash
xrandr --output HDMI-1 --mode 1024x768
```

---

## 19.3 Решены проблемы с меню и кнопками

Отключить масштабирование:

```text
Настройки → Дисплеи → Масштаб → 100%
```

Для GTK-приложений:

```bash
GDK_SCALE=1 GDK_DPI_SCALE=1 имя_программы
```

Для Qt-приложений:

```bash
QT_SCALE_FACTOR=1 имя_программы
```

Пример:

```bash
QT_SCALE_FACTOR=1 codeblocks
```

---

## 19.4 Отключена композиция рабочего стола

В GNOME напрямую композиция не отключается как в Windows, но можно отключить анимации:

```bash
gsettings set org.gnome.desktop.interface enable-animations false
```

Показать:

```bash
gsettings get org.gnome.desktop.interface enable-animations
```

Должно быть:

```text
false
```

---

## 19.5 Отключено масштабирование изображения при высоком разрешении

Где искать:

```text
Настройки → Дисплеи → Масштаб → 100%
```

Показать через терминал:

```bash
gsettings get org.gnome.desktop.interface text-scaling-factor
```

Поставить стандартное значение:

```bash
gsettings set org.gnome.desktop.interface text-scaling-factor 1.0
```

Что сказать:

```text
Параметры совместимости проверены через настройки дисплея. Масштаб установлен на 100%, анимации отключены, при необходимости программа запускается с переменными масштаба GDK_SCALE или QT_SCALE_FACTOR.
```

---

# 20. Подготовлена документация пользователя

## Как сделать

Открыть LibreOffice Writer:

```bash
libreoffice --writer
```

Создать документ:

```text
Руководство пользователя
```

Структура документа:

```text
1. Наименование программного обеспечения
2. Назначение программы
3. Краткое описание
4. Требования к системе
5. Порядок запуска
6. Основные функции
7. Основные приёмы работы
8. Настройка интерфейса
9. Обмен данными с другими системами
10. Завершение работы
```

## Как показать преподавателю

Проверить документы:

```bash
ls -lh ~/Документы
find ~ -iname "*Руковод*"
```

Где искать:

```text
Домашняя папка → Документы → Руководство пользователя.odt
```

---

# 21. Руководство по использованию ПО

Пример текста для Android Studio:

```text
Руководство пользователя Android Studio

1. Наименование программы
Android Studio.

2. Назначение
Android Studio предназначена для разработки мобильных приложений под Android.

3. Запуск
Программа запускается через меню приложений Ubuntu или командой android-studio.

4. Основные функции
- создание Android-проектов;
- редактирование исходного кода;
- сборка приложений;
- запуск приложений на эмуляторе или устройстве;
- отладка приложений;
- управление Android SDK.

5. Основные приёмы работы
Для создания проекта необходимо выбрать New Project, указать шаблон приложения,
выбрать язык программирования и минимальную версию Android. После создания проекта
можно редактировать файлы, запускать сборку и проверять приложение.

6. Обмен данными
Обмен данными выполняется через Android SDK, ADB, Git и сетевые подключения.

7. Завершение работы
Для завершения работы необходимо сохранить проект и закрыть Android Studio.
```

---

# 22. Финальная проверка в конце экзамена

Скопировать и выполнить по очереди:

```bash
uname -a
lsb_release -a
```

```bash
tuned-adm active
sysctl vm.swappiness fs.inotify.max_user_watches net.ipv4.tcp_syncookies
```

```bash
systemctl status ssh --no-pager
ss -tulpn | grep :22
```

```bash
ip -br addr
ip route
ping -c 4 8.8.8.8
ping -c 4 google.com
```

```bash
lpstat -p -d
```

```bash
ls -lh ~/exam_backup
ls -lh ~/exam_system_image.iso
sudo timeshift --list
```

```bash
getent group developers testers support
id $USER
ls -ld /srv/company/*
getfacl /srv/company/projects
```

```bash
cat /etc/security/pwquality.conf
grep '^PASS_' /etc/login.defs
```

```bash
systemctl status auditd --no-pager
sudo auditctl -l
```

```bash
sudo ufw status verbose
clamscan --version
fail2ban-client status
```

```bash
snap list
dpkg -l | grep -Ei "android|studio|java|adb|codeblocks|gcc|g\+\+|blender|virtualbox|clamav|fail2ban|libreoffice|gimp"
```

```bash
find ~ -iname "*Руковод*"
```

---

# 23. Что говорить преподавателю

```text
Я показываю выполнение не по отдельному отчёту, а через системные команды.
Службы проверяются через systemctl status.
Открытые порты проверяются через ss.
Установленные программы проверяются через dpkg -l и snap list.
Сетевое подключение проверяется через ip addr, ip route и ping.
Группы пользователей проверяются через getent group и id.
Права доступа проверяются через ls -ld и getfacl.
Журнал мониторинга проверяется через auditctl и journalctl.
Документация пользователя создана в LibreOffice Writer.
```

---

# 24. Самые важные места в Ubuntu

```text
Настройки → Сеть
Настройки → Принтеры
Настройки → Общий доступ
Настройки → Дисплеи
Меню приложений → Timeshift
Меню приложений → Android Studio
Меню приложений → Code::Blocks
Меню приложений → Blender
Меню приложений → VirtualBox
```

---

# 25. Быстрая таблица: критерий — чем доказать

| Критерий | Чем доказать |
|---|---|
| Утилиты ядра | `tuned-adm active`, `sysctl`, `/etc/sysctl.d/99-exam-kernel.conf` |
| SSH | `systemctl status ssh`, `ss -tulpn | grep :22` |
| Удалённый доступ | `ss -tulpn | grep 5900`, настройки общего доступа |
| Сетевой интерфейс | `ip -br addr`, `nmcli device status` |
| Проверка интернета | `ping 8.8.8.8`, `ping google.com` |
| Базовое ПО | `dpkg -l`, `git --version`, `libreoffice --version` |
| Виртуальный принтер | `lpstat -p -d`, настройки принтеров |
| Обоснование ПО | текст в отчёте или устный ответ |
| Резервное копирование | `ls -lh ~/exam_backup` |
| ISO-образ | `ls -lh ~/exam_system_image.iso` |
| Точки восстановления | `sudo timeshift --list` |
| Группы пользователей | `getent group`, `id $USER` |
| Права доступа | `ls -ld`, `getfacl` |
| Авторизация | `/etc/security/pwquality.conf`, `/etc/sudoers.d/` |
| Журналы | `systemctl status auditd`, `auditctl -l` |
| Требуемое ПО | `snap list`, `dpkg -l`, версии программ |
| Интерфейс программ | запустить программу и показать настройки |
| Обмен данными | SSH, Samba, Git, ADB |
| Совместимость | настройки дисплея, `gsettings`, `xrandr` |
| Документация | файл `Руководство пользователя.odt` |

