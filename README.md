<p align="center">
  <img src="EyeCare/Assets.xcassets/AppIcon.appiconset/icon-256.png" width="128" alt="EyeCare">
</p>

<h1 align="center">EyeCare</h1>

<p align="center">
  <img alt="Swift 5.9+" src="https://img.shields.io/badge/Swift-5.9%2B-F05138?logo=swift&logoColor=white">
  <img alt="macOS 26.6+" src="https://img.shields.io/badge/macOS-26.6%2B-000000?logo=apple&logoColor=white">
  <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue">
</p>

EyeCare — небольшое приложение для macOS, которое живёт в строке меню и напоминает вовремя отдыхать от экрана. Оно работает по правилу 20-20-20: каждые 20 минут работы — перерыв, чтобы дать глазам отдохнуть.

## Возможности

- Таймер «работа → перерыв → работа» прямо в строке меню (в формате `05:35` или «6 мин»).
- Полноэкранный оверлей на время перерыва.
- Предупреждение за минуту до перерыва и подсказка у курсора за 10 секунд, с кнопками «+1 / +5 / +15 мин».
- Пауза, сброс таймера и запуск перерыва вручную.
- Настройка длительности работы (1–120 минут) и перерыва (10–600 секунд).

## Запуск проекта

Требования: macOS 26.6 или новее и Xcode с поддержкой Swift 5.9+ (CI использует Xcode 27).

1. Клонируйте репозиторий:

   ```bash
   git clone https://github.com/fix1in1it/eyecare.git
   cd eyecare
   ```

2. Откройте проект в Xcode:

   ```bash
   open EyeCare.xcodeproj
   ```

3. Выберите схему **EyeCare** и destination **My Mac**, затем нажмите **Run** (⌘R). Для запуска из Xcode может понадобиться выбрать свою команду разработчика в *Signing & Capabilities*.

Сборка из командной строки без подписи:

```bash
xcodebuild build \
  -project EyeCare.xcodeproj \
  -scheme EyeCare \
  -configuration Release \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
```

## Установка

1. Скачайте `EyeCare.zip` из раздела [Releases](https://github.com/fix1in1it/eyecare/releases).
2. Распакуйте архив и перетащите `EyeCare.app` в папку `/Applications`.
3. Запустите приложение (см. ниже про неподписанное приложение). Значок глаза появится в строке меню — в Dock приложения нет.

### Запуск неподписанного приложения

Сборки из Releases не подписаны сертификатом разработчика Apple и не нотаризованы, поэтому при первом запуске macOS Gatekeeper может заблокировать приложение («EyeCare не может быть открыт» или «повреждён»). Разблокировать его можно одним из способов:

**Способ 1 — через системные настройки**

1. Попробуйте открыть `EyeCare.app` — macOS покажет предупреждение. Нажмите «Готово».
2. Откройте **Системные настройки → Конфиденциальность и безопасность**.
3. В разделе «Безопасность» найдите сообщение о блокировке EyeCare и нажмите **«Всё равно открыть»**.
4. Подтвердите запуск паролем или Touch ID.

**Способ 2 — через Терминал**

Снимите с приложения атрибут карантина:

```bash
xattr -dr com.apple.quarantine /Applications/EyeCare.app
```

После этого приложение откроется обычным двойным кликом.

Если вы не доверяете готовой сборке, соберите приложение сами — см. «Запуск проекта».

## Лицензия

[MIT](LICENSE)
