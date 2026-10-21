#!/bin/bash

# Создание тестовых директорий
TEST_LOG_DIR="/tmp/test_log"
rm -rf "$TEST_LOG_DIR"
mkdir -p "$TEST_LOG_DIR"

echo "=== ПОДГОТОВКА ТЕСТОВОЙ СРЕДЫ ==="
# Создание 3 файлов записей журнала с разным временем изменения (имитация старых и новых)
touch -d "2 hours ago" "$TEST_LOG_DIR/oldest_file.log"
touch -d "1 hour ago"  "$TEST_LOG_DIR/medium_file.log"
touch                  "$TEST_LOG_DIR/newest_file.log"

echo "Созданы тестовые файлы в $TEST_LOG_DIR"
ls -lt "$TEST_LOG_DIR"
echo "----------------------------------------"

echo "=== ТЕСТ-КЕЙС 1: Порог N не превышен ==="
# Установка высокого порога 99%, чтобы архивация не сработала
./OneLabWork.sh "$TEST_LOG_DIR" 99 2
echo "Статус выполнения Тест-кейса 1: $?"
echo "----------------------------------------"

echo "=== ТЕСТ-КЕЙС 2: Порог N превышен ==="
# Установка низкого порога 0.1%, чтобы гарантированно запустить архивацию
# Архивация пяти (M=5) самых старых файлов
./OneLabWork.sh "$TEST_LOG_DIR" 0.1 5
STATUS=$?

echo "Статус выполнения Тест-кейса 2: $STATUS"
echo "Проверка содержимого тестовой папки после архивации:"
ls -la "$TEST_LOG_DIR"

echo "Проверка наличия архива в /backup:"
ls -la /backup 2>/dev/null

# Очистка за собой (закомментирована)
# rm -rf "$TEST_LOG_DIR"
