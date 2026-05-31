# Академия Барберов — MVP

Кросс-платформенное приложение для академии барберов: запись учеников на курсы, ручное подтверждение оплаты администратором, управление пользователями и курсами.

**Платформы:** Android · iOS · Web (Flutter)

---

## Демо

| Ресурс | URL |
|--------|-----|
| 🌐 Веб-приложение | **https://lav571-hash.github.io/lav571-project/** |
| 📦 Android APK | [Releases → v0.1.4](https://github.com/lav571-hash/lav571-project/releases/latest) |
| 📖 API Swagger | (см. раздел «Запуск бэкенда») |

**Войти как администратор:** `admin@barber.academy` / `Admin1234!`

> ⚠️ Демо-бэкенд работает на временном сервере. Для постоянного хостинга см. раздел «Деплой бэкенда».

---

## Структура проекта

```
/
├── backend/                    # NestJS REST API (TypeScript)
│   ├── src/
│   │   ├── auth/               # Аутентификация, JWT, RBAC
│   │   ├── users/              # Управление пользователями
│   │   ├── courses/            # Курсы, расписание, материалы
│   │   ├── booking/            # Записи, оплата, автоснятие брони
│   │   ├── teaching/           # Посещаемость, оценки (преподаватель)
│   │   ├── notifications/      # Очередь уведомлений (BullMQ)
│   │   ├── settings/           # Конфигурируемые параметры
│   │   └── database/           # TypeORM сущности + Seeder
│   ├── fly.toml                # Конфиг для Fly.io
│   └── Dockerfile
├── mobile/                     # Flutter 3 (iOS / Android / Web)
│   ├── lib/
│   │   ├── screens/            # UI экраны
│   │   ├── providers/          # Riverpod провайдеры
│   │   ├── services/           # HTTP сервисы (Dio)
│   │   ├── models/             # JSON-сериализуемые модели
│   │   ├── widgets/            # Переиспользуемые виджеты
│   │   ├── theme/              # Тёмная тема барбер-индустрии
│   │   └── utils/              # GoRouter навигация
│   └── pubspec.yaml
├── nginx/nginx.conf            # Reverse proxy
├── docker-compose.yml          # Полный стек локально
├── render.yaml                 # Конфиг для Render.com
├── BACKLOG.md                  # Нереализованный функционал
└── ТЗ/Архитектура .md          # Исходные документы
```

---

## Технологический стек

| Слой | Технология |
|------|------------|
| Клиент | Flutter 3.32, Riverpod, GoRouter, Dio |
| Бэкенд | NestJS 11 (TypeScript), REST API, OpenAPI/Swagger |
| БД | PostgreSQL 16 + TypeORM |
| Кэш / Очередь | Redis 7 + BullMQ |
| Хранилище файлов | MinIO (S3-совместимый) |
| Уведомления | FCM (push), SMTP (email), Telegram Bot API *(заглушки)* |
| Хостинг фронта | GitHub Pages |
| Инфраструктура | Docker Compose, Nginx, Fly.io / Render.com |

---

## Роли пользователей

| Роль | Возможности |
|------|-------------|
| `student` | Каталог курсов (публичный), запись, отмена до оплаты, личный кабинет |
| `teacher` | Свои курсы, список учеников, посещаемость, оценки, материалы |
| `admin` | Всё + управление пользователями и курсами, подтверждение оплат, настройки |

### Предустановленный admin

| Поле | Значение |
|------|----------|
| Email | `admin@barber.academy` |
| Пароль | `Admin1234!` |

Настраивается через `.env`: `ADMIN_EMAIL` / `ADMIN_PASSWORD`.

---

## Реализованный функционал

### Backend (NestJS)

| Модуль | Эндпоинты | Статус |
|--------|-----------|--------|
| **Auth** | `POST /auth/register` `POST /auth/login` `POST /auth/refresh` | ✅ |
| **Users** | `GET/POST /users` `GET /users/me` `PATCH /users/:id` `GET /users/teachers` | ✅ |
| **Courses** | `GET /courses` `POST /courses` `GET /courses/published` *(публичный)* `GET /courses/:id` | ✅ |
| **Sessions** | `POST /courses/:id/sessions` `GET /courses/:id/sessions` `DELETE` | ✅ |
| **Materials** | `POST/GET /courses/:id/materials` `DELETE` | ✅ |
| **Bookings** | `POST /bookings` `GET /bookings/my` `PATCH /:id/confirm-payment` `PATCH /:id/cancel` | ✅ |
| **Teaching** | `GET /teaching/my-students` `GET /teaching/my-courses` `POST /teaching/attendance` `POST /teaching/grades` | ✅ |
| **Settings** | `GET /settings` `PUT /settings/:key` | ✅ |

### Flutter — экраны

| Экран | Роль | Статус |
|-------|------|--------|
| Вход / Регистрация | Все | ✅ |
| Каталог курсов (фильтры, поиск) | Все | ✅ |
| Детали курса (описание / расписание / программа) | Все | ✅ |
| Запись на курс с подтверждением | Ученик | ✅ |
| Личный кабинет (мои записи, статус оплаты, отмена) | Ученик | ✅ |
| Admin: вкладка «Записи» (подтверждение оплаты, отмена) | Admin | ✅ |
| Admin: вкладка «Курсы» (список) | Admin | ✅ |
| Admin: создание курса (форма + добавление занятий) | Admin | ✅ |
| Admin: вкладка «Пользователи» (список + создание admin/teacher) | Admin | ✅ |
| Admin: вкладка «Настройки» (срок автоснятия брони) | Admin | ✅ |

---

## Жизненный цикл брони

```
[*] → pending_payment    ← ученик записался
pending_payment → confirmed     ← admin подтвердил оплату
pending_payment → cancelled     ← ученик отменил сам
pending_payment → expired       ← планировщик (каждые 5 мин)
confirmed → cancelled           ← admin отменил после оплаты
```

Срок автоснятия: `PUT /settings/booking_hold_hours` (по умолчанию **24 ч**).

---

## Запуск бэкенда

### Локально (разработка)

```bash
# Требования: Node.js 18+, PostgreSQL 16, Redis 7
cd backend
cp .env.example .env    # заполните DATABASE_URL, REDIS_HOST, JWT_SECRET
npm install
npm run start:dev       # → http://localhost:3000
# Swagger: http://localhost:3000/api/docs
```

### Docker Compose (полный стек)

```bash
docker compose up -d
# API:      http://localhost/api/v1
# Swagger:  http://localhost/api/docs
# MinIO UI: http://localhost:9001 (admin/admin)
```

---

## Деплой бэкенда (постоянный хостинг)

### Вариант А — Fly.io (рекомендуется)

```bash
# Установить CLI
curl -L https://fly.io/install.sh | sh

# Авторизоваться
flyctl auth login

# Создать PostgreSQL
flyctl postgres create --name barber-academy-db --region fra

# Создать Redis
flyctl redis create --name barber-academy-redis --region fra

# Задеплоить бэкенд
cd backend
flyctl launch --name barber-academy-backend --region fra --no-deploy

# Привязать БД
flyctl postgres attach barber-academy-db

# Задать переменные
flyctl secrets set JWT_SECRET=$(openssl rand -hex 32) \
  ADMIN_EMAIL=admin@barber.academy \
  ADMIN_PASSWORD=Admin1234!

# Деплой
flyctl deploy
```

### Вариант Б — Render.com (через UI)

1. [render.com](https://render.com) → **New → Blueprint**
2. Выбрать репозиторий `lav571-project`
3. Render автоматически создаст сервисы из `render.yaml`:
   - Web Service (NestJS)
   - PostgreSQL (free)
   - Redis (free)

После деплоя — сообщить URL и обновить Flutter-приложение.

---

## Сборка Flutter

### Android APK

```bash
cd mobile
flutter pub get
flutter build apk --release \
  --dart-define="API_URL=https://YOUR-BACKEND-URL/api/v1"
```

### Веб (GitHub Pages)

```bash
flutter build web --release \
  --base-href "/lav571-project/" \
  --dart-define="API_URL=https://YOUR-BACKEND-URL/api/v1"
# Результат: mobile/build/web → gh-pages ветка
```

---

## Переменные окружения

```env
# backend/.env
NODE_ENV=development
PORT=3000

DATABASE_URL=postgresql://barber:barber@localhost:5432/barber_academy
REDIS_HOST=localhost
REDIS_PORT=6379
# или строкой: REDIS_URL=redis://localhost:6379

JWT_SECRET=replace-with-long-random-string

# Seeder (первый запуск)
ADMIN_EMAIL=admin@barber.academy
ADMIN_PASSWORD=Admin1234!

# Email уведомления (SMTP)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=noreply@example.com
SMTP_PASS=your-password

# Telegram Bot
TELEGRAM_BOT_TOKEN=your-bot-token

# Firebase Cloud Messaging
FCM_SERVER_KEY=your-fcm-key

# S3 / MinIO
S3_ENDPOINT=http://localhost:9000
S3_BUCKET=barber-academy
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin
AWS_REGION=us-east-1
```

---

## История версий (Android APK)

| Версия | Дата | Изменения |
|--------|------|-----------|
| **v0.1.4** | 31.05.2026 | Admin: управление пользователями + создание курсов |
| v0.1.3 | 31.05.2026 | Исправлен вход (полный user-объект в JWT-ответе) |
| v0.1.2 | 31.05.2026 | Исправлен URL бэкенда (localhost → Cloudflare tunnel) |
| v0.1.1 | 31.05.2026 | Предустановленный admin-аккаунт (SeederService) |
| v0.1.0 | 31.05.2026 | Первая сборка: каталог, запись, профиль, базовая admin-панель |

---

## Нереализованный функционал

Подробный список: **[BACKLOG.md](./BACKLOG.md)**

Краткая сводка по приоритетам:

| Приоритет | Задача |
|-----------|--------|
| 🔴 Высокий | Панель преподавателя (Flutter UI): ученики, посещаемость, оценки |
| 🔴 Высокий | Реальные уведомления: push (FCM), email (SMTP), Telegram |
| 🔴 Высокий | Личный кабинет ученика: расписание, история, материалы, оценки |
| 🟡 Средний | Редактирование курса и занятий (Flutter UI) |
| 🟡 Средний | Загрузка фото курсов (S3/MinIO) |
| 🟡 Средний | Смена пароля |
| 🟡 Средний | Деактивация пользователей (Flutter UI) |
| 🟡 Средний | Фильтрация и поиск в admin-панели |
| 🔵 Следующий этап | Онлайн-оплата (ЮKassa / Stripe) |
| 🔵 Следующий этап | Сертификаты, аналитика, мультифилиальность |
