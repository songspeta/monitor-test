# 🚀 Мониторинг процесса `test` с отправкой уведомлений по HTTPS

Этот проект реализует **автоматический мониторинг** наличия и стабильности процесса с именем `test` в Linux-системе. При обнаружении запущенного процесса — отправляется **HTTPS POST-запрос** на заданный URL мониторинга. Также отслеживаются **перезапуски процесса** и **недоступность сервера мониторинга**, с записью соответствующих событий в раздельные лог-файлы.

---

## 🎯 Основные возможности

- ✅ Проверка наличия процесса `test` каждую минуту.
- ✅ Отправка **POST-запроса по HTTPS** на `https://test.com/monitoring/test/api`, если процесс запущен.
- ✅ Отслеживание **изменения PID** → фиксация перезапуска процесса.
- ✅ Раздельные логи:
  - `/var/log/monitoring_restart.log` — перезапуски процесса.
  - `/var/log/monitoring_error.log` — ошибки доступа к серверу мониторинга.
- ✅ Автоматический запуск через **systemd timer** (каждую минуту).
- ✅ Поддержка тестирования через **локальный Nginx в Docker** с самоподписанным SSL-сертификатом.

---

## 📁 Структура репозитория
├── monitor_test.sh # Основной скрипт мониторинга\
├── monitor-test.service # systemd-сервис\
├── monitor-test.timer # systemd-таймер\
└── README.md # Этот файл


---

## 🛠 Установка и настройка

### 1. Клонирование репозитория

```bash
git clone https://github.com/songspeta/monitor-test.git
cd monitor-test 
```
### 2. Установка скрипта

```bash
sudo cp monitor_test.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/monitor_test.sh
```
### 3. Настройка systemd
```bash 
sudo cp monitor-test.service /etc/systemd/system/
sudo cp monitor-test.timer /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable monitor-test.timer
sudo systemctl start monitor-test.timer
```
## 📊 Логирование
Скрипт пишет в два файла:

- Перезапуски процесса:
```bash 
tail -f /var/log/monitoring_restart.log
```
Пример записи:
```bash
2025-04-16 12:30:00 - Процесс перезапущен, PID изменился с 1234 на 5678
```
- Ошибки доступа к серверу:
```bash
tail -f /var/log/monitoring_error.log
```
Пример записи:
```bash
2025-04-16 12:31:00 - Сервер мониторинга недоступен: https://test.com/monitoring/test/api
```
## 🧪 Тестирование (локально)
Так как test.com  недоступен для запросов, для тестирования можно использовать локальный Nginx в Docker.

### 1. Генерация SSL-сертификата
```bash
openssl req -x509 -nodes -newkey rsa:2048 -keyout /tmp/nginx.key -out /tmp/nginx.crt -days 365 -subj "/C=RU/ST=Moscow/L=Moscow/O=Test/CN=test.com"
```
### 2. Создание конфига Nginx
```bash 
cat > tmp/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl;
        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;

        location /monitoring/test/api {
            return 200 "OK\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF
```
### 3. Запуск Nginx в Docker
```bash 
docker run -d \
  --name test-monitoring-server \
  -p 443:443 \
  -v /tmp/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v /tmp/nginx.crt:/etc/nginx/ssl/nginx.crt:ro \
  -v /tmp/nginx.key:/etc/nginx/ssl/nginx.key:ro \
  nginx:alpine
  ```
  ### 4. Настройка DNS
  ```bash 
  echo "127.0.0.1 test.com" | sudo tee -a /etc/hosts
  ```
## 📝 Примечание: зачем два лог-файла и расширяемость

Разделение логов на два файла для упрощения мониторинга и отладки:
- monitoring_restart.log содержит только события перезапуска процесса
- monitoring_error.log фиксирует проблемы с внешними зависимостями

ЭТО:

- Позволяет настроить раздельную ротацию логов
- Облегчает интеграцию с системами сбора логов
- В будущем в эти файлы можно расширить функциональность
