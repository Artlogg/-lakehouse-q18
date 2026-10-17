# Локальный Lakehouse — TPC-H Q18

**Кадыров Артур Рустамович. Вариант 3, масштаб sf1.**

Полный отчёт: [отчет.md](отчет.md). Файл для сдачи: [сдача.txt](сдача.txt).

Стек: **Silo → Iceberg / Lakekeeper → Trino → Superset**.
PostgreSQL хранит состояние каталога. DBeaver используется как SQL-клиент Windows.

## Результаты

| Формат | Кодек | Bronze, МБ | Запись 3 таблиц, с | Медиана Q18, с |
|---|---|---:|---:|---:|
| Parquet | ZSTD | ≈22,177 | 3,198 | 1,150 |
| Parquet | GZIP | 23,825 | 6,941 | 1,240 |
| ORC | ZSTD | 26,930 | 3,726 | 0,976 |

Bronze: 150000 клиентов, 1500000 заказов, 6001215 позиций.
Silver и Gold: **57 строк**. LIMIT 100 означает максимум 100 заказов.

В [results/](results/) сохранены исходные времена и сводка, записанные по
измерениям автора. Запись измерялась один раз на таблицу. Q18 — пять повторений
после одного прогрева; метрика — Execution из EXPLAIN ANALYZE.

## Происхождение опубликованных файлов

Эксперименты выполнены на уже работающем локальном стенде с отдельными схемами
Q18. Сохранённые SQL проверены и дополнены разделителями выражений. Конфигурации
подготовлены для отдельного проекта. Секреты вынесены в переменные окружения;
имя сети согласовано с Compose-проектом lakehouse-q18.

Проверки выполнены на работающем стенде: Gold совпадает с исходным Q18,
Silver содержит 57 уникальных заказов без нарушений проверяемых условий.
Конфигурации проверены командой docker compose config. Полный отдельный
запуск с нуля не выполнялся, чтобы не поднимать второй стек на тех же портах.
Скриншот Superset находится в [docs/images/](docs/images/).

## Запуск с нуля: Windows PowerShell

Требуется Docker Desktop с Linux-контейнерами и WSL2, около 8 ГБ памяти для Docker
и свободное место для образов. Порты 8080, 8088, 8181, 9000, 9001 должны быть
свободны: прежний стенд Q3 использует те же порты, поэтому одновременно запускать
его и новый комплект без изменения портов нельзя.

Клонируйте проект:

```powershell
git clone https://github.com/Artlogg/-lakehouse-q18.git lakehouse-q18
Set-Location lakehouse-q18
```

Создайте локальные секреты — скрипт не перезаписывает существующие файлы:

```powershell
& .\scripts\new-local-env.ps1
docker compose config --quiet
docker compose up -d silo postgres lakekeeper-migrate lakekeeper
docker compose ps -a
```

Дождитесь healthy у сервисов и Exited (0) у lakekeeper-migrate. Затем
инициализируйте бакет и warehouse; скрипт предназначен для нового warehouse:

```powershell
& .\scripts\init-warehouse.ps1
docker compose up -d trino
docker compose exec trino trino --user student --execute "SHOW CATALOGS"
```

В Docker должен быть доступ к реестру образов; ошибка DNS auth.docker.io
исправляется на уровне сети, а не изменением SQL. Основные образы закреплены digest из выполненного окружения в Compose;
соответствия сохранены в images.lock.json. В опыте Lakekeeper имел версию
0.14.0. Для базового образа Superset указан тег 6.1.0.

## SQL

В DBeaver: Trino, localhost:8080, пользователь student, без пароля для данного
локального стенда. Внутри Docker используется имя trino, а не localhost.

Выполняйте SQL последовательно:

1. 01_bronze.sql.
2. 02_silver.sql.
3. 03_gold_checks.sql.
4. 04_sizes_benchmark.sql.
5. 05_benchmark_gzip.sql и 06_benchmark_gzip_checks.sql.
6. 07_benchmark_orc.sql.
7. 08_benchmark_write_zstd.sql.
8. 09_schema_evolution.sql.
9. 09_time_travel.sql — сначала замените исторический snapshot ID на свой.
10. 10_superset_check.sql — в Superset SQL Lab.

Все файлы находятся в [sql/](sql/). В DBeaver выполняйте отдельные выражения,
особенно при замерах. Повторный CREATE TABLE без удаления тестовой таблицы
приведёт к ошибке; сценарии намеренно не удаляют рабочие таблицы автоматически.
Секции чтения запускайте один раз для прогрева и ещё пять раз для измерения.

Пример CLI для начальной загрузки:

```powershell
docker compose exec trino trino --user student --file /sql/01_bronze.sql
docker compose exec trino trino --user student --file /sql/02_silver.sql
docker compose exec trino trino --user student --file /sql/03_gold_checks.sql
```

## Superset

```powershell
docker compose -f compose.bi.yaml build superset
docker compose -f compose.bi.yaml run --rm superset superset db upgrade
docker compose -f compose.bi.yaml run --rm superset superset fab create-admin
docker compose -f compose.bi.yaml run --rm superset superset init
docker compose -f compose.bi.yaml up -d superset
```

При create-admin задайте собственный логин и пароль. Откройте
http://localhost:8088, создайте Database Connection с URI:

```text
trino://student@trino:8080/iceberg/bronze_q18
```

В SQL Lab выполните sql/10_superset_check.sql. Результат:
150000 / 1500000 / 6001215 / 57 / 57.

SQLite хранит только служебные данные локального Superset в отдельном volume.
Аналитические таблицы остаются в Silo. В этом учебном варианте не нужны
Celery, Redis или второй вычислительный кластер.

## Остановка и сохранность

```powershell
docker compose -f compose.bi.yaml stop
docker compose stop
```

Данные остаются в volumes. git clone не переносит volumes с работающего стенда:
на новом компьютере нужна первоначальная инициализация и загрузка SQL.
Не применяйте down -v, если данные нужно сохранить.

.env и .env.bi исключены из Git; опубликованы только примеры. Не добавляйте
виртуальные диски Docker, пароли или дампы служебных баз в репозиторий.
