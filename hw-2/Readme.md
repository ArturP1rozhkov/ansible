# Ansible playbook

Этот playbook устанавливает и настраивает две системы:
- `ClickHouse` - колоночную СУБД (`play` `Install Clickhouse`).
- `Vector` - агент сбора и обработки логов (`play` `Install Vector`).
Каждый `play` работает со своей группой хостов из inventory (`clickhouse`, `vector`) и может запускаться отдельно.
## Структура 
Основные файлы и директории:
- `site.yml` - playbook с двумя `plays` (`Install Clickhouse` и `Install Vector`):
- `inventory/prod.yml` - inventory‑файл с описанием окружения.
- `group_vars/clickhouse/vars.yml` - переменные для группы `clickhouse`.
- `group_vars/vector/vars.yml` - переменные для группы `vector`.
- `templates/vector.yml.j2` - Jinja2‑шаблон конфигурации `vector`.
## Описание play

### Play: Install Clickhouse. Назначение:
  - Скачать RPM‑пакеты `ClickHouse` нужной версии.
  - Установить пакеты `ClickHouse`.
  - Запустить/перезапустить сервис `clickhouse-server`.
  - Создать базу данных `logs`.

Основные` task`:

1. **Скачивание дистрибутивов ClickHouse**

   В блоке `block/rescue` используется модуль `ansible.builtin.get_url`:
   - Основной путь: скачивание пакетов из официального репозитория ClickHouse по пути:  
     `{{ item }}-{{ clickhouse_version }}.noarch.rpm`.
   - Резервный путь: скачивание `clickhouse-common-static` с архитектурой `x86_64`.

2. **Установка пакетов ClickHouse**
   Используется модуль `ansible.builtin.dnf`:
   - Устанавливаются локальные RPM‑файлы:
     - `clickhouse-common-static-{{ clickhouse_version }}.rpm`
     - `clickhouse-client-{{ clickhouse_version }}.rpm`
     - `clickhouse-server-{{ clickhouse_version }}.rpm`
   - При изменении пакетов вызывается handler `Start clickhouse service`.

2. **Запуск сервиса ClickHouse**
   Handler `Start clickhouse service` использует модуль `ansible.builtin.service`:
   - Сервис: `clickhouse-server`.
   - Состояние: `restarted`.

2. **Создание базы данных `logs`**
   Используется модуль `ansible.builtin.command`:
   - Команда: `clickhouse-client -q 'create database logs;'`.
   - Условие успешности (rc - код возврата):
     - `rc == 0` то база создана (задача считается `changed`, возврат 0).
     - `rc == 82` то база уже существует (задача считается `ok`, без ошибки, возврат 82 - официальный код ошибки ClickHouse для ситуации “database already exists”**).

> Данный play для RPM‑совместимых систем (используются `dnf` и RPM‑пакеты). На Ubuntu в таком виде не взлетит.

### Play: Install Vector. Назначение:
  - Установить Vector в домашний каталог пользователя.
  - Создать директории для установки и конфигурации.
  - Развернуть конфигурационный файл Vector из Jinja2‑шаблона.
  - Проверить конфигурацию после изменения (handler Validate vector config).

Основные `tasks`:

1. **Создание директории установки Vector**
   Задача `Create vector install directory`:
   - Модуль: `ansible.builtin.file`.
   - Путь: `{{ vector_install_dir }}`  
     (по умолчанию  `{{ ansible_facts['user_dir'] }}/vector`).
   - Состояние: `directory`.
   - Права: `0755`.
   - `check_mode: false`, то есть каталог создаётся даже при запуске playbook с флагом `--check`, чтобы не ломать проверку других задач.

2. **Скачивание дистрибутива Vector**
   Задача `Get Vector distrib`:
   - Модуль: `ansible.builtin.get_url`.
   - URL:  
     `https://github.com/vectordotdev/vector/releases/download/v{{ vector_version }}/vector-{{ vector_version }}-x86_64-unknown-linux-musl.tar.gz`
   - Путь назначения: `/tmp/vector-{{ vector_version }}.tar.gz`.
   - Права: `0644`.
   - `check_mode: false` - архив скачивается и в обычном режиме, и при запуске с `--check`, чтобы модуль `unarchive` мог корректно отработать.

3. **Распаковка Vector**
   Задача `Unarchive Vector`:
   - Модуль: `ansible.builtin.unarchive`.
   - Источник: `/tmp/vector-{{ vector_version }}.tar.gz`.
   - Папка назначения: `{{ vector_install_dir }}`.
   - `remote_src: true` - архив уже находится на целевом хосте.
   - `extra_opts: ["--strip-components=2"]` - обрезает лишние уровни вложенности в архиве.
   - `creates: "{{ vector_install_dir }}/bin/vector"` - делает задачу идемпотентной: если файл уже существует, распаковка пропускается.

4. **Создание директории конфигурации**
   Задача `Create vector config directory`:
   - Модуль: `ansible.builtin.file`.
   - Путь: `{{ vector_install_dir }}/config`.
   - Состояние: `directory`.
   - Права: `0755`.

5. **Деплой конфигурации Vector из шаблона**
   Задача `Deploy vector config`:
   - Модуль: `ansible.builtin.template`.
   - Шаблон: `templates/vector.yml.j2`.
   - Путь назначения: `{{ vector_install_dir }}/config/vector.yml`.
   - Права: `0644`.
   - При изменении файла срабатывает `notify: Validate vector config`.

6. **Handler: Validate vector config**
   Handler `Validate vector config`:
   - Модуль: `ansible.builtin.command`.
   - Команда:  
     `{{ vector_install_dir }}/bin/vector validate --config {{ vector_install_dir }}/config/vector.yml`
   - `changed_when: false` - `handler` не помечается как изменяющий систему, что помогает сохранять идемпотентность `playbook`
   - Цель `handler` - проверить корректность конфигурационного файла после его изменения.

## Переменные

### Группа clickhouse (`group_vars/clickhouse/vars.yml`)

- `clickhouse_version` - версия ClickHouse.
- `clickhouse_packages` - список пакетов ClickHouse для установки:
  - `clickhouse-client`
  - `clickhouse-server`
  - `clickhouse-common-static`

### Группа vector (`group_vars/vector/vars.yml`)

- `vector_version` - версия Vector.
- `vector_install_dir` - директория установки Vector:  
  `{{ ansible_facts['user_dir'] }}/vector` (по умолчанию это `~/vector` для пользователя, от которого запускается Ansible).

## Inventory

Файл `inventory/prod.yml`:

```yaml
***
clickhouse:
  hosts:
    clickhouse-01:
      ansible_host: 127.0.0.1
      ansible_connection: local

vector:
  hosts:
    vector-01:
      ansible_host: 127.0.0.1
      ansible_connection: local
```

- Группа `clickhouse` - хост `clickhouse-01` на локальной машине.
- Группа `vector` - хост `vector-01` на локальной машине.
- `ansible_connection: local` - выполнение задач происходит локально, без SSH‑подключения.

## Теги

В текущей версии `playbook` теги (`tags:`) не используются:

- Запустить только ClickHouse можно через `--limit clickhouse`.
- Запустить только Vector можно через `--limit vector`.

При необходимости теги можно добавить, например:

- `tags: [clickhouse]` для первого play.
- `tags: [vector]` для второго play.

## Примеры запуска

### Установка только `Vector` на локальном окружении

```bash
cd playbook
ansible-playbook -i inventory/prod.yml site.yml --limit vector
```

### Проверка (`dry‑run`) для `Vector`

```bash
ansible-playbook -i inventory/prod.yml site.yml --check --limit vector
```

### Просмотр отличий и реальное применение для `Vector`

```bash
ansible-playbook -i inventory/prod.yml site.yml --diff --limit vector
```

### Запуск всего `playbook` (`ClickHouse` + `Vector`)

> Для реального запуска `Install Clickhouse` требуется RPM‑совместимая система (RHEL/CentOS/Alma/Rocky и т.п.), так как используются `dnf` и RPM‑пакеты.

```bash
ansible-playbook -i inventory/prod.yml site.yml
```