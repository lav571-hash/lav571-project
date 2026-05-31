# Академия Барберов — MVP

Кросс-платформенное приложение для академии барберов. Ученики записываются на курсы, администратор подтверждает оплату вручную.

## Структура проекта

```
/
├── backend/          # NestJS REST API (TypeScript)
├── mobile/           # Flutter (iOS + Android + Web)
├── nginx/            # Конфигурация reverse proxy
├── docker-compose.yml
├── ТЗ_MVP_академия_барберов.md
└── Архитектура_MVP_академия_барберов.md
```

## Стек

| Слой | Технология |
|------|------------|
| Клиент | Flutter 3 (iOS / Android / Web), Riverpod, GoRouter, Dio |
| Бэкенд | NestJS (TypeScript), REST, OpenAPI/Swagger |
| База данных | PostgreSQL 16 |
| Кэш / Очередь | Redis 7 + BullMQ |
| Файлы | MinIO (S3-совместимый) |
| Уведомления | FCM (push), SMTP (email), Telegram Bot API |
| Инфраструктура | Docker Compose, Nginx |

## Предустановленный admin-аккаунт

При первом запуске бэкенд автоматически создаёт аккаунт администратора:

| Поле | Значение |
|------|----------|
| Email | `admin@barber.academy` |
| Пароль | `Admin1234!` |

Изменить через переменные окружения: `ADMIN_EMAIL` и `ADMIN_PASSWORD` в `.env`.

## Быстрый старт (локально)

### Бэкенд

```bash
cd backend
cp .env.example .env    # настройте переменные окружения
npm install
npm run start:dev       # http://localhost:3000
# Swagger: http://localhost:3000/api/docs
```

### Через Docker Compose (полный стек)

```bash
docker compose up -d
# API:   http://localhost/api/v1
# Docs:  http://localhost/api/docs
# MinIO: http://localhost:9001
```

### Flutter

```bash
cd mobile
flutter pub get
flutter run             # выбрать платформу
```

## API Модули

| Модуль | Эндпоинты |
|--------|-----------|
| Auth | `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh` |
| Users | `GET/POST /users`, `GET /users/me`, `PATCH /users/:id` |
| Courses | `GET/POST /courses`, `GET /courses/published`, `GET /courses/:id`, `POST /courses/:id/sessions`, `POST /courses/:id/materials` |
| Bookings | `POST /bookings`, `GET /bookings/my`, `PATCH /bookings/:id/confirm-payment`, `PATCH /bookings/:id/cancel` |
| Teaching | `GET /teaching/my-students`, `POST /teaching/attendance`, `POST /teaching/grades` |
| Settings | `GET/PUT /settings` |

## Роли

| Роль | Возможности |
|------|-------------|
| `student` | Просмотр каталога, запись на курсы, отмена до оплаты, личный кабинет |
| `teacher` | Список своих учеников, расписание, посещаемость, оценки, материалы |
| `admin` | Полный доступ: курсы, слоты, пользователи, подтверждение оплат, настройки |

## Жизненный цикл брони

```
pending_payment → confirmed   (admin подтвердил оплату)
pending_payment → cancelled   (student отменил сам)
pending_payment → expired     (истёк срок, фоновый планировщик)
confirmed       → cancelled   (admin отменил)
```

Срок автоснятия настраивается через `PUT /settings/booking_hold_hours`.
