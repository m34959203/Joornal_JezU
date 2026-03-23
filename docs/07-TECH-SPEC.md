# Техническая спецификация

**Проект:** JRNL-2026 | **Версия:** 1.0 | **Дата:** 2026-03-23

---

## 1. Архитектура системы

### 1.1 Компоненты

```
┌─────────────────────────────────────────────────────────────┐
│                        Интернет                              │
│                           │                                  │
│                     ┌─────▼─────┐                            │
│                     │   Nginx   │  SSL (Let's Encrypt)       │
│                     │  :443/:80 │  gzip, static cache        │
│                     └─────┬─────┘                            │
│                           │                                  │
│              ┌────────────▼────────────┐                     │
│              │     OJS 3.4.x           │                     │
│              │     PHP 8.1 (FPM)       │                     │
│              │     Smarty Templates    │                     │
│              │     :9000 (internal)    │                     │
│              └────────┬───────┬────────┘                     │
│                       │       │                              │
│              ┌────────▼──┐  ┌─▼──────────┐                   │
│              │ MySQL 8.0 │  │  Volumes   │                   │
│              │   :3306   │  │ - files/   │                   │
│              │ (internal)│  │ - public/  │                   │
│              └───────────┘  │ - config/  │                   │
│                             └────────────┘                   │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐               │
│  │  Cron    │  │  SMTP    │  │   Backups    │               │
│  │ (OJS     │  │ (внешний │  │  (ежедневно) │               │
│  │  tasks)  │  │  сервер) │  │              │               │
│  └──────────┘  └──────────┘  └──────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Технологический стек

| Компонент | Технология | Версия |
|-----------|-----------|--------|
| CMS/Платформа | Open Journal Systems | 3.4.x (latest stable) |
| Язык сервера | PHP | 8.1+ |
| База данных | MySQL | 8.0 |
| Веб-сервер | Nginx | latest |
| Шаблонизатор | Smarty | 3.x (встроен в OJS) |
| Контейнеризация | Docker + Docker Compose | 24.x / 2.x |
| SSL | Let's Encrypt (certbot) | — |
| ОС сервера | Ubuntu | 22.04/24.04 LTS |

### 1.3 Минимальные требования к серверу

| Параметр | Минимум | Рекомендуется |
|----------|---------|---------------|
| CPU | 2 ядра | 4 ядра |
| RAM | 2 GB | 4 GB |
| Диск | 20 GB SSD | 50 GB SSD |
| ОС | Ubuntu 22.04 LTS | Ubuntu 24.04 LTS |
| Сеть | 100 Mbit/s | 1 Gbit/s |

---

## 2. Структура Docker Compose

```yaml
# docker-compose.yml (схематично)
version: "3.8"

services:
  ojs:
    image: pkp/ojs:3_4_0  # или custom build
    volumes:
      - ojs_files:/var/www/files
      - ojs_public:/var/www/html/public
      - ojs_config:/var/www/html/config
      - ./theme:/var/www/html/plugins/themes/zhezujournal
    environment:
      - OJS_DB_HOST=db
      - OJS_DB_NAME=ojs
      - OJS_DB_USER=${DB_USER}
      - OJS_DB_PASSWORD=${DB_PASSWORD}
    depends_on:
      - db

  db:
    image: mysql:8.0
    volumes:
      - db_data:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      - MYSQL_DATABASE=ojs
      - MYSQL_USER=${DB_USER}
      - MYSQL_PASSWORD=${DB_PASSWORD}

  nginx:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./certbot:/etc/letsencrypt
      - ojs_public:/var/www/html/public:ro
    depends_on:
      - ojs

volumes:
  ojs_files:
  ojs_public:
  ojs_config:
  db_data:
```

---

## 3. Структура Child Theme

```
plugins/themes/zhezujournal/
├── ZhezuJournalThemePlugin.php    # Основной класс плагина
├── version.xml                     # Версия и метаданные
├── locale/
│   ├── ru_RU/locale.po            # Русская локаль
│   ├── kk/locale.po               # Казахская локаль
│   └── en_US/locale.po            # Английская локаль
├── styles/
│   ├── variables.less             # Цвета, шрифты
│   ├── header.less                # Шапка
│   ├── footer.less                # Подвал
│   ├── homepage.less              # Главная страница
│   ├── archive.less               # Архив
│   ├── article.less               # Страница статьи
│   ├── editorial-board.less       # Редколлегия
│   ├── search.less                # Поиск
│   └── responsive.less            # Адаптивность
├── templates/
│   ├── frontend/
│   │   ├── components/
│   │   │   ├── header.tpl         # Шапка (логотип, меню, поиск, языки)
│   │   │   ├── footer.tpl         # Подвал
│   │   │   ├── breadcrumbs.tpl    # Хлебные крошки
│   │   │   └── languageSwitcher.tpl
│   │   └── pages/
│   │       ├── indexJournal.tpl    # Главная (текущий номер)
│   │       ├── issue.tpl          # Страница выпуска
│   │       ├── article.tpl        # Страница статьи
│   │       ├── search.tpl         # Результаты поиска
│   │       └── editorialBoard.tpl # Редколлегия
│   └── frontend/objects/
│       ├── article_summary.tpl    # Карточка статьи в списке
│       └── issue_summary.tpl      # Карточка выпуска в архиве
└── assets/
    ├── images/
    │   ├── logo.svg               # Логотип ЖезУ
    │   ├── favicon.ico
    │   └── icons/                 # Иконки Scopus, WoS, ORCID
    ├── js/
    │   └── zhezujournal.js        # Кастомный JS (меню, поиск)
    └── fonts/                     # Веб-шрифты (если нужны)
```

---

## 4. Конфигурация Nginx

```nginx
server {
    listen 443 ssl http2;
    server_name journal.zhezu.edu.kz;

    ssl_certificate     /etc/letsencrypt/live/journal.zhezu.edu.kz/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/journal.zhezu.edu.kz/privkey.pem;

    root /var/www/html;
    index index.php;

    # Статические файлы — кеш 30 дней
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff2?)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # PDF — без ограничения размера
    location ~* \.pdf$ {
        expires 7d;
        client_max_body_size 50M;
    }

    # PHP → OJS (FPM)
    location ~ \.php$ {
        fastcgi_pass ojs:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # OJS URL rewriting
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # Безопасность
    location ~ /\. { deny all; }
    location ~* /config\.inc\.php$ { deny all; }

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml;
}

server {
    listen 80;
    server_name journal.zhezu.edu.kz;
    return 301 https://$host$request_uri;
}
```

---

## 5. Резервное копирование

### Скрипт (cron, ежедневно в 03:00)

```bash
#!/bin/bash
# backup-ojs.sh
BACKUP_DIR="/backups/ojs/$(date +%Y-%m-%d)"
mkdir -p "$BACKUP_DIR"

# Дамп БД
docker exec ojs-db mysqldump -u root -p"${DB_ROOT_PASSWORD}" ojs \
  | gzip > "$BACKUP_DIR/ojs-db.sql.gz"

# Файлы (загруженные рукописи, PDF)
docker cp ojs-app:/var/www/files "$BACKUP_DIR/files"

# Конфигурация
docker cp ojs-app:/var/www/html/config.inc.php "$BACKUP_DIR/"

# Тема
cp -r ./theme "$BACKUP_DIR/theme"

# Ротация (хранить 30 дней)
find /backups/ojs/ -maxdepth 1 -mtime +30 -exec rm -rf {} \;

echo "[$(date)] Backup completed: $BACKUP_DIR" >> /var/log/ojs-backup.log
```

---

## 6. Безопасность

| Мера | Реализация |
|------|-----------|
| HTTPS | SSL через Let's Encrypt, автообновление certbot |
| Пароли | Минимум 8 символов, буквы + цифры, хранение bcrypt (OJS) |
| SQL-инъекции | OJS использует prepared statements (DAO layer) |
| XSS | Smarty auto-escaping + OJS sanitization |
| Доступ к конфигам | Nginx deny для config.inc.php и .* файлов |
| SSH | Только по ключам, отключен root login |
| Docker | Сервисы в internal network, только nginx на 80/443 |
| Секреты | .env файл, .gitignore, не в репозитории |
| Обновления | Мониторинг CVE для OJS, PHP, MySQL, Nginx |
| Бэкапы | Ежедневно, 30 дней ротация, тест восстановления |

---

## 7. Мониторинг

| Что мониторим | Как | Порог алерта |
|---------------|-----|-------------|
| Доступность сайта (HTTP 200) | Cron curl каждые 5 мин | Нет ответа 3 мин |
| SSL-сертификат | certbot --renew | До истечения 14 дней |
| Место на диске | df | >85% |
| Бэкапы | Проверка наличия файла | Нет бэкапа за сегодня |
| Ошибки OJS | /var/log/ojs/error.log | Любая FATAL ошибка |

---

## 8. Структура URL

| Страница | URL |
|----------|-----|
| Главная | `/` |
| О журнале | `/about` |
| Цели и задачи | `/about#aims` |
| Редакционная политика | `/about/editorialPolicy` |
| Редколлегия | `/about/editorialTeam` |
| Публикационная этика | `/about/ethics` |
| Для авторов | `/about/submissions` |
| Рецензирование | `/about/reviewPolicy` |
| Архив | `/issue/archive` |
| Выпуск (номер) | `/issue/view/{id}` |
| Статья | `/article/view/{id}` |
| Контакты | `/about/contact` |
| Поиск | `/search` |
| Вход | `/login` |
| Регистрация | `/user/register` |
| Подача статьи | `/submission/wizard` |
| Личный кабинет | `/dashboard` |
