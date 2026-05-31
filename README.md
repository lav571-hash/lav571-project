# Академия Барберов — MVP

Кросс-платформенное приложение для академии барберов: запись учеников на курсы, ручное подтверждение оплаты администратором, панели преподавателя и администратора.

**Платформы:** Android · iOS · Web (Flutter)

---

## Структура проекта

```
/
├── backend/          # NestJS REST API (TypeScript, модульный монолит)
├── mobile/           # Flutter 3 (iOS / Android / Web)
├── nginx/            # Reverse proxy конфиг
├── docker-compose.yml
├── BACKLOG.md        # Нереализованный функционал
├── ТЗ_MVP_академия_барберов.md
└── Архитектура_MVP_академия_барберов.md
```

---

## Технологический стек

| Слой | Технология |
|------|------------|
| Клиент | Flutter 3.32, Riverpod, GoRouter, Dio |
| Бэкенд | NestJS 11 (TypeScript), REST, OpenAPI/Swagger |
| База данных | PostgreSQL 16 + TypeORM |
| Кэш / Очередь | Redis 7 + BullMQ |
| Хранилище файлов | MinIO (S3-совместимый) |
| Уведомления | FCM (push), SMTP (email), Telegram Bot API |
| Инфраструктура | Docker Compose, Nginx |

---

## Предустановленный admin-аккаунт

При первом запуске бэкенд автоматически создаёт аккаунт администратора:

| Поле | Значение |
|------|----------|
| Email | `admin@barber.academy` |
| Пароль | `Admin1234!` |

Переопределить через `.env`: `ADMIN_EMAIL` / `ADMIN_PASSWORD`.

---

## Быстрый старт

### Бэкенд (локально)

```bash
cd backend
cp .env.example .env   # настройте DATABASE_URL, REDIS_HOST, JWT_SECRET
npm install
npm run start:dev      # → http://localhost:3000
# Swagger UI: http://localhost:3000/api/docs
```

### Полный стек через Docker Compose

```bash
docker compose up -d
# API:      http://localhost/api/v1
# Swagger:  http://localhost/api/docs
# MinIO UI: http://localhost:9001
```

### Flutter (мобильное приложение)

```bash
cd mobile
flutter pub get
flutter run -d android  # или -d ios / -d chrome
```

> Перед запуском укажите адрес бэкенда в `mobile/lib/services/api_client.dart` → `_baseUrl`.

---

## API

### Модули

| Модуль | Ключевые эндпоинты |
|--------|--------------------|
| **Auth** | `POST /auth/register` `POST /auth/login` `POST /auth/refresh` |
| **Users** | `GET /users` `POST /users` `GET /users/me` `PATCH /users/:id` `GET /users/teachers` |
| **Courses** | `GET /courses/published` `POST /courses` `GET /courses/:id` `PATCH /courses/:id/publish` |
| **Sessions** | `POST /courses/:id/sessions` `GET /courses/:id/sessions` |
| **Materials** | `POST /courses/:id/materials` `GET /courses/:id/materials` |
| **Bookings** | `POST /bookings` `GET /bookings/my` `PATCH /bookings/:id/confirm-payment` `PATCH /bookings/:id/cancel` |
| **Teaching** | `GET /teaching/my-students` `GET /teaching/my-courses` `POST /teaching/attendance` `POST /teaching/grades` |
| **Settings** | `GET /settings` `PUT /settings/:key` |

### Роли и права

| Роль | Возможности |
|------|-------------|
| `student` | Каталог курсов, запись, отмена до оплаты, личный кабинет |
| `teacher` | Свои курсы, список учеников, посещаемость, оценки, материалы |
| `admin` | Всё выше + управление пользователями, курсами, подтверждение оплат, настройки |

---

## Жизненный цикл брони

```
[*] → pending_payment  (ученик записался)
pending_payment → confirmed   (admin подтвердил оплату)
pending_payment → cancelled   (ученик отменил сам)
pending_payment → expired     (истёк срок — планировщик каждые 5 мин)
confirmed → cancelled         (admin отменил после оплаты)
```

Срок автоснятия: `PUT /settings/booking_hold_hours` (по умолчанию 24 ч).

---

## Модель данных (основные сущности)

```
Users ──< Bookings >── Courses ──< Sessions
                          │
                     Materials
Bookings ──< Attendance >── Sessions
Bookings ──< Grades
```

---

## Сборки Android

| Версия | Что изменено |
|--------|-------------|
| v0.1.0 | Начальный MVP: каталог, запись, профиль, базовая admin-панель |
| v0.1.1 | Предустановленный admin-аккаунт (SeederService) |
| v0.1.2 | Исправлен URL бэкенда (localhost → публичный) |
| v0.1.3 | Исправлен вход (полный user-объект в JWT ответе) |
| v0.1.4 | Admin: управление пользователями + создание курсов |

Актуальный APK: [Releases](https://github.com/lav571-hash/lav571-project/releases/latest)

---

## Переменные окружения (backend/.env)

```env
NODE_ENV=development
PORT=3000

DATABASE_URL=postgresql://barber:barber@localhost:5432/barber_academy
REDIS_HOST=localhost
REDIS_PORT=6379

JWT_SECRET=change-me-in-production

ADMIN_EMAIL=admin@barber.academy
ADMIN_PASSWORD=Admin1234!

# Email (SMTP)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=...
SMTP_PASS=...

# Telegram Bot
TELEGRAM_BOT_TOKEN=...

# Firebase Cloud Messaging
FCM_SERVER_KEY=...

# S3 / MinIO
S3_ENDPOINT=http://localhost:9000
S3_BUCKET=barber-academy
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin
```

---

## Нереализованный функционал

См. подробный список: **[BACKLOG.md](./BACKLOG.md)**
