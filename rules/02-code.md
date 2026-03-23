# Стандарты кода

## PHP (OJS плагины, кастомизация)
- PHP 8.1+ strict types
- PSR-12 стиль кодирования
- Комментарии на английском
- Docblocks для всех публичных методов
- Использовать OJS DAO layer, НЕ прямые SQL-запросы
- Не модифицировать ядро OJS — только плагины и темы

## Smarty Templates (OJS theme)
- Файлы `.tpl` в `theme/templates/`
- Использовать `{translate key="..."}` для всех строк интерфейса
- Не хардкодить текст — всё через локали
- Экранирование: `{$variable|escape}` по умолчанию
- Комментарии: `{* описание *}`

## CSS/LESS
- LESS компилируется OJS автоматически
- Переменные в `styles/variables.less`
- БЭМ-нотация для кастомных классов: `.zhezu-header__menu-item--active`
- Не использовать `!important` без крайней необходимости
- Mobile-first подход в responsive.less
- Breakpoints: 375px, 768px, 1024px, 1366px, 1920px

## JavaScript
- Vanilla JS или jQuery (OJS включает jQuery)
- Файлы в `theme/assets/js/`
- Строгий режим: `'use strict';`
- Не использовать inline JS в шаблонах

## Именование файлов
- Шаблоны: camelCase (`editorialBoard.tpl`)
- Стили: kebab-case (`editorial-board.less`)
- PHP: PascalCase для классов (`ZhezuJournalThemePlugin.php`)
- Локали: стандарт OJS (`locale/ru_RU/locale.po`)
