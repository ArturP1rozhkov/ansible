#!/bin/bash

set -e

PLAYBOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
INVENTORY="${PLAYBOOK_DIR}/inventory/prod.yml"
PLAYBOOK="${PLAYBOOK_DIR}/site.yml"

echo "======================================="
echo " Запуск: поднимаем контейнеры..."
echo "======================================="
docker compose -f "${PLAYBOOK_DIR}/docker-compose.yml" up -d

echo ""
echo "Ждём 5 секунд пока контейнеры поднимутся..."
sleep 5

echo ""
echo "======================================="
echo " Статус контейнеров:"
echo "======================================="
docker ps

echo ""
echo "======================================="
echo " Запускаем ansible-playbook..."
echo "======================================="
ansible-playbook -i "${INVENTORY}" "${PLAYBOOK}" --ask-vault-pass

echo ""
echo "======================================="
echo " Останавливаем контейнеры..."
echo "======================================="
docker compose -f "${PLAYBOOK_DIR}/docker-compose.yml" down

echo ""
echo "======================================="
echo " Готово!"
echo "======================================="
