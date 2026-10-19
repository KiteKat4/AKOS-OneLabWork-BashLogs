#!/bin/bash

# Проверка, что переданы все 3 обязательных аргумента
if [ "$#" -ne 3 ]; then
    echo "Использование: $0 <путь_к_папке> <порог_N_%> <кол_во_файлов_M>"
    exit 1
fi

TARGET_DIR="$1"
THRESHOLD_N="$2"
FILE_COUNT_M="$3"

# Проверка существования директории
if [ ! -d "$TARGET_DIR" ]; then
    echo "Ошибка: Директория $TARGET_DIR не существует."
    exit 1
fi

# Измерение размера папки (в КБ) и вычисление её доли от общего объема диска (в %)
DIR_SIZE_KB=$(du -s "$TARGET_DIR" | awk '{print $1}')

# Получение общего объема диска (раздела), где находится папка (в КБ)
TOTAL_DISK_KB=$(df "$TARGET_DIR" | tail -1 | awk '{print $2}')

# Вычисление процента 
PERCENTAGE=$(awk -v dir="$DIR_SIZE_KB" -v total="$TOTAL_DISK_KB" 'BEGIN {printf "%.2f", (dir/total)*100}')

echo "Папка: $TARGET_DIR"
echo "Занимает места на диске: $PERCENTAGE%"
echo "Заданный порог: $THRESHOLD_N%"

# Проверка превышения порога N%
IS_EXCEEDED=$(awk -v p="$PERCENTAGE" -v t="$THRESHOLD_N" 'BEGIN {print (p > t) ? 1 : 0}')

if [ "$IS_EXCEEDED" -eq 1 ]; then
    echo "Порог превышен! Начинаем архивацию $FILE_COUNT_M старых файлов..."

    # Создание папки /backup, если её еще нет (могут потребоваться права sudo)
    BACKUP_DIR="/backup"
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "Создаем директорию $BACKUP_DIR..."
        sudo mkdir -p "$BACKUP_DIR" 2>/dev/null || mkdir -p "./backup_local"
        # Если нет прав на корень /, сохраняем локально в ./backup_local для теста
        if [ -d "$BACKUP_DIR" ]; then
            ACTUAL_BACKUP="$BACKUP_DIR"
        else
            ACTUAL_BACKUP="./backup_local"
            echo "Предупреждение: Нет прав на /backup, сохраняем в $ACTUAL_BACKUP"
        fi
    else
        ACTUAL_BACKUP="$BACKUP_DIR"
    fi

    # Фильтрация и поиск M самых старых регулярных файлов
    OLD_FILES=$(find "$TARGET_DIR" -maxdepth 1 -type f -printf '%T@ %p\n' | sort -n | head -n "$FILE_COUNT_M" | cut -d' ' -f2-)

    if [ -z "$OLD_FILES" ]; then
        echo "В папке нет файлов для архивации."
        exit 0
    fi

    # Формирование имени архива с временной меткой
    ARCHIVE_NAME="$ACTUAL_BACKUP/log_archive_$(date +%Y%m%d_%H%M%S).tar.gz"

    # Превращаем список строк в аргументы для tar (Архивация выбранных файлов)
    echo "$OLD_FILES" | tar -czf "$ARCHIVE_NAME" -T - 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "Успешно заархивировано в: $ARCHIVE_NAME"
        echo "Список заархивированных файлов:"
        echo "$OLD_FILES"
    else
        echo "Ошибка при создании архива."
        exit 1
    fi
else
    echo "Объем папки в пределах нормы. Архивация не требуется."
fi
