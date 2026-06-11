## Описание плейбука

Плейбук выполняет установку и настройку ClickHouse, Vector и LightHouse на соответствующих хостах в Yandex Cloud. Он скачивает необходимые файлы, устанавливает пакеты, размещает конфигурационные файлы и управляет службами.
### Установка и настройка ClickHouse
#### Параметры `hosts` `clickhouse`:
- **Handler**  `Start clickhouse service`  перезапускает службу ClickHouse.
- **Tasks**:
	- `Get clickhouse distrib`:  cкачивает rpm-пакеты ClickHouse.
	- `Install clickhouse packages`: устанавливает пакеты ClickHouse через `dnf`.
	- `Flush handlers`: выполняет отложенные хэндлеры.
	- `Create database`: создает базу данных `logs`.

### Установка и настройка Vector

#### Параметры  `hosts` `vector`:
- **handler**  `Validate vector config`  проверяет корректность конфигурации Vector после изменения файла.
- **Tasks** 
	- `Create vector install directory`: cоздает каталог установки Vector.
	- `Get Vector distrib`: cкачивает архив Vector.
	- `Unarchive Vector`: распаковывает архив Vector в каталог установки.
	- `Create vector config directory`: создает каталог для конфигурации Vector.
	- `Deploy vector config`: размещает конфигурационный файл Vector по шаблону.

### Установка и настройка LightHouse

#### Параметры `hosts: lighthouse`  `become: true`
- **handler** `Restart nginx`: перезапускает Nginx после изменения конфигурации или файлов LightHouse.
- **Tasks** 
	-  `Install Nginx and unzip`: устанавливает Nginx и `unzip`.
	- `Create lighthouse directory`: создает каталог для файлов LightHouse.
	- `Create temporary directory for Lighthouse archive`: создает временный каталог для распаковки архива.
	- `Download Lighthouse archive`: скачивает архив LightHouse из GitHub.
	- `Unarchive Lighthouse`: распаковывает архив LightHouse.
	- `Copy Lighthouse files`: копирует файлы LightHouse в каталог Nginx.
	- `Deploy Nginx config`: размещает конфиг Nginx по шаблону.
	- `Start Nginx service`: запускает Nginx и добавляет его в автозагрузку.

### Переменные

- `clickhouse_version` - версия ClickHouse.
- `clickhouse_packages` - список пакетов ClickHouse.
- `vector_version` - версия Vector.
- `vector_install_dir` - каталог установки Vector.
- `lighthouse_url` - ссылка на архив LightHouse.
- `lighthouse_dir` - каталог файлов LightHouse.
- `lighthouse_nginx_config` - путь к фалу конфига Nginx для LightHouse.

### Inventory

Файл `inventory/prod.yml` содержит:
- IP-адреса хостов;
- пользователя подключения `ansible_user`;
- путь к интерпретатору Python `ansible_python_interpreter`.

### Проверка и запуск

Проверка inventory:
```bash
ansible-inventory -i inventory/prod.yml --list
```

Проверка playbook линтером и чекером:
```bash
ansible-lint site.yml
ansible-playbook -i inventory/prod.yml site.yml --check
```

Запуск playbook в режиме `diff`:
```bash
ansible-playbook -i inventory/prod.yml site.yml --diff
```

Повторный запуск в режиме `diff` для проверки идемпотентности:
```bash
ansible-playbook -i inventory/prod.yml site.yml --diff
```

### Теги

В текущем варианте playbook теги не используются.