# Правила безопасности

## Секреты
- Все пароли, ключи API, токены — ТОЛЬКО в `.env`
- `.env` в `.gitignore` — НИКОГДА не коммитить
- `config.inc.php` в `.gitignore`
- Пример `.env.example` с пустыми значениями — в репозитории

## Пароли
- Минимум 16 символов для сервисных аккаунтов
- Минимум 8 символов для пользователей (требование ТЗ)
- Хранение: bcrypt (OJS по умолчанию)
- Уникальные пароли для: MySQL root, MySQL ojs user, OJS admin, SSH

## Веб-безопасность
- HTTPS обязателен (SSL через Let's Encrypt)
- HTTP → HTTPS redirect (301)
- Заголовки безопасности в Nginx:
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: SAMEORIGIN`
  - `X-XSS-Protection: 1; mode=block`
  - `Strict-Transport-Security: max-age=31536000`
- Запретить доступ к: `config.inc.php`, `.env`, `.git/`, `*.sql`
- SQL-инъекции: использовать ТОЛЬКО OJS DAO (prepared statements)
- XSS: экранирование через Smarty `{$var|escape}`
- CSRF: OJS встроенная защита — не отключать

## Docker
- Сервисы MySQL и PHP-FPM — ТОЛЬКО internal network
- Наружу выставлен ТОЛЬКО Nginx (80, 443)
- Не запускать контейнеры от root где возможно
- Регулярно обновлять образы (security patches)

## Доступ к серверу
- SSH только по ключам, root login отключен
- Firewall (ufw): разрешить только 22, 80, 443
- Fail2ban для защиты от brute-force

## Бэкапы
- Ежедневно в 03:00
- Хранение 30 дней
- Тест восстановления — минимум раз в месяц
- Бэкапы НЕ на том же диске что production
