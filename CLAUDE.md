# CLAUDE.md

Руководство для Claude Code по работе с этим репозиторием.

## О проекте

EyeCare — macOS-приложение для строки меню (SwiftUI, `MenuBarExtra`, `LSUIElement = YES`, без значка в Dock). Напоминает делать перерывы для глаз: цикл «работа → перерыв → работа». Интерфейс на русском языке.

- Swift, language mode 5.0 (`SWIFT_VERSION = 5.0`), macOS deployment target 26.6.
- Зависимостей нет; один Xcode-проект `EyeCare.xcodeproj`, схема `EyeCare`.
- Bundle ID: `alexzobnin.EyeCare`.

## Структура

Весь код — в `EyeCare/`:

- `EyeCareApp.swift` — точка входа, `MenuBarExtra` с иконкой и текстом таймера.
- `BreakTimer.swift` — состояние таймера (фазы `working` / `onBreak`, пауза, продление), управляет оверлеями.
- `AppSettings.swift` — настройки в `UserDefaults` (длительность работы и перерыва, стиль текста в меню-баре).
- `MenuBarView.swift` — popover меню-бара.
- `SettingsView.swift` — окно настроек.
- `BreakOverlay.swift` — полноэкранный оверлей перерыва.
- `BreakWarning.swift` — плашка за минуту до перерыва.
- `BreakCursorHint.swift` — плашка у курсора за 10 секунд до перерыва.
- `Assets.xcassets` — иконка приложения.

## Сборка и проверка

Сборка (как в CI, без подписи):

```bash
xcodebuild build -project EyeCare.xcodeproj -scheme EyeCare -configuration Release \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
```

Тестов в проекте нет. Сборка требует macOS и Xcode — на Linux (облачная среда) собрать нельзя, полагайтесь на CI.

## CI/CD

- `.github/workflows/build.yml` — сборка на каждый pull request (раннер `xcode-27`).
- `.github/workflows/release.yml` — ручной запуск (`workflow_dispatch`), выбор `patch` / `minor` / `major`; вычисляет версию из git-тегов `vX.Y.Z`, собирает неподписанное приложение и публикует `EyeCare.zip` в GitHub Release.

## Соглашения

- Комментарии и строки интерфейса — на русском, как в существующем коде.
- Файлы Swift начинаются со стандартного заголовка Xcode (`//  Имя.swift` / `//  EyeCare`).
- Не добавляйте сторонние зависимости без необходимости.
- Работа ведётся в ветках, изменения попадают в `master` через pull request.
- Новые файлы в проект добавляются через `project.pbxproj`; правьте его осторожно.
