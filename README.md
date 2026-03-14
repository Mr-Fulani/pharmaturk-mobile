# PharmaTurk Mobile App

Flutter мобильное приложение для интернет-магазина PharmaTurk (Turk Export). Отдельный репозиторий — работает с API бэкенда PharmaTurk.

## Последние обновления

- **Поиск по тексту** — полнотекстовый поиск товаров с debounce
- **Поиск по фото** — загрузка изображения или вставка URL для визуального поиска похожих товаров (RecSys)
- **Локализация** — русский и английский интерфейс (ru/en)
- **Избранное** — исправлена работа с API и отображение

## Быстрый старт

### Требования

- Flutter SDK 3.8+
- Запущенный бэкенд PharmaTurk на `http://localhost:8000` (или эмулятор: `http://10.0.2.2:8000`)

### 1. Установка зависимостей

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 2. Настройка API URL

URL бэкенда задаётся через `--dart-define`:

**Android эмулятор** (10.0.2.2 — хост-машина):

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

**iOS симулятор / Web:**

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

**Production:**

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.pharmaturk.com
```

### 3. Запуск

```bash
flutter run
```

Подробная шпаргалка — [COMMANDS.md](COMMANDS.md).

## Docker

### Web-режим (разработка)

Backend должен быть запущен отдельно (основной проект PharmaTurk). Скопируйте `.env.example` в `.env` и укажите `API_BASE_URL`:

```bash
cp .env.example .env
# Отредактируйте .env: API_BASE_URL=http://host.docker.internal:8000

docker compose up mobile-web
```

Приложение будет доступно на http://localhost:8080.

**Важно:** На Mac M1/M2 образ Flutter в Docker может падать с segfault. В этом случае запускайте локально:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

### Сборка APK

```bash
API_BASE_URL=https://api.pharmaturk.com docker compose run --rm mobile-build
```

APK: `build/app/outputs/flutter-apk/app-release.apk`

## Структура проекта

```
lib/
├── constants/       # env.dart — конфигурация API URL
├── models/          # Модели данных (Product, User, Cart и т.д.)
├── services/        # API-клиент и сервисы
├── providers/       # State management (Provider)
├── screens/         # Экраны приложения
├── l10n/            # Локализация
├── utils/           # Утилиты
└── main.dart
```

## Функциональность

### Авторизация
- Регистрация, вход по email/паролю
- Социальная авторизация (Google, Telegram)
- Восстановление пароля, подтверждение email

### Каталог
- Просмотр категорий, фильтрация
- Поиск по тексту и по фото
- Детали товара, похожие товары

### Корзина и заказы
- Корзина, промокоды, оформление заказа

### Профиль
- Профиль, история заказов, избранное, адреса, настройки (язык ru/en, валюта)

## API Endpoints

| Endpoint | Описание |
|----------|----------|
| `GET /api/catalog/products/` | Список товаров |
| `GET /api/catalog/products/{slug}/` | Детали товара |
| `GET /api/catalog/products/search/` | Поиск |
| `GET /api/catalog/categories/` | Категории |
| `GET /api/catalog/brands/` | Бренды |
| `GET /api/catalog/banners/` | Баннеры |
| `GET/POST /api/catalog/favorites/` | Избранное |
| `GET/POST /api/orders/cart/` | Корзина |
| `GET/POST /api/orders/orders/` | Заказы |
| `POST /api/users/login/` | Вход |
| `POST /api/users/register/` | Регистрация |
| `GET /api/users/profile/me/` | Профиль |
| `POST /api/upload/temp/` | Загрузка изображения |
| `POST /api/recommendations/search_by_image/` | Поиск по фото |

## Устранение неполадок

### DioException: connection error (Flutter Web)

1. **CORS** — бэкенд должен разрешать запросы с origin Flutter. При `DEBUG=True` обычно `CORS_ALLOW_ALL_ORIGINS = True`.
2. **Бэкенд не запущен** — проверьте `API_BASE_URL`.
3. **Обход CORS для разработки:** `flutter run -d chrome --web-browser-flag "--disable-web-security" --dart-define=API_BASE_URL=http://localhost:8000`

### Ошибки сборки

```bash
flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs
```

## Зависимости

- `provider` — State management
- `dio` — HTTP клиент
- `json_annotation` + `json_serializable` — JSON сериализация
- `cached_network_image` — Кэширование изображений
- `shared_preferences` — Локальное хранилище
- `intl` — Интернационализация
- `url_launcher`, `share_plus`, `image_picker` — Нативные функции

## Лицензия

MIT License
