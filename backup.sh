#!/bin/bash

# ------ Configurations ------
CONTAINER_NAME="postgres_db"
DB_NAME="internship_db"
DB_USER="internship_db_user"
BACKUP_DIR="/root/backup/list"
LOG_DIR="/root/backup/logs"

# Log va backup nomlari uchun hozirgi vaqt
DATE=$(date +'%Y-%m-%d_%H-%M-%S')
LOG_DATE=$(date +'%Y-%m-%d')   # Har kuni alohida log yozish uchun
LOG_FILE="${LOG_DIR}/backup_${LOG_DATE}.log"
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql"

# ------ Log yozish funksiyasi ------
log() {
    # Har bir xabarga joriy vaqtni yozib boramiz
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

# ------ Papkalarni yaratish ------
mkdir -p "${BACKUP_DIR}"
mkdir -p "${LOG_DIR}"

log "------------------------------------------"
log "Backup jarayoni boshlandi."

# ------ Backup olish ------
docker exec "${CONTAINER_NAME}" pg_dump -U "${DB_USER}" "${DB_NAME}" > "${BACKUP_FILE}" 2>"${LOG_DIR}"/error/backup_error.log
if [ $? -eq 0 ]; then
    if [ -s "${BACKUP_FILE}" ]; then
        log "Backup muvaffaqiyatli yakunlandi: ${BACKUP_FILE}"
    else
        log "Backup fayli bo'sh. Xatolik yuz bergan bo'lishi mumkin."
        cat "${LOG_DIR}"/error/backup_error.log | tee -a "${LOG_FILE}"
        exit 1
    fi
else
    log "Backupda xatolik yuz berdi!"
    cat "${LOG_DIR}"/error/backup_error.log | tee -a "${LOG_FILE}"
    exit 1
fi

# ------ Eski backup fayllarini o'chirish ------
log "Eski backuplarni o'chirish jarayoni boshlandi."
log "Oxirgi 2 ta backupni qoldirish va eski fayllarni o'chirish jarayoni boshlandi."

cd "${BACKUP_DIR}" || { log "Katalogga o'tishda xatolik yuz berdi!"; exit 1; }

# Fayl nomlari bo'yicha teskari tartibda (yangi -> eski) saralash
ls -1 "${DB_NAME}"_*.sql 2>/dev/null | sort -r | sed -n '3,$p' | xargs -r rm -f

log "Keraksiz eski backup fayllar o'chirildi."