# rag.nvim

Semantic RAG Plugin for Neovim с SQLite-Vec

## Возможности

- Индексация кодовых файлов с использованием эмбеддингов
- Семантический поиск по коду
- Индексация на уровне проекта
- Параллельная обработка для быстрой индексации
- Автоматическое обновление при сохранении файлов

## Установка

### С использованием Nix

1. Обновите flake:

```bash
nix flake update
```

2. Добавьте плагин в конфигурацию Neovim:

```lua
{
  "jmarkin/rag.nvim",
  flake = "jmarkin/rag.nvim",
}
```

## Использование

### Индексация

Выполните `:RagIndex` для индексации всех файлов в проекте. Это сделает:

1. Поиск всех файлов в текущем репозитории
2. Загрузка файлов размером меньше `max_file_size` токенов
3. Генерация эмбеддингов для каждого чанка файла
4. Хранение векторов в SQLite с sqlite-vec

### Поиск

Выполните `:RagSearch <query>` для поиска по индексированному коду. Результаты будут показаны в списке quickfix.

### Авто-обновление

Плагин автоматически переиндексирует файлы при их сохранении.

## Конфигурация

Смотрите `lua/rag/config.lua` для опций конфигурации.

## Как это работает

- Использует OpenAI эмбеддинги для семантического поиска кода
- Хранит векторы в SQLite с расширением sqlite-vec
- Параллелизирует индексацию для лучшей производительности
- Кэширует эмбеддинги для избежания лишних запросов к API

## Требования

Необходимые компоненты:

- **Neovim 0.9+** — редактор
- **Nix** — система сборки и менеджер зависимостей
- **OpenAI API ключ** — для генерации эмбеддингов

Необходимые зависимости Nix:

- **nixpkgs (nixos-unstable)** — набор пакетов Nix
  - [NixOS/nixpkgs](https://github.com/NixOS/nixpkgs)
- **flake-parts** — инструмент для nix flakes
  - [hercules-ci/flake-parts](https://github.com/hercules-ci/flake-parts)
- **sqlite-lua** — библиотека SQLite для Lua
  - [klocki3/sqlite-lua](https://github.com/klocki3/sqlite-lua)
- **sqlite-vec** — расширение SQLite для векторного поиска
  - [asg017/sqlite-vec](https://github.com/asg017/sqlite-vec)
- **sqlite** — бинарник SQLite
  - [NixOS/nixpkgs](https://github.com/NixOS/nixpkgs)
- **ripgrep (rg)** — утилита для поиска файлов
  - [BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep)

## Дополнительные сведения

Все конфигурации хранятся в `~/.local/share/nvim/rag_index.db` (база данных) и `~/.local/share/nvim/rag_emb_cache.json` (кэш эмбеддингов).
