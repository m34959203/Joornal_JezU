# Инструкция для администратора

## Для кого

Системный администратор (IT-служба), отвечающий за техническую эксплуатацию сайта журнала «Вестник ЖезУ» на базе OJS 3.4.x.

## Предварительные условия

- SSH-доступ к серверу.
- Docker и Docker Compose установлены.
- Проект развернут в директории `/home/ubuntu/Joornal_JezU/`.
- Файл `.env` настроен в `/home/ubuntu/Joornal_JezU/docker/`.

---

## Пошаговая инструкция

### Шаг 1: Запуск и остановка Docker-контейнеров

Все сервисы (OJS, MySQL, Nginx) работают в Docker-контейнерах. Управление осуществляется из директории `docker/`.

**Запуск всех сервисов:**

```bash
cd /home/ubuntu/Joornal_JezU/docker
docker compose up -d
```

**Остановка всех сервисов:**

```bash
cd /home/ubuntu/Joornal_JezU/docker
docker compose down
```

**Перезапуск отдельного сервиса:**

```bash
docker compose restart ojs     # PHP-FPM (OJS)
docker compose restart db      # MySQL
docker compose restart nginx   # Nginx
```

**Просмотр статуса контейнеров:**

```bash
docker compose ps
```

**Ожидаемый результат:**

| Контейнер | Порт | Статус |
|-----------|------|--------|
| ojs-app | (internal) | healthy |
| ojs-db | (internal) | healthy |
| ojs-nginx | 80, 443 | healthy |

> **Примечание**: Контейнеры `ojs-app` и `ojs-db` работают во внутренней сети Docker и не доступны напрямую снаружи. Весь внешний трафик проходит через Nginx.

---

### Шаг 2: Резервное копирование

Скрипт `backup.sh` создает полную резервную копию: базы данных MySQL, файлов OJS и конфигурации.

**Запуск вручную:**

```bash
cd /home/ubuntu/Joornal_JezU/docker
./scripts/backup.sh
```

**Запуск с указанием директории и срока хранения:**

```bash
./scripts/backup.sh /opt/backups/ojs 30
```

Параметры:
- Первый аргумент — директория для бэкапов (по умолчанию: `/opt/backups/ojs`).
- Второй аргумент — количество дней хранения (по умолчанию: 30).

**Что сохраняется:**

| Файл | Содержание |
|------|-----------|
| `database.sql.gz` | Дамп базы MySQL |
| `private_files.tar.gz` | Загруженные рукописи, рецензии |
| `public_files.tar.gz` | Публичные файлы (PDF статей, обложки) |
| `config.inc.php` | Конфигурация OJS |
| `docker-compose.yml` | Конфигурация Docker |
| `env.backup` | Переменные окружения |
| `checksums.sha256` | Контрольные суммы файлов |

**Автоматическое резервное копирование (cron):**

```bash
crontab -e
```

Добавьте строку:

```
0 3 * * * /home/ubuntu/Joornal_JezU/docker/scripts/backup.sh >> /var/log/ojs-backup.log 2>&1
```

Бэкап будет выполняться ежедневно в 03:00.

> **Примечание**: Регулярно проверяйте, что бэкапы создаются успешно. Команда для проверки:
> ```bash
> ls -lh /opt/backups/ojs/
> ```

---

### Шаг 3: Восстановление из бэкапа

**Запуск:**

```bash
cd /home/ubuntu/Joornal_JezU/docker
./scripts/restore.sh /opt/backups/ojs/20260323_030000
```

**Порядок действий скрипта:**

1. Проверяет наличие файлов бэкапа и контрольные суммы.
2. Запрашивает подтверждение (данные будут перезаписаны).
3. Восстанавливает базу данных MySQL из дампа.
4. Восстанавливает приватные файлы OJS.
5. Восстанавливает публичные файлы.
6. Восстанавливает `config.inc.php`.
7. Исправляет права доступа (`www-data`).

**После восстановления перезапустите OJS:**

```bash
docker compose restart ojs
```

**Просмотр списка доступных бэкапов:**

```bash
./scripts/restore.sh
```

(Запуск без аргументов покажет список бэкапов с их размерами.)

> **Примечание**: Перед восстановлением обязательно создайте бэкап текущего состояния. Восстановление необратимо — все текущие данные будут перезаписаны.

---

### Шаг 4: Обновление OJS

1. **Создайте бэкап** перед обновлением:

   ```bash
   ./scripts/backup.sh /opt/backups/ojs-pre-update
   ```

2. **Остановите контейнеры:**

   ```bash
   docker compose down
   ```

3. **Обновите образ OJS** в `docker-compose.yml`:

   ```yaml
   # Было:
   image: pkpofficial/ojs:3_4_0-8
   # Стало (пример):
   image: pkpofficial/ojs:3_4_0-9
   ```

4. **Загрузите новый образ:**

   ```bash
   docker compose pull ojs
   ```

5. **Запустите контейнеры:**

   ```bash
   docker compose up -d
   ```

6. **Выполните миграцию базы данных** (если требуется):

   ```bash
   docker exec ojs-app php /var/www/html/tools/upgrade.php upgrade
   ```

7. **Проверьте работоспособность:**

   ```bash
   /home/ubuntu/Joornal_JezU/scripts/check-health.sh https://<домен_журнала>
   ```

8. **Очистите кэш OJS:**

   ```bash
   docker exec ojs-app rm -rf /var/www/html/cache/t_cache/*
   docker exec ojs-app rm -rf /var/www/html/cache/t_compile/*
   ```

> **Примечание**: Всегда читайте Release Notes перед обновлением. Некоторые версии требуют ручного вмешательства. Документация OJS: https://docs.pkp.sfu.ca/dev/upgrade-guide/

---

### Шаг 5: Управление плагинами

**Установка плагина через веб-интерфейс:**

1. Войдите в OJS как администратор.
2. Перейдите: **Настройки** > **Веб-сайт** > **Плагины** > **Галерея плагинов** (Plugin Gallery).
3. Найдите нужный плагин.
4. Нажмите **Установить** (Install).
5. После установки нажмите **Включить** (Enable).

**Установка плагина вручную (через Docker):**

```bash
# Скопировать плагин в контейнер
docker cp ./plugins/generic/myPlugin ojs-app:/var/www/html/plugins/generic/

# Исправить права
docker exec ojs-app chown -R www-data:www-data /var/www/html/plugins/generic/myPlugin

# Обновить базу плагинов
docker exec ojs-app php /var/www/html/tools/upgrade.php upgrade
```

**Удаление плагина:**

```bash
docker exec ojs-app rm -rf /var/www/html/plugins/generic/myPlugin
```

> **Примечание**: Не удаляйте системные плагины OJS. Удаление плагинов вроде `defaultThemePlugin` или `nativeImportExportPlugin` приведет к неработоспособности системы.

---

### Шаг 6: Управление пользователями и ролями

**Через веб-интерфейс OJS (рекомендуется):**

1. Войдите как администратор.
2. Перейдите: **Пользователи и роли** (Users & Roles) > **Пользователи** (Users).
3. Доступные действия:
   - **Добавить пользователя** — создание нового аккаунта.
   - **Редактировать** — изменение данных пользователя.
   - **Отключить** — временная блокировка доступа.
   - **Удалить** — полное удаление аккаунта.
   - **Объединить** — слияние дублирующих аккаунтов.
4. Для управления ролями перейдите на вкладку **Роли** (Roles).

**Роли в OJS:**

| Роль | Описание |
|------|----------|
| Администратор сайта | Полный доступ ко всей системе |
| Менеджер журнала | Управление настройками журнала |
| Главный редактор | Управление подачами, назначение рецензентов |
| Редактор раздела | Управление подачами в своем разделе |
| Рецензент | Оценка рукописей |
| Автор | Подача статей |
| Читатель | Доступ к опубликованным материалам |

**Сброс пароля пользователя через CLI:**

```bash
docker exec -it ojs-app php /var/www/html/tools/mergeUsers.php
```

Или попросите пользователя воспользоваться формой «Забыли пароль?» на сайте.

---

### Шаг 7: Настройка SMTP

Настройки email хранятся в файле `config.inc.php` (генерируется из шаблона `docker/config.inc.php.template`).

**Через .env файл:**

```bash
nano /home/ubuntu/Joornal_JezU/docker/.env
```

Настройте параметры:

```env
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_AUTH=ssl
SMTP_USER=journal@example.com
SMTP_PASSWORD=your_password_here
SMTP_ENCRYPTION=tls
SMTP_FROM=journal@example.com
```

**Применение изменений:**

```bash
# Перегенерировать config.inc.php
/home/ubuntu/Joornal_JezU/scripts/setup-ojs.sh

# Перезапустить OJS
cd /home/ubuntu/Joornal_JezU/docker
docker compose restart ojs
```

**Проверка отправки email:**

1. Войдите в OJS как администратор.
2. Попробуйте сбросить пароль тестового пользователя.
3. Проверьте получение письма.

> **Примечание**: Для Gmail используйте пароль приложения (App Password), а не основной пароль аккаунта. Для Яндекса — аналогично.

---

### Шаг 8: Мониторинг (check-health.sh)

Скрипт проверяет состояние всех компонентов системы.

**Запуск:**

```bash
/home/ubuntu/Joornal_JezU/scripts/check-health.sh https://<домен_журнала>
```

**Полный формат:**

```bash
./scripts/check-health.sh <BASE_URL> <MYSQL_HOST> <MYSQL_USER> <MYSQL_PASS> <MYSQL_DB>
```

**Что проверяется:**

| Проверка | Критерий |
|----------|----------|
| HTTP-доступность OJS | HTTP 200 |
| MySQL-подключение | mysqladmin ping |
| Дисковое пространство | < 90% |
| SSL-сертификат | Срок действия > 14 дней |

**Автоматический мониторинг (cron):**

```bash
crontab -e
```

Добавьте:

```
*/15 * * * * /home/ubuntu/Joornal_JezU/scripts/check-health.sh https://<домен_журнала> >> /var/log/ojs-health.log 2>&1
```

Проверка каждые 15 минут.

---

### Шаг 9: Обновление SSL-сертификата

SSL-сертификат от Let's Encrypt обновляется автоматически скриптом `ssl-renew.sh`.

**Ручное обновление:**

```bash
/home/ubuntu/Joornal_JezU/scripts/ssl-renew.sh
```

**Автоматическое обновление (cron):**

```bash
crontab -e
```

Добавьте:

```
0 4 * * * /home/ubuntu/Joornal_JezU/scripts/ssl-renew.sh >> /var/log/ssl-renew.log 2>&1
```

**Порядок работы скрипта:**

1. Запускает `certbot renew`.
2. Если сертификат обновлен — перезагружает Nginx (`nginx -s reload`).
3. Если обновление не требуется — завершается без действий.

**Проверка текущего сертификата:**

```bash
echo | openssl s_client -servername <домен_журнала> -connect <домен_журнала>:443 2>/dev/null | openssl x509 -noout -dates
```

> **Примечание**: Let's Encrypt сертификаты действуют 90 дней. Автообновление запускается, когда до истечения остается менее 30 дней.

---

### Шаг 10: Просмотр логов

**Логи Nginx:**

```bash
docker logs ojs-nginx --tail 100
docker logs ojs-nginx --tail 100 -f    # В реальном времени
```

Или через Docker volumes:

```bash
docker exec ojs-nginx cat /var/log/nginx/access.log | tail -50
docker exec ojs-nginx cat /var/log/nginx/error.log | tail -50
```

**Логи OJS (PHP):**

```bash
docker logs ojs-app --tail 100
```

Или через volume:

```bash
docker exec ojs-app cat /var/log/ojs/ojs.log 2>/dev/null | tail -50
```

**Логи MySQL:**

```bash
docker logs ojs-db --tail 100
```

Медленные запросы:

```bash
docker exec ojs-db cat /var/log/mysql/slow.log | tail -50
```

**Логи Docker Compose (все сервисы):**

```bash
cd /home/ubuntu/Joornal_JezU/docker
docker compose logs --tail 100
docker compose logs --tail 100 -f    # В реальном времени
```

**Логи бэкапов и мониторинга:**

```bash
tail -50 /var/log/ojs-backup.log
tail -50 /var/log/ojs-health.log
tail -50 /var/log/ssl-renew.log
```

> **Примечание**: Для анализа проблем производительности обращайте внимание на slow query log MySQL (запросы дольше 2 секунд) и error.log Nginx.

---

## Частые вопросы (FAQ)

**В: Контейнер ojs-app не запускается (unhealthy).**
О: Проверьте логи: `docker logs ojs-app`. Частые причины: ошибка в `config.inc.php`, база данных недоступна, нехватка дискового пространства.

**В: Сайт работает, но медленно.**
О: Проверьте дисковое пространство (`df -h`), память (`free -h`), загрузку процессора (`top`). Проверьте slow query log MySQL. Очистите кэш OJS: `docker exec ojs-app rm -rf /var/www/html/cache/t_cache/* /var/www/html/cache/t_compile/*`.

**В: Как перенести сайт на другой сервер?**
О: Создайте бэкап (`backup.sh`), разверните OJS на новом сервере (см. `manual-deploy.md`), восстановите из бэкапа (`restore.sh`).

**В: Email-уведомления не отправляются.**
О: Проверьте настройки SMTP в `.env`. Убедитесь, что порт 587 (или 465) не заблокирован файрволом. Проверьте логи OJS на ошибки отправки.

---

## Контакты поддержки

- **Техническая поддержка**: support@zhezuni.edu.kz
- **Телефон**: +7 (7102) XX-XX-XX (IT-служба ЖезУ)
