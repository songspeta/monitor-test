#!/bin/bash

# Логи 
RESTART_LOG="/var/log/monitoring_restart.log"
ERROR_LOG="/var/log/monitoring_error.log"
PID_FILE="/var/run/test_process.pid"
MONITORING_URL="https://test.com/monitoring/test/api" 
# Создаем лог-файлы если не существуют
touch "$RESTART_LOG" "$ERROR_LOG"
chmod 644 "$RESTART_LOG" "$ERROR_LOG"

# Проверяем доступность curl
if ! command -v curl &> /dev/null; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Ошибка: curl не установлен" >> "$ERROR_LOG"
    exit 1
fi

# Получаем PID процесса test
CURRENT_PID=$(pgrep -x "test")

if [ -n "$CURRENT_PID" ]; then
    # Процесс запущен

    # Проверяем, изменился ли PID
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if [ "$OLD_PID" != "$CURRENT_PID" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Процесс перезапущен, PID изменился с $OLD_PID на $CURRENT_PID" >> "$RESTART_LOG"
        fi
    fi

    # Сохраняем текущий PID
    echo "$CURRENT_PID" > "$PID_FILE"

    # Проверяем доступность сервера мониторинга
    if curl -k -s --head --fail "$MONITORING_URL" > /dev/null; then
        # Отправляем POST-запрос
        RESPONSE=$(curl -k -s -X POST "$MONITORING_URL" -o /dev/null -w "%{http_code}")
        if [ "$RESPONSE" != "200" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Ошибка при отправке уведомления: HTTP $RESPONSE" >> "$ERROR_LOG"
        fi
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Сервер мониторинга недоступен: $MONITORING_URL" >> "$ERROR_LOG"
    fi
else
    # Процесс не запущен — ничего не делаем
    # Удаляем PID-файл, если процесс исчез
    [ -f "$PID_FILE" ] && rm -f "$PID_FILE"
fi
