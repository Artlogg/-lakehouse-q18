# Локальный Lakehouse — TPC-H Q18

**Автор:** Кадыров Артур Рустамович

**Вариант:** 3 — Large Volume Customer

**Масштаб:** sf1

Полный отчёт: [отчет.md](отчет.md).

## Состав

- Silo — S3-совместимое хранилище.
- PostgreSQL — состояние каталога Lakekeeper.
- Lakekeeper — Iceberg REST Catalog.
- Trino — загрузка, преобразования и аналитика.
- Superset — дополнительный BI-инструмент в Docker.
- DBeaver — SQL-клиент Windows.

Поток обработки:

`tpch.sf1 → iceberg.bronze_q18 → iceberg.silver_q18.large_orders → iceberg.gold_q18.large_volume_customer`

## Файлы проекта

- `compose.yaml`, `compose.override.yaml` — развёртывание Lakehouse.
- `trino/` — конфигурация движка и каталогов.
- `sql/` — SQL загрузки, преобразований, проверок и экспериментов.
- `compose.bi.yaml` — развёртывание Superset.
- `bi/Dockerfile` — Superset с драйвером Trino.
- `bi/superset_config.py` — локальная конфигурация Superset.
- `scripts/` — создание локальных настроек и инициализация warehouse.
- `results/` — результаты измерений и проверок.
- `docs/images/` — подтверждающие скриншоты.
- `images.lock.json` — digest основных образов.
- `отчет.md` — полный отчёт.

## Запуск уже инициализированного окружения

Из папки проекта, развёрнутого по конфигурациям этого репозитория:

```powershell
docker compose start
docker compose -f compose.bi.yaml up -d superset
```

Проверка:

```powershell
docker compose ps -a
docker compose -f compose.bi.yaml ps -a
docker compose exec trino trino --user student --execute "SELECT count(*) FROM iceberg.gold_q18.large_volume_customer"
```

Последняя команда должна вернуть **57**. На масштабе sf1 найдено 57 подходящих
заказов; `LIMIT 100` задаёт только максимальное количество строк.

Для временной остановки:

```powershell
docker compose -f compose.bi.yaml stop
docker compose stop
```

Тома с данными при остановке сохраняются.

## Развёртывание с нуля

1. Подготовить Docker Desktop с Linux-контейнерами и WSL2. Освободить порты
   8080, 8088, 8181, 9000 и 9001, если их занимает другой стенд.
2. Клонировать репозиторий и перейти в папку проекта:

   ```powershell
   git clone https://github.com/Artlogg/-lakehouse-q18.git lakehouse-q18
   Set-Location lakehouse-q18
   ```

3. Создать локальные настройки и поднять Silo, PostgreSQL и Lakekeeper:

   ```powershell
   & .\scripts\new-local-env.ps1
   docker compose up -d silo postgres lakekeeper-migrate lakekeeper
   docker compose ps -a
   ```

   Дождаться `healthy` у сервисов и `Exited (0)` у миграции.
4. Создать бакет `lakehouse` и зарегистрировать warehouse `lakehouse`:

   ```powershell
   & .\scripts\init-warehouse.ps1
   ```

   Скрипт предназначен для первичной настройки. Используются endpoint
   `http://silo:9000`, регион `us-east-1`, path-style access и префикс `warehouse`.
5. Поднять Trino с каталогами `tpch` и `iceberg`:

   ```powershell
   docker compose up -d trino
   ```

6. Выполнить SQL Bronze, Silver, Gold и проверки:

   ```powershell
   docker compose exec trino trino --user student --file /sql/01_bronze.sql
   docker compose exec trino trino --user student --file /sql/02_silver.sql
   docker compose exec trino trino --user student --file /sql/03_gold_checks.sql
   ```

7. Выполнить остальные сценарии в `sql/`: замеры, изменение схемы и time travel.
   Запросы замеров выполняются отдельно; при новом развёртывании в time travel
   нужно заменить ID снапшота на свой.
8. Собрать и инициализировать Superset:

   ```powershell
   docker compose -f compose.bi.yaml build superset
   docker compose -f compose.bi.yaml run --rm superset superset db upgrade
   docker compose -f compose.bi.yaml run --rm superset superset fab create-admin
   docker compose -f compose.bi.yaml run --rm superset superset init
   docker compose -f compose.bi.yaml up -d superset
   ```

   При создании администратора задать собственные логин и пароль.
9. Добавить подключение `trino://student@trino:8080/iceberg/bronze_q18`
   и выполнить `sql/10_superset_check.sql` в SQL Lab.

Warehouse и таблицы находятся в Docker volumes и не переносятся через Git.
При новом развёртывании инициализацию и SQL необходимо выполнить заново;
ID warehouse и снапшотов будут другими. Повторные `CREATE TABLE` для уже
существующих таблиц приведут к ошибке.

Эксперимент выполнен на ранее настроенном локальном стенде с отдельными
схемами Q18. Для публикации подготовлены конфигурации отдельного проекта.
Они проверены через `docker compose config`; полный отдельный запуск с нуля
не повторялся. Секреты хранятся в локальных `.env` и `.env.bi`,
исключённых из Git.

## Адреса

| Сервис | Адрес |
|---|---|
| Trino | [http://localhost:8080](http://localhost:8080) |
| Silo Console | [http://localhost:9001](http://localhost:9001) |
| Lakekeeper | [http://localhost:8181](http://localhost:8181) |
| Superset | [http://localhost:8088](http://localhost:8088) |

## Основные результаты

| Формат | Кодек | Размер Bronze, МБ | Запись трёх таблиц, с | Медиана Q18, с |
|---|---|---:|---:|---:|
| Parquet | ZSTD | ≈22,177 | 3,198 | 1,150 |
| Parquet | GZIP | 23,825 | 6,941 | 1,240 |
| ORC | ZSTD | 26,930 | 3,726 | 0,976 |

Запись — по одному измерению для каждой таблицы; в сводке показана сумма трёх
значений. Q18 — медиана пяти повторений после одного прогрева.
Использована метрика `Execution` из `EXPLAIN ANALYZE`.

Размеры относятся к текущим файлам данных Iceberg, без метаданных и старых
снапшотов; 1 МБ = 1 000 000 байт. Размер Parquet + ZSTD получен суммой
округлённых размеров трёх таблиц.

Bronze содержит 150 000 клиентов, 1 500 000 заказов и 6 001 215 позиций.
Silver и Gold — по **57 строк**. Проверки подтвердили совпадение Gold с
исходным Q18, отсутствие нарушений проверяемых условий Silver и восстановление
демонстрационной таблицы: 5 строк, 0 заполненных заметок.

В данном опыте Parquet + ZSTD обеспечил минимальный размер и сумму времени
записи, а ORC + ZSTD — минимальную медиану Q18. Подробные измерения сохранены
в [results/](results/), подтверждение работы BI — в [docs/images/](docs/images/).
