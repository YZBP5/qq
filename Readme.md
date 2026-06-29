Понял. Ниже шпора без скриптов: по каждому пункту — как сделать, как показать преподавателю, где искать в настройках Ubuntu. Это можно прямо закинуть себе на сайт/в GitHub как команды для экзамена. Пункты идут по твоим критериям из билета. 


---

0. Базовые команды перед началом

Обновить систему:

sudo apt update
sudo apt upgrade -y

Посмотреть версию Ubuntu:

lsb_release -a

Посмотреть ядро:

uname -a


---

1. Использованы специальные утилиты для настройки ядра

Как сделать

Установить утилиты:

sudo apt install -y tuned linux-tools-generic ubuntu-drivers-common

Включить профиль оптимизации:

sudo systemctl enable --now tuned
sudo tuned-adm profile balanced

Настроить параметры ядра:

echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-exam-kernel.conf
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.d/99-exam-kernel.conf
echo "net.ipv4.tcp_syncookies=1" | sudo tee -a /etc/sysctl.d/99-exam-kernel.conf
echo "kernel.dmesg_restrict=1" | sudo tee -a /etc/sysctl.d/99-exam-kernel.conf
sudo sysctl --system

Проверить драйверы:

ubuntu-drivers devices

Как показать

uname -a
tuned-adm active
cat /etc/sysctl.d/99-exam-kernel.conf
sysctl vm.swappiness fs.inotify.max_user_watches net.ipv4.tcp_syncookies kernel.dmesg_restrict
ubuntu-drivers devices

Где искать

В файлах:

/etc/sysctl.conf
/etc/sysctl.d/


---

2. SSH настроен

Как сделать

sudo apt install -y openssh-server
sudo systemctl enable --now ssh
sudo ufw allow ssh

Дополнительно проверить конфиг:

sudo nano /etc/ssh/sshd_config

Желательно, чтобы было:

Port 22
PermitRootLogin no
PasswordAuthentication yes

После изменения:

sudo systemctl restart ssh

Как показать

systemctl status ssh --no-pager
ss -tulpn | grep :22
ssh localhost

Если ssh localhost спросил пароль или подключился — SSH работает.

Где искать

/etc/ssh/sshd_config
/etc/ssh/sshd_config.d/


---

3. Удалённый доступ к активной сессии

Вариант через настройки Ubuntu

Открыть:

Настройки → Общий доступ → Удалённый рабочий стол

Включить:

Удалённый рабочий стол
Удалённое управление

Вариант через терминал — x11vnc

Установить:

sudo apt install -y x11vnc

Задать пароль:

x11vnc -storepasswd

Запустить удалённый доступ:

x11vnc -display :0 -auth guess -forever -shared

Как показать

В другом терминале:

ss -tulpn | grep 5900

Или:

ps aux | grep x11vnc

Где искать

В настройках:

Настройки → Общий доступ → Удалённый рабочий стол


---

4. Выбран правильный сетевой интерфейс

Как сделать

Обычно в VirtualBox интерфейс называется:

enp0s3
eth0

Посмотреть интерфейсы:

ip -br addr

Посмотреть через NetworkManager:

nmcli device status

Как показать

ip -br addr
ip route
nmcli device status

Пример, что говорить:

Активный интерфейс enp0s3 получил IP-адрес. Через него настроено интернет-соединение.

Где искать

Настройки → Сеть


---

5. Проверка интернет-соединения

Как показать

ping -c 4 8.8.8.8
ping -c 4 google.com

Дополнительно:

curl -I https://ubuntu.com

Если 8.8.8.8 работает, а google.com нет — проблема с DNS.
Если оба работают — интернет настроен нормально.


---

6. Установлено базовое программное обеспечение

Как сделать

sudo apt install -y git curl wget nano vim htop tree p7zip-full unrar zip unzip libreoffice gimp vlc build-essential

Как показать

git --version
curl --version
wget --version
htop --version
7z
libreoffice --version
gimp --version
gcc --version

Или общим списком:

dpkg -l | grep -Ei "git|curl|wget|htop|p7zip|libreoffice|gimp|vlc|build-essential"

Где искать

Меню приложений Ubuntu → LibreOffice
Меню приложений Ubuntu → GIMP
Меню приложений Ubuntu → VLC


---

7. Установлен виртуальный принтер

Как сделать

sudo apt install -y cups printer-driver-cups-pdf system-config-printer
sudo systemctl enable --now cups

Как показать

systemctl status cups --no-pager
lpstat -p -d

Если установлен PDF-принтер, будет что-то типа:

printer PDF is idle

Где искать

Настройки → Принтеры

Или открыть:

system-config-printer


---

8. Выбор программных ресурсов обоснован

Тут команды не нужны. Это пишется словами в отчёте.

Пример текста:

Выбранное программное обеспечение соответствует задачам пользователя. 
LibreOffice используется для работы с документами, GIMP — для графики, 
7-Zip/p7zip — для архивов, OpenSSH — для удалённого администрирования, 
CUPS-PDF — для создания PDF-документов через виртуальный принтер, 
UFW/ClamAV/Fail2ban — для базовой защиты системы.

Для билета про Android-разработку:

Android Studio выбрана как основная среда разработки Android-приложений.
OpenJDK и Android Debug Bridge необходимы для сборки, запуска и отладки приложений.
Code::Blocks и GCC/G++ используются для компиляции программ на C/C++.
Blender используется как средство работы с 3D-графикой.
VirtualBox используется для создания виртуальных машин и эмуляции других ОС.
ClamAV, UFW и Fail2ban используются для защиты системы.


---

9. Выполнено резервное копирование установленной ОС

Простой вариант через архив

Создать папку:

mkdir -p ~/exam_backup

Сделать резервную копию важных настроек:

sudo tar -czvf ~/exam_backup/system_backup.tar.gz /etc /home/$USER /var/log

Как показать

ls -lh ~/exam_backup
file ~/exam_backup/system_backup.tar.gz

Где искать

Домашняя папка → exam_backup


---

10. Создан установочный образ системы

Как сделать ISO-образ из резервной папки

Установить утилиту:

sudo apt install -y genisoimage

Создать ISO:

genisoimage -o ~/exam_system_image.iso ~/exam_backup

Как показать

ls -lh ~/exam_system_image.iso
file ~/exam_system_image.iso

Где искать

Домашняя папка → exam_system_image.iso

Фраза для преподавателя:

Создан ISO-образ с резервными файлами системы и пользовательскими настройками.


---

11. Созданы точки восстановления системы

Как сделать через Timeshift

sudo apt install -y timeshift
sudo timeshift --create --comments "exam restore point" --tags D

Как показать

sudo timeshift --list

Где искать

Открыть графически:

sudo timeshift-gtk

Или в меню:

Меню приложений → Timeshift


---

12. Созданы группы пользователей

Как сделать

sudo groupadd developers
sudo groupadd testers
sudo groupadd support

Добавить текущего пользователя в группы:

sudo usermod -aG developers,testers,support $USER

Как показать

getent group developers
getent group testers
getent group support
id $USER

Важно: после добавления в группу лучше выйти из системы и зайти снова.


---

13. Права доступа к ресурсам настроены

Как сделать

Создать папки:

sudo mkdir -p /srv/company/projects
sudo mkdir -p /srv/company/testing
sudo mkdir -p /srv/company/support

Назначить группы:

sudo chgrp developers /srv/company/projects
sudo chgrp testers /srv/company/testing
sudo chgrp support /srv/company/support

Настроить права:

sudo chmod 770 /srv/company/projects
sudo chmod 770 /srv/company/testing
sudo chmod 770 /srv/company/support

Установить ACL:

sudo apt install -y acl
sudo setfacl -m g:developers:rwx /srv/company/projects
sudo setfacl -m g:testers:rwx /srv/company/testing
sudo setfacl -m g:support:rwx /srv/company/support

Как показать

ls -ld /srv/company/*
getfacl /srv/company/projects
getfacl /srv/company/testing
getfacl /srv/company/support

Где искать

Файловый менеджер → Другие места → Компьютер → srv → company


---

14. Выполнена настройка аутентификации и авторизации

Как сделать настройку политики паролей

sudo apt install -y libpam-pwquality

Открыть файл:

sudo nano /etc/security/pwquality.conf

Добавить или изменить:

minlen = 8
ucredit = -1
lcredit = -1
dcredit = -1
ocredit = -1
retry = 3

Настроить срок действия пароля:

sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' /etc/login.defs
sudo sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   7/' /etc/login.defs

Ограничить права sudo для группы support

echo "%support ALL=(ALL) /usr/bin/systemctl, /usr/bin/apt" | sudo tee /etc/sudoers.d/exam_support
sudo chmod 440 /etc/sudoers.d/exam_support
sudo visudo -cf /etc/sudoers.d/exam_support

Как показать

cat /etc/security/pwquality.conf
grep '^PASS_' /etc/login.defs
sudo cat /etc/sudoers.d/exam_support
sudo visudo -cf /etc/sudoers.d/exam_support

Где искать

/etc/security/pwquality.conf
/etc/login.defs
/etc/sudoers.d/


---

15. Журнал мониторинга настроен

Как сделать

Установить auditd:

sudo apt install -y auditd audispd-plugins
sudo systemctl enable --now auditd

Добавить правила аудита:

echo "-w /etc/passwd -p wa -k passwd_changes" | sudo tee /etc/audit/rules.d/exam.rules
echo "-w /etc/group -p wa -k group_changes" | sudo tee -a /etc/audit/rules.d/exam.rules
echo "-w /etc/sudoers -p wa -k sudoers_changes" | sudo tee -a /etc/audit/rules.d/exam.rules
sudo augenrules --load

Как показать

systemctl status auditd --no-pager
sudo auditctl -l
journalctl -n 30 --no-pager

Где искать

/etc/audit/rules.d/exam.rules
/var/log/audit/audit.log


---

16. Установлено требуемое программное обеспечение

Для билета про Android-разработку.

Android Studio

sudo snap install android-studio --classic

Показать:

snap list android-studio

Запуск:

android-studio

Или:

Меню приложений → Android Studio


---

Java и ADB

sudo apt install -y openjdk-17-jdk android-tools-adb

Показать:

java -version
javac -version
adb version


---

Code::Blocks и компиляторы

sudo apt install -y codeblocks build-essential gcc g++ make cmake

Показать:

codeblocks --version
gcc --version
g++ --version
make --version
cmake --version

Запуск:

codeblocks


---

Blender — эмулятор/редактор 3D-графики

sudo apt install -y blender

Показать:

blender --version

Запуск:

blender


---

VirtualBox — эмулятор/виртуализация ОС

sudo apt install -y virtualbox

Показать:

virtualbox --help
vboxmanage --version

Запуск:

virtualbox


---

Защитное ПО

sudo apt install -y ufw clamav clamav-daemon fail2ban

Включить защиту:

sudo ufw enable
sudo systemctl enable --now fail2ban

Обновить базы ClamAV:

sudo freshclam

Показать:

sudo ufw status verbose
clamscan --version
systemctl status fail2ban --no-pager
fail2ban-client status


---

17. Базовая настройка интерфейса программы

Тут обычно показываешь, что программа запущена и выполнена первичная настройка.

Android Studio

Запуск:

android-studio

Что показать:

Android Studio открыта.
Выбрана стандартная тема.
Установлен Android SDK.
Создан или открыт стартовый проект.

Где искать:

Android Studio → Settings → Appearance
Android Studio → Settings → Languages & Frameworks → Android SDK


---

Code::Blocks

Запуск:

codeblocks

Что показать:

Code::Blocks открывается.
Компилятор GCC определён.
Можно создать C/C++ проект.

Где искать:

Code::Blocks → Settings → Compiler


---

Blender

Запуск:

blender

Что показать:

Blender запускается.
Интерфейс открыт.
3D-сцена отображается корректно.


---

18. Настройка обмена данными с другими системами

Можно показать через SSH, Samba, Git и ADB.

SSH уже есть

Показать:

systemctl status ssh --no-pager
ssh localhost


---

Samba-общая папка

Установить:

sudo apt install -y samba

Создать папку обмена:

sudo mkdir -p /srv/share
sudo chmod 777 /srv/share

Открыть конфиг:

sudo nano /etc/samba/smb.conf

В конец добавить:

[exam_share]
path = /srv/share
read only = no
browseable = yes
guest ok = yes

Перезапустить:

sudo systemctl restart smbd

Показать:

testparm -s
systemctl status smbd --no-pager

Где искать

Файлы → Другие места → Сеть


---

Git

git --version
git config --global user.name "Exam User"
git config --global user.email "exam@example.com"
git config --list


---

ADB для Android

adb version
adb devices


---

19. Совместимость программ с установленной ОС

Эти пункты больше похожи на Windows, но в Ubuntu можно показать аналоги: разрешение, масштабирование, отключение анимации, запуск с переменными масштабирования.


---

Ограниченная цветовая палитра / проблемы отображения

Проверить текущий дисплей:

xrandr

Где искать:

Настройки → Дисплеи


---

Низкое разрешение

Поставить разрешение через настройки:

Настройки → Дисплеи → Разрешение → 1024×768

Через терминал сначала узнать имя монитора:

xrandr

Пример, если монитор называется Virtual-1:

xrandr --output Virtual-1 --mode 1024x768

Если называется HDMI-1, команда будет:

xrandr --output HDMI-1 --mode 1024x768


---

Проблемы с меню и кнопками

Отключить масштабирование:

Настройки → Дисплеи → Масштаб → 100%

Для GTK-приложений:

GDK_SCALE=1 GDK_DPI_SCALE=1 имя_программы

Для Qt-приложений:

QT_SCALE_FACTOR=1 имя_программы

Пример:

QT_SCALE_FACTOR=1 codeblocks


---

Отключена композиция рабочего стола

В GNOME напрямую композиция не отключается как в Windows, но можно отключить анимации:

gsettings set org.gnome.desktop.interface enable-animations false

Показать:

gsettings get org.gnome.desktop.interface enable-animations

Должно быть:

false


---

Отключено масштабирование при высоком разрешении

Где искать:

Настройки → Дисплеи → Масштаб → 100%

Показать через терминал:

gsettings get org.gnome.desktop.interface text-scaling-factor

Можно поставить стандарт:

gsettings set org.gnome.desktop.interface text-scaling-factor 1.0


---

20. Подготовлена документация пользователя

Как сделать

Открыть LibreOffice Writer:

libreoffice --writer

Создать документ:

Руководство пользователя

Структура:

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

Как показать

Файл должен лежать, например:

/home/имя_пользователя/Документы/Руководство пользователя.odt

Проверить:

ls -lh ~/Документы

Или:

find ~ -iname "*Руковод*"


---

21. Руководство по использованию ПО

Пример текста для Android Studio:

Руководство пользователя Android Studio

1. Наименование программы:
Android Studio.

2. Назначение:
Android Studio предназначена для разработки мобильных приложений под Android.

3. Запуск:
Программа запускается через меню приложений Ubuntu или командой android-studio.

4. Основные функции:
- создание Android-проектов;
- редактирование исходного кода;
- сборка приложений;
- запуск приложений на эмуляторе или устройстве;
- отладка приложений;
- управление Android SDK.

5. Основные приёмы работы:
Для создания проекта необходимо выбрать New Project, указать шаблон приложения,
выбрать язык программирования и минимальную версию Android. После создания проекта
можно редактировать файлы, запускать сборку и проверять приложение.

6. Обмен данными:
Обмен данными выполняется через Android SDK, ADB, Git и сетевые подключения.

7. Завершение работы:
Для завершения работы необходимо сохранить проект и закрыть Android Studio.


---

22. Самый короткий набор команд для демонстрации в конце

Вот это можно сохранить отдельно как блок “ФИНАЛЬНАЯ ПРОВЕРКА”:

uname -a
lsb_release -a
tuned-adm active
sysctl vm.swappiness fs.inotify.max_user_watches net.ipv4.tcp_syncookies
systemctl status ssh --no-pager
ss -tulpn | grep :22
ip -br addr
ip route
ping -c 4 8.8.8.8
ping -c 4 google.com
lpstat -p -d
ls -lh ~/exam_backup
ls -lh ~/exam_system_image.iso
sudo timeshift --list
getent group developers testers support
id $USER
ls -ld /srv/company/*
getfacl /srv/company/projects
cat /etc/security/pwquality.conf
grep '^PASS_' /etc/login.defs
systemctl status auditd --no-pager
sudo auditctl -l
sudo ufw status verbose
clamscan --version
fail2ban-client status
snap list
dpkg -l | grep -Ei "android|studio|java|adb|codeblocks|gcc|g\+\+|blender|virtualbox|clamav|fail2ban|libreoffice|gimp"
find ~ -iname "*Руковод*"


---

23. Что говорить, если преподаватель спрашивает “где это видно?”

Я показываю выполнение не по отчёту, а через системные команды.
Службы проверяются через systemctl status.
Открытые порты проверяются через ss.
Установленные программы проверяются через dpkg -l и snap list.
Сетевое подключение проверяется через ip addr, ip route и ping.
Группы пользователей проверяются через getent group и id.
Права доступа проверяются через ls -ld и getfacl.
Журнал мониторинга проверяется через auditctl и journalctl.
Документация пользователя создана в LibreOffice Writer.

Самые важные места в Ubuntu:

Настройки → Сеть
Настройки → Принтеры
Настройки → Общий доступ
Настройки → Дисплеи
Меню приложений → Timeshift
Меню приложений → Android Studio
Меню приложений → Code::Blocks
Меню приложений → Blender
Меню приложений → VirtualBox
