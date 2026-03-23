# Правила Docker

## Структура
```
docker/
├── docker-compose.yml          # Основной compose
├── docker-compose.dev.yml      # Override для разработки
├── .env.example                # Шаблон переменных
├── nginx/
│   ├── nginx.conf
│   └── conf.d/
│       └── ojs.conf
├── php/
│   └── php.ini                 # Кастомные настройки PHP
└── scripts/
    ├── backup.sh
    └── restore.sh
```

## Правила
- `docker-compose.yml` — production-конфигурация
- `docker-compose.dev.yml` — дополнительные настройки для разработки (порты, debug)
- Все переменные — через `.env` (НЕ хардкодить в compose)
- Volumes для персистентных данных (БД, файлы OJS, публичные файлы)
- Только Nginx выставлен наружу (80, 443)
- MySQL и PHP-FPM — internal network только

## Команды

```bash
# Production
docker compose up -d

# Разработка
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Логи
docker compose logs -f ojs
docker compose logs -f nginx

# Бэкап БД
docker exec ojs-db mysqldump -u root -p"${DB_ROOT_PASSWORD}" ojs | gzip > backup.sql.gz

# Зайти в контейнер OJS
docker exec -it ojs-app bash

# Обновить OJS
# 1. Сделать бэкап
# 2. Обновить образ в compose
# 3. docker compose pull ojs
# 4. docker compose up -d
# 5. Тестировать тему и плагины
```

## Мониторинг
- `docker compose ps` — статус контейнеров
- Healthcheck для каждого сервиса в compose
- Автоперезапуск: `restart: unless-stopped`
