# Dev Container Docker Image

## Overview
Docker-образ для работы AI-агентов (claude-code, codex) над любыми проектами. Включает полное окружение для разработки на Python, Node.js и Go с предустановленным ralphex.

Компоненты:
- **claude-code** — CLI от Anthropic для работы с Claude
- **codex** — CLI от OpenAI для работы с GPT
- **Python 3.12+** — с pip, venv, основными dev-зависимостями
- **Node.js 22 LTS** — с npm, pnpm, frontend-инструментами
- **Go 1.23+** — для сборки Go-проектов и ralphex
- **ralphex** — инструмент автономного выполнения планов

## Context
- Новый проект, пустая директория
- Базовый образ: Ubuntu 24.04
- Multi-stage build для оптимизации размера
- **Персистентный home**: вся home-директория контейнера монтируется из хоста
  - На хосте: `./home` (или configurable path)
  - В контейнере: `/home/developer`
  - При первом запуске — авторизация через `claude login`, `codex login`
  - Все креды, конфиги, история сохраняются между запусками

## Development Approach
- **Testing approach**: Regular (код, затем тесты)
- Dockerfile тестируем через сборку и проверку наличия инструментов
- Каждый этап — логически завершённая часть
- **CRITICAL: каждая задача включает проверку работоспособности**
- **CRITICAL: проверки должны проходить перед следующей задачей**

## Testing Strategy
- **Unit tests**: Dockerfile проверяется через сборку и smoke-тесты
- **Smoke tests**: скрипт проверки наличия и версий всех инструментов
- E2E тесты не применимы для Docker-образа

## Progress Tracking
- Mark completed items with `[x]` immediately when done
- Add newly discovered tasks with ➕ prefix
- Document issues/blockers with ⚠️ prefix

## Implementation Steps

### Task 1: Создать структуру проекта
- [x] создать базовую структуру директорий
- [x] создать .gitignore (включить home/ — там креды!)
- [x] создать .dockerignore для исключения лишних файлов
- [x] проверить структуру через ls

### Task 2: Создать Dockerfile — базовый слой
- [x] создать Dockerfile с multi-stage структурой
- [x] настроить базовый Ubuntu 24.04 образ
- [x] установить системные зависимости (curl, git, build-essential, etc.)
- [x] собрать образ — проверить что этап проходит

### Task 3: Добавить Go в Dockerfile
- [x] добавить stage для копирования Go из официального образа
- [x] настроить GOPATH и PATH
- [x] собрать образ — проверить `go version`

### Task 4: Добавить Node.js в Dockerfile
- [x] установить Node.js 22 LTS через NodeSource или официальный образ
- [x] установить pnpm глобально
- [x] собрать образ — проверить `node --version`, `npm --version`, `pnpm --version`

### Task 5: Добавить Python в Dockerfile
- [x] установить Python 3.12 из deadsnakes PPA или системного репозитория
- [x] установить pip, venv
- [x] установить poetry/uv для управления зависимостями
- [x] собрать образ — проверить `python3 --version`, `pip --version`

### Task 6: Установить AI-агенты
- [x] установить claude-code через npm (`@anthropic-ai/claude-code`)
- [x] установить codex через npm (`@openai/codex`)
- [x] собрать образ — проверить `claude --version`, `codex --version`

### Task 7: Установить ralphex
- [x] установить ralphex из GitHub releases или через go install
- [x] собрать образ — проверить `ralphex --version`

### Task 8: Финализировать образ
- [x] настроить рабочую директорию (/workspace)
- [x] настроить entrypoint/cmd
- [x] добавить non-root пользователя `developer` (UID 1000) с home в /home/developer
- [x] home будет монтироваться с хоста — не создавать файлы внутри образа
- [x] собрать финальный образ — полная проверка

### Task 9: Создать Makefile
- [x] добавить `make build` — сборка образа
- [x] добавить `make run` — запуск контейнера с маунтами:
  - `./home` → `/home/developer` (персистентный home)
  - текущая директория (или PROJECT=...) → `/workspace`
- [x] добавить `make shell` — интерактивный шелл в контейнере
- [x] добавить `make test` — запуск smoke-тестов
- [x] добавить `make init` — создать ./home если не существует
- [x] проверить все команды работают

### Task 10: Создать smoke-test скрипт
- [ ] создать scripts/smoke-test.sh
- [ ] проверка всех установленных инструментов и их версий
- [ ] запустить `make test` — все проверки должны пройти

### Task 11: Верификация
- [ ] убедиться что образ собирается без ошибок
- [ ] убедиться что все инструменты доступны в контейнере
- [ ] проверить размер образа — должен быть разумным (<3GB)
- [ ] запустить полный smoke-test

### Task 12: [Final] Документация
- [ ] создать README.md с инструкциями по использованию
- [ ] описать персистентный home и первую авторизацию
- [ ] описать как маунтить проекты
- [ ] добавить примеры использования с разными проектами

## Technical Details

### Структура файлов
```
dev-container/
├── Dockerfile
├── Makefile
├── .dockerignore
├── .gitignore
├── home/                    # персистентный home (создаётся при первом запуске)
│   ├── .claude/             # креды и настройки claude-code
│   ├── .config/             # конфиги (ralphex и др.)
│   └── ...                  # остальные dotfiles
├── scripts/
│   └── smoke-test.sh
├── docs/
│   └── plans/
│       └── dev-container-docker-image.md
└── README.md
```

### Персистентный home
Вся home-директория контейнера монтируется с хоста:

| Host path | Container path | Назначение |
|-----------|----------------|------------|
| `./home` | `/home/developer` | Персистентный home (креды, конфиги, история) |
| `$(pwd)` или указанный путь | `/workspace` | Рабочий проект |

**Первый запуск:**
```bash
make build
make run
# В контейнере:
claude login      # авторизация claude-code
codex login       # авторизация codex (если нужно)
```

**Последующие запуски:** авторизация сохранена в `./home`, повторный логин не нужен.

### Использование
```bash
# Сборка образа
make build

# Запуск (текущая директория как workspace)
make run

# Запуск с указанием проекта
make run PROJECT=/path/to/project

# Или явный запуск
docker run -it --rm \
  -v $(pwd)/home:/home/developer \
  -v /path/to/project:/workspace \
  dev-container
```

## Post-Completion
**Ручная верификация:**
- Выполнить `claude login` при первом запуске
- Проверить что креды сохраняются в ./home между перезапусками
- Проверить работу claude-code с авторизацией
- Проверить работу codex (если нужен)
- Протестировать на реальном проекте

**Возможные улучшения:**
- Добавить docker-compose для более сложных сценариев
- Добавить GitHub Actions для автоматической сборки
- Опубликовать на Docker Hub / GitHub Container Registry
- Добавить скрипт миграции существующих конфигов с хост-системы в ./home
