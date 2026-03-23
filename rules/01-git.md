# Правила работы с Git

## Ветки
```
main            — production-ready код, только через PR
develop         — интеграционная ветка
feature/*       — новые функции (feature/theme-header, feature/doi-plugin)
fix/*           — исправления (fix/search-encoding)
docs/*          — документация (docs/user-manual)
locale/*        — переводы (locale/kk-interface)
```

## Коммиты
Формат: `<тип>(<область>): <описание>`

Типы:
- `feat` — новая функция
- `fix` — исправление бага
- `style` — верстка/CSS без логики
- `refactor` — рефакторинг
- `docs` — документация
- `test` — тесты
- `chore` — настройка, конфиги, Docker
- `locale` — переводы

Примеры:
```
feat(theme): добавить шапку с логотипом и меню
fix(search): исправить кодировку кириллицы в результатах
style(archive): адаптив страницы архива для мобильных
chore(docker): добавить volume для файлов OJS
locale(kk): перевести интерфейс подачи статьи
docs(api): описать интеграцию с CrossRef
```

## Правила
- Коммиты на русском или английском (описание)
- Один коммит = одно логическое изменение
- Не коммитить: `.env`, `config.inc.php`, пароли, ключи API
- PR из feature/* → develop, из develop → main
- Перед PR — проверить что нет конфликтов с develop

## .gitignore
```
.env
config.inc.php
docker/volumes/
*.sql.gz
node_modules/
vendor/
```
