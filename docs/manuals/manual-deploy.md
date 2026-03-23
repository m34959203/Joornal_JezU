# Инструкция по развертыванию с нуля

## Для кого

IT-специалисты, выполняющие первоначальное развертывание сайта журнала «Вестник ЖезУ» на базе OJS 3.4.x.

## Предварительные условия

- Сервер с ОС **Ubuntu 22.04 / 24.04 LTS** (или аналогичный Linux-дистрибутив).
- SSH-доступ с правами `sudo`.
- Доменное имя, направленное на IP-адрес сервера (A-запись в DNS).
- Открытые порты: **80** (HTTP), **443** (HTTPS), **22** (SSH).

---

## Пошаговая инструкция

### Шаг 1: Требования к серверу

**Минимальные требования:**

| Параметр | Значение |
|----------|----------|
| CPU | 2 ядра |
| RAM | 4 ГБ |
| Диск | 40 ГБ SSD |
| ОС | Ubuntu 22.04 / 24.04 LTS |
| Сеть | Публичный IP, домен |

**Рекомендуемые требования:**

| Параметр | Значение |
|----------|----------|
| CPU | 4 ядра |
| RAM | 8 ГБ |
| Диск | 100 ГБ SSD |
| ОС | Ubuntu 24.04 LTS |

> **Примечание**: Объем диска зависит от количества статей. Каждая статья (PDF + исходники) занимает в среднем 5-20 МБ. Планируйте с запасом.

---

### Шаг 2: Установка Docker и Docker Compose

1. Обновите систему:

   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. Установите зависимости:

   ```bash
   sudo apt install -y ca-certificates curl gnupg lsb-release
   ```

3. Добавьте репозиторий Docker:

   ```bash
   sudo install -m 0755 -d /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   sudo chmod a+r /etc/apt/keyrings/docker.gpg

   echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
     https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
     sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   ```

4. Установите Docker:

   ```bash
   sudo apt update
   sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
   ```

5. Добавьте текущего пользователя в группу `docker`:

   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```

6. Проверьте установку:

   ```bash
   docker --version
   docker compose version
   ```

> **Примечание**: Если вы используете другой дистрибутив Linux, обратитесь к официальной документации Docker: https://docs.docker.com/engine/install/

---

### Шаг 3: Клонирование репозитория

```bash
cd /home/ubuntu
git clone https://github.com/<организация>/Joornal_JezU.git
cd Joornal_JezU
```

> **Примечание**: Если репозиторий приватный, используйте SSH-ключ или персональный токен доступа.

---

### Шаг 4: Настройка .env

1. Скопируйте шаблон:

   ```bash
   cp docker/.env.example docker/.env
   ```

2. Отредактируйте файл:

   ```bash
   nano docker/.env
   ```

3. Заполните все параметры:

   ```env
   # --- База данных ---
   DB_ROOT_PASSWORD=<надежный_пароль_root>
   DB_NAME=ojs
   DB_USER=ojs
   DB_PASSWORD=<надежный_пароль_ojs>

   # --- OJS ---
   OJS_DOMAIN=journal.example.com
   OJS_BASE_URL=https://journal.example.com
   OJS_ADMIN_USER=admin
   OJS_ADMIN_PASSWORD=<надежный_пароль_admin>
   OJS_ADMIN_EMAIL=admin@example.com

   # --- Nginx ---
   NGINX_HTTP_PORT=80
   NGINX_HTTPS_PORT=443

   # --- SSL ---
   CERTBOT_EMAIL=admin@example.com

   # --- SMTP ---
   SMTP_HOST=smtp.example.com
   SMTP_PORT=587
   SMTP_AUTH=ssl
   SMTP_USER=journal@example.com
   SMTP_PASSWORD=<пароль_smtp>
   SMTP_ENCRYPTION=tls
   SMTP_FROM=journal@example.com

   # --- Безопасность ---
   API_KEY_SECRET=<случайная_строка_32_символа>
   OAI_REPOSITORY_ID=journal.example.com

   # --- Бэкапы ---
   BACKUP_DIR=/opt/backups/ojs
   BACKUP_RETENTION_DAYS=30

   # --- Часовой пояс ---
   TZ=Asia/Almaty
   ```

4. Сгенерируйте надежные пароли:

   ```bash
   openssl rand -base64 24    # Для DB_ROOT_PASSWORD
   openssl rand -base64 24    # Для DB_PASSWORD
   openssl rand -hex 16       # Для API_KEY_SECRET
   ```

> **Примечание**: Никогда не коммитьте файл `.env` в Git. Он уже добавлен в `.gitignore`. Храните копию паролей в надежном месте (менеджер паролей).

---

### Шаг 5: Запуск setup-ojs.sh

Скрипт выполняет первоначальную настройку: генерация `config.inc.php`, создание директорий, установка темы, плагинов и казахской локали.

```bash
chmod +x scripts/setup-ojs.sh
./scripts/setup-ojs.sh
```

**Что делает скрипт:**

1. Загружает переменные из `.env`.
2. Генерирует `config.inc.php` из шаблона с подстановкой переменных.
3. Создает необходимые директории с правами `www-data`.
4. Копирует тему `zhezujournal` в `plugins/themes/`.
5. Копирует кастомные плагины из `plugins/generic/`.
6. Копирует казахскую локаль из `locales/kk/`.

> **Примечание**: Скрипт предназначен для запуска на хосте перед первым `docker compose up`. Некоторые операции (копирование в `/var/www/html`) выполняются только внутри контейнера — они произойдут при монтировании Docker volumes.

---

### Шаг 6: Запуск контейнеров

```bash
cd /home/ubuntu/Joornal_JezU/docker
docker compose up -d
```

Дождитесь запуска всех контейнеров (1-2 минуты для первого раза):

```bash
docker compose ps
```

Убедитесь, что все контейнеры в статусе `healthy`:

```
NAME        SERVICE   STATUS                  PORTS
ojs-app     ojs       Up (healthy)
ojs-db      db        Up (healthy)
ojs-nginx   nginx     Up (healthy)            0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
```

Если контейнер в статусе `unhealthy`, проверьте логи:

```bash
docker logs ojs-app
docker logs ojs-db
```

---

### Шаг 7: Первоначальная настройка через веб-интерфейс

1. Откройте в браузере:

   ```
   https://<домен_журнала>/index.php/index/install
   ```

   Или (если SSL еще не настроен):

   ```
   http://<IP_сервера>/index.php/index/install
   ```

2. На странице установки проверьте и заполните:
   - **Основной язык** (Primary Locale): `Русский (ru_RU)`.
   - **Дополнительные языки**: `Қазақша (kk)`, `English (en_US)`.
   - **Имя администратора**: из `.env` (`OJS_ADMIN_USER`).
   - **Email администратора**: из `.env` (`OJS_ADMIN_EMAIL`).
   - **Пароль администратора**: из `.env` (`OJS_ADMIN_PASSWORD`).
   - **База данных**: параметры подставляются автоматически из `config.inc.php`.
3. Нажмите **Установить OJS** (Install OJS).
4. Дождитесь завершения установки.

5. Создайте журнал:
   - Войдите как администратор.
   - Перейдите: **Администрирование** > **Размещенные журналы** > **Создать журнал**.
   - Заполните:
     - **Название**: «Вестник ЖезУ» (на 3 языках).
     - **Путь** (Path): `vestnik`.
     - **Языки**: ru_RU (основной), kk, en_US.
   - Нажмите **Сохранить**.

---

### Шаг 8: Установка темы и плагинов

1. Войдите в OJS как администратор.
2. Перейдите: **Настройки** > **Веб-сайт** > **Внешний вид** > **Тема**.
3. Выберите **zhezujournal** и нажмите **Сохранить**.

4. Установите рекомендуемые плагины:
   - Перейдите: **Настройки** > **Веб-сайт** > **Плагины** > **Галерея плагинов**.
   - Установите и включите:
     - **DOI Plugin** — присвоение DOI статьям.
     - **Crossref Export Plugin** — регистрация DOI в Crossref.
     - **Google Scholar Plugin** — метатеги для Google Scholar.
     - **ORCID Profile Plugin** — интеграция с ORCID.
     - **Usage Statistics Plugin** — статистика просмотров.
     - **Backup Plugin** — дополнительное резервное копирование.

> **Примечание**: Если тема `zhezujournal` не отображается в списке, убедитесь, что скрипт `setup-ojs.sh` был выполнен успешно и файлы темы скопированы в контейнер.

---

### Шаг 9: Настройка SSL (Certbot)

1. Установите Certbot на хосте:

   ```bash
   sudo apt install -y certbot
   ```

2. Остановите Nginx для получения первого сертификата:

   ```bash
   cd /home/ubuntu/Joornal_JezU/docker
   docker compose stop nginx
   ```

3. Получите сертификат:

   ```bash
   sudo certbot certonly --standalone \
     -d journal.example.com \
     --email admin@example.com \
     --agree-tos \
     --non-interactive
   ```

4. Скопируйте сертификаты в Docker volume:

   ```bash
   # Узнайте путь к volume
   docker volume inspect docker_certbot_etc

   # Скопируйте сертификаты
   sudo cp -rL /etc/letsencrypt/* $(docker volume inspect docker_certbot_etc --format '{{.Mountpoint}}')/
   ```

5. Запустите Nginx:

   ```bash
   docker compose up -d nginx
   ```

6. Проверьте SSL:

   ```bash
   curl -I https://journal.example.com
   ```

> **Примечание**: Альтернативный способ — использование Certbot в режиме webroot через Nginx. В этом случае не нужно останавливать Nginx:
> ```bash
> sudo certbot certonly --webroot -w /var/www/certbot -d journal.example.com
> ```

---

### Шаг 10: Настройка cron-задач

Откройте crontab:

```bash
crontab -e
```

Добавьте следующие задачи:

```cron
# Резервное копирование — ежедневно в 03:00
0 3 * * * /home/ubuntu/Joornal_JezU/docker/scripts/backup.sh >> /var/log/ojs-backup.log 2>&1

# Обновление SSL — ежедневно в 04:00
0 4 * * * /home/ubuntu/Joornal_JezU/scripts/ssl-renew.sh >> /var/log/ssl-renew.log 2>&1

# Плановые задачи OJS (уведомления, индексация) — каждые 4 часа
0 */4 * * * docker exec ojs-app php /var/www/html/tools/runScheduledTasks.php >> /var/log/ojs-tasks.log 2>&1

# Мониторинг здоровья — каждые 15 минут
*/15 * * * * /home/ubuntu/Joornal_JezU/scripts/check-health.sh https://journal.example.com >> /var/log/ojs-health.log 2>&1
```

Проверьте, что задачи сохранены:

```bash
crontab -l
```

> **Примечание**: Замените `journal.example.com` на реальный домен журнала. Убедитесь, что все скрипты имеют права на выполнение:
> ```bash
> chmod +x /home/ubuntu/Joornal_JezU/scripts/*.sh
> chmod +x /home/ubuntu/Joornal_JezU/docker/scripts/*.sh
> ```

---

### Шаг 11: Проверка развертывания

**Проверка состояния системы (check-health.sh):**

```bash
/home/ubuntu/Joornal_JezU/scripts/check-health.sh https://journal.example.com
```

Ожидаемый результат:

```
[HTTP]  OJS at https://journal.example.com ... OK (HTTP 200)
[MySQL] Connection ... OK
[Disk]  Usage on / ... OK (25% used)
[SSL]   Certificate ... OK (expires in 89 days)
All checks passed.
```

**Аудит безопасности (security-audit.sh):**

```bash
/home/ubuntu/Joornal_JezU/scripts/security-audit.sh https://journal.example.com
```

Убедитесь, что нет FAIL-результатов. Исправьте все найденные проблемы перед передачей в эксплуатацию.

**Smoke-тест:**

```bash
/home/ubuntu/Joornal_JezU/tests/smoke/smoke-test.sh https://journal.example.com
```

---

### Шаг 12: Импорт контента

Если есть готовые статьи для загрузки (в формате OJS Native XML):

```bash
# Импорт из директории
docker exec ojs-app /home/ubuntu/Joornal_JezU/scripts/import-content.sh \
  --journal-path vestnik \
  --import-dir /path/to/content/ \
  --user admin

# Импорт одного файла
docker exec ojs-app /home/ubuntu/Joornal_JezU/scripts/import-content.sh \
  --journal-path vestnik \
  --file /path/to/article.xml

# Проверка XML без импорта (dry-run)
docker exec ojs-app /home/ubuntu/Joornal_JezU/scripts/import-content.sh \
  --journal-path vestnik \
  --import-dir /path/to/content/ \
  --dry-run
```

> **Примечание**: XML-файлы должны соответствовать формату OJS Native XML. Пример шаблона доступен в директории `content/`. После импорта автоматически запускается перестройка поискового индекса.

---

## Итоговый чек-лист

Перед передачей сайта в эксплуатацию убедитесь, что выполнены все пункты:

- [ ] Docker и Docker Compose установлены.
- [ ] Репозиторий клонирован.
- [ ] `.env` заполнен корректными значениями.
- [ ] `setup-ojs.sh` выполнен успешно.
- [ ] Контейнеры запущены (`docker compose ps` — все healthy).
- [ ] OJS установлен через веб-интерфейс.
- [ ] Журнал создан (path: `vestnik`).
- [ ] Тема `zhezujournal` активирована.
- [ ] Рекомендуемые плагины установлены.
- [ ] SSL-сертификат получен и работает.
- [ ] Cron-задачи настроены (бэкап, SSL, OJS tasks, мониторинг).
- [ ] `check-health.sh` возвращает «All checks passed».
- [ ] `security-audit.sh` не показывает FAIL.
- [ ] SMTP настроен и email-уведомления работают.
- [ ] Первый бэкап создан успешно.

---

## Частые вопросы (FAQ)

**В: OJS не открывается после `docker compose up -d`.**
О: Подождите 1-2 минуты (контейнер ojs-app ждет готовности MySQL). Проверьте `docker compose ps` и `docker logs ojs-app`.

**В: Certbot не может получить сертификат.**
О: Убедитесь, что домен указывает на IP сервера (проверьте: `dig journal.example.com`). Порты 80 и 443 должны быть открыты. Файрвол: `sudo ufw allow 80/tcp && sudo ufw allow 443/tcp`.

**В: Ошибка «Permission denied» при запуске скриптов.**
О: Добавьте права на выполнение: `chmod +x scripts/*.sh docker/scripts/*.sh`.

**В: База данных не создается.**
О: Проверьте логи MySQL: `docker logs ojs-db`. Убедитесь, что пароли в `.env` не содержат специальных символов, которые могут быть неправильно интерпретированы shell (например, `$`, `!`, `"`).

---

## Контакты поддержки

- **Техническая поддержка**: support@zhezuni.edu.kz
- **Телефон**: +7 (7102) XX-XX-XX (IT-служба ЖезУ)
