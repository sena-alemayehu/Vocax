# Vocax AI

*Your Voice. Your World.* A multilingual AI voice assistant for everyday life.

Built with Flutter. Listens in English, Amharic, Afaan Oromoo, Tigrinya, French, Spanish and Chinese (when the language's voice pack is on the phone) and answers by voice. Spoken replies are still English only.

## Features

- Chat-style screen: your words on the right, Vocax AI on the left. Opening an app shows a card with the app icon, its name and "App opened successfully.", then launches it.
- Web results (Google, YouTube, websites) open inside Vocax AI in a built-in web view.
- First tap on Start listening: "Hello! I'm Vocax Ai Assistance. How can I help you today?"
- Works offline: apps, calls, texts, alarms, flashlight, volume, music, screen control and settings need no internet. When offline the phone's on-device voice pack is used, and web searches answer with a friendly "you are offline".
- "Who built you?" (also French, Spanish, Chinese, Amharic, Afaan Oromoo, Tigrinya): "I was built by Sena Alemayehu, and he is a professional software engineer."
- Side menu: Language, App Permissions, Voice commands, About. Light/dark toggle stays in the top bar.
- Language screen shows each language's voice status ("Voice ready" / "Install voice" with steps).
- App Permissions screen: microphone, contacts, phone calls, Accessibility, with one-tap buttons.
- Accessibility Service (turn on once): screenshots, lock screen, back/home/recents, notifications, scroll/swipe, tap text on screen, type text, and Wi-Fi / Bluetooth / airplane mode / hotspot / location / rotation switches.

## Project structure

```
Vocax/
├── .github/workflows/flutter-build.yml   CI: icon, analyze, test, build the APK
├── android/                              icons + native Kotlin (MainActivity.kt, VocaxAccessibilityService.kt)
├── assets/
│   ├── images/logo.png                   wave logo used in the app
│   └── icons/                            app icon + adaptive icon foreground
├── lib/
│   ├── main.dart                         entry point
│   ├── app.dart                          MaterialApp, light/dark themes
│   ├── theme.dart                        colors, gradient, background
│   ├── screens/
│   │   ├── welcome_screen.dart           "Get Started" screen
│   │   ├── language_screen.dart          Select Language screen + voice status
│   │   ├── permissions_screen.dart       App Permissions screen
│   │   ├── web_screen.dart               in-app web view
│   │   └── home_screen.dart              chat screen + mic button
│   ├── services/
│   │   ├── voice_service.dart            speech recognition + text to speech
│   │   ├── command_handler.dart          understands what you say, picks the action
│   │   ├── device_service.dart           bridge to Android (calls, apps, torch, volume...)
│   │   ├── app_launcher.dart             finds installed apps by spoken name
│   │   ├── contact_service.dart          contact lookup
│   │   ├── fuzzy_match.dart              forgiving name matching
│   │   ├── language_service.dart         supported languages
│   │   └── settings_service.dart         saved theme + language
│   ├── models/                           InstalledApp, DeviceContact, ChatMessage, CommandResult
│   └── widgets/                          drawer, dialogs, language dropdown, logo...
├── test/
├── pubspec.yaml
└── analysis_options.yaml
```

## Voice commands

| Say | Vocax does |
| --- | --- |
| "Open YouTube", "Open WhatsApp", "Open Camera" | opens any app installed on the phone (spoken name is matched loosely) |
| "Call Mom", "Call 0911223344" | calls the contact or number (asks for permission the first time) |
| "Send a message to Mom saying I am late", "Text Mom see you soon" | opens the message ready to send |
| "Search for weather in Addis Ababa" | Google search |
| "Play Ethiopian music on YouTube" | YouTube search |
| "Navigate to Bole Airport" | directions in Maps |
| "Turn on / off the flashlight" | flashlight |
| "Volume up", "Volume down", "Volume 50", "Mute" | media volume |
| "Pause", "Play", "Next song", "Previous song" | controls the current music app |
| "Set an alarm for 7 30 AM", "Set a timer for 5 minutes" | alarm / timer |
| "Take a photo", "Record a video" | opens the camera |
| "Open Wi-Fi settings" (also Bluetooth, location, display, airplane mode, mobile data) | opens that settings page |
| "What is my battery level", "What time is it", "What is the date" | answers |
| "Hello Vocax", "How are you", "What is your name" | small talk |

| "Turn on / off Wi-Fi", "Turn on Bluetooth", "Airplane mode on" | flips the switch through the Accessibility Service (falls back to opening the settings page) |
| "Take a screenshot", "Lock the screen", "Go back", "Go home", "Recent apps", "Open notifications" | needs the Accessibility Service |
| "Scroll down", "Swipe up", "Tap Search", "Type hello" | acts on the app underneath (Accessibility Service) |
| "Who built you?" | names Sena Alemayehu |

The main verbs (open, call, search) also work in French, Spanish, Chinese, Amharic, Tigrinya and Afaan Oromoo. Replies are spoken in English.

### Limits (Android rules)

- Other installed apps cannot be embedded inside Vocax AI. Vocax shows the result card in the chat, then launches the app. Web pages do open inside Vocax AI.
- Accessibility Service must be switched on by the user once (menu, App Permissions, Turn on). On Android 13+ an APK installed outside the Play Store also needs App info, three dots, "Allow restricted settings".
- Switching Wi-Fi/Bluetooth/airplane mode works by tapping the quick-settings tile for you, so it depends on the phone's layout; if the tile is not found Vocax opens the settings page instead.
- Text messages open ready to send; you tap Send. This avoids sending a wrongly heard message.
- Voice packs cannot be installed silently by an app. The Language screen shows what is installed and walks you to the phone's speech settings. Google's speech service may not offer Afaan Oromoo or Tigrinya on every phone.

## App icon

The launcher icons are ready-made files in `android/app/src/main/res` (all sizes, plus the adaptive icon). The workflow copies them over the default Flutter icon on every build. The source art is in `assets/icons`.

## Build

Push to `main` (or run the workflow by hand). GitHub Actions builds the APK and uploads it as the `vocax-android-apk` artifact.

To work on a computer: run `flutter create --platforms=android .` once in this folder to generate `android/`, add the permissions and `<queries>` shown in the workflow to `AndroidManifest.xml`, then copy this repo's `android/app/src/main` over the generated one (it holds the icons and `MainActivity.kt`), then `flutter pub get` and `flutter run`.

## Next steps

- Replies and spoken output in Afaan Oromoo, Amharic, Tigrinya, French, Spanish and Chinese.
- Always-listening "Hey Vocax" wake word.
- Smarter answers for open questions (an AI model).
