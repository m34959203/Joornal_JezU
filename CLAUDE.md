# JRNL-2026 — Сайт научного журнала «Вестник ЖезУ»

## Проект
Разработка сайта научного журнала на Open Journal Systems (OJS) 3.4.x для Жезказганского университета им. О.А. Байконурова. Сайт должен соответствовать требованиям ККСОН (Приказ МОН РК №20, ред. 03.06.2025).

## Рабочая директория
`/home/ubuntu/Joornal_JezU/`

## Язык общения
Русский. Технические термины и код — на английском.

## Архитектура
- **Платформа**: OJS 3.4.x (PHP 8.1+, Smarty templates)
- **БД**: MySQL 8.0
- **Веб-сервер**: Nginx (reverse proxy + SSL)
- **Контейнеризация**: Docker Compose
- **Тема**: Child theme `zhezujournal` на базе default theme OJS
- **Языки**: казахский (kk), русский (ru_RU), английский (en_US)

## Структура проекта
```
Joornal_JezU/
├── CLAUDE.md                    # Этот файл — правила проекта
├── agents/                      # Инструкции для агентов (ролей)
├── rules/                       # Общие правила разработки
├── docs/                        # Проектная документация
│   ├── 01-PROJECT-CHARTER.md
│   ├── 02-WBS-TASKS.md
│   ├── 03-GANTT-SCHEDULE.md
│   ├── 04-RISK-REGISTER.md
│   ├── 05-RACI-MATRIX.md
│   ├── 06-KKSON-COMPLIANCE.md
│   ├── 07-TECH-SPEC.md
│   ├── 08-TEST-PLAN.md
│   ├── architecture/
│   ├── standards/
│   └── templates/
├── docker/                      # Docker Compose, Nginx, конфиги
├── theme/                       # Child theme OJS (zhezujournal)
├── plugins/                     # Кастомные плагины OJS
├── locales/                     # Казахская локаль OJS
├── scripts/                     # Скрипты (бэкап, деплой, импорт)
├── tests/                       # Тестовые сценарии
└── content/                     # Контент для загрузки (от заказчика)
```

## Агентная система
Проект использует 30 специализированных агентов. Каждый агент — роль со своей инструкцией в `agents/`. Вызов агента:
```
«Задача для [АГЕНТ]: описание задачи»
```

### Оркестратор (главный агент)
**Файл**: `agents/00-ORCHESTRATOR.md`
**Вызов**: `«Задача для ORCH: ...»` или при любом запросе без указания конкретного агента.
Оркестратор координирует всех агентов, определяет порядок работ, проверяет результаты, обновляет статусы WBS.

### Список агентов
| Код | Агент | Файл инструкции |
|-----|-------|-----------------|
| **ORCH** | **Оркестратор (главный)** | **agents/00-ORCHESTRATOR.md** |
| PM | Руководитель проекта | agents/01-PM.md |
| BA | Бизнес-аналитик | agents/02-BA.md |
| SA | Системный аналитик | agents/03-SA.md |
| UXD | UX-дизайнер | agents/04-UXD.md |
| UID | UI-дизайнер | agents/05-UID.md |
| GD | Графический дизайнер | agents/06-GD.md |
| BACK | Backend-разработчик | agents/07-BACK.md |
| FRONT | Frontend-разработчик | agents/08-FRONT.md |
| DEVOPS | DevOps-инженер | agents/09-DEVOPS.md |
| SYSADM | Системный администратор | agents/10-SYSADM.md |
| DBA | Администратор БД | agents/11-DBA.md |
| QA | QA-инженер | agents/12-QA.md |
| QAUTO | QA-автоматизатор | agents/13-QAUTO.md |
| UXT | Специалист по юзабилити | agents/14-UXT.md |
| SEC | Специалист по ИБ | agents/15-SEC.md |
| PERF | Специалист по производительности | agents/16-PERF.md |
| CM | Контент-менеджер | agents/17-CM.md |
| EDITRU | Редактор/корректор (рус) | agents/18-EDITRU.md |
| TRKK | Переводчик (казахский) | agents/19-TRKK.md |
| TREN | Переводчик (английский) | agents/20-TREN.md |
| SEO | SEO-специалист | agents/21-SEO.md |
| CHRED | Главный редактор журнала | agents/22-CHRED.md |
| SECR | Ответственный секретарь | agents/23-SECR.md |
| NAUK | Научный консультант | agents/24-NAUK.md |
| JURIST | Юрист | agents/25-JURIST.md |
| BIBLIO | Библиограф | agents/26-BIBLIO.md |
| CURATOR | Куратор проекта | agents/27-CURATOR.md |
| TW | Технический писатель | agents/28-TW.md |
| TRAINER | Специалист по обучению | agents/29-TRAINER.md |
| SUPPORT | Инженер техподдержки | agents/30-SUPPORT.md |

## Правила разработки
Обязательно прочитать `rules/` перед началом работы:
- `rules/01-git.md` — правила работы с git
- `rules/02-code.md` — стандарты кода
- `rules/03-security.md` — правила безопасности
- `rules/04-ojs.md` — правила работы с OJS
- `rules/05-i18n.md` — правила многоязычности
- `rules/06-docker.md` — правила Docker
- `rules/07-testing.md` — правила тестирования

## Ключевые документы
- ТЗ: `ТЗ сайт журнала 2 (1).docx`
- Требования ККСОН: `Адилет требования к Журналу ККСОН 03.06.2025.pdf`
- WBS с задачами: `docs/02-WBS-TASKS.md`
- Техспецификация: `docs/07-TECH-SPEC.md`
