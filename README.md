# Mebo

**Mebo** is a minimalistic, feature-rich habit tracker built with Flutter. It is designed to help you build good habits, visualize your progress, and stay consistent with gamified elements like **GitVille**.





## ✨ Features:

- **Flexible Habit Tracking**: Support for various habit types to suit your needs:
  - **Boolean**: Simple Yes/No completion.
  - **Numeric**: Track counts or values (e.g., glasses of water, pages read).
  - **Diary**: Record daily entries or reflections.
  - **Meter**: Visual progress tracking.
  - **Savings**: Track financial goals or balances.

- **GitVille**: A unique gamification feature that generates a visual "city" based on your habit consistency and streaks. Watch your city grow as you maintain your habits!

- **Advanced Statistics**: insightful charts and data visualization to analyze your performance over time.

- **Customization**:
  - **Themes**: Switch between Light, Dark, OLED, and Material You (dynamic colors).
  - **Colors**: Assign custom pastel colors to individual habits.
  - **Icons**: Choose from a wide variety of icons for your habits.

- **Privacy & Security**:
  - **Local Storage**: Your data stays on your device.
  - **Biometric Lock**: Protect your private data with Fingerprint or Face ID authentication.
  - **Backup & Restore**: Easily backup your data locally.

- **User Friendly**:
  - **Smart Notifications**: Reminders to keep you on track.
  - **Widgets**: Home screen widgets for quick access.
  - **Accessibility**: Designed to be accessible and easy to use.

## 🛠️ Tech Stack

Mebo is built using modern mobile development technologies:

- **Framework**: [Flutter](https://flutter.dev/)
- **Language**: [Dart](https://dart.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Database**: [Sqflite](https://pub.dev/packages/sqflite)
- **Localization**: `flutter_localizations`, `intl`
- **Charts**: `fl_chart`
- **Notifications**: `awesome_notifications`

## 🚀 Getting Started

Follow these steps to set up the project locally.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.38.4 or higher recommended)
- Android Studio or VS Code with Flutter/Dart extensions.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/mebo.git
    cd mebo
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```

## 📂 Project Structure

- `lib/main.dart`: Application entry point and configuration.
- `lib/habits`: Core logic and UI for habit management.
- `lib/location/gitville`: GitVille city generation and visualization.
- `lib/model`: Data models and database interactions.
- `lib/screens`: Primary application screens.
- `lib/services`: Background services (Notifications, Backup, etc.).
- `lib/settings`: Settings management and theming.
- `lib/statistics`: Analytics and charting features.
- `lib/widgets`: Reusable UI components.

## 🤝 Contributing

Contributions are welcome! Please check out [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## 📄 License

This project is licensed under the terms found in the [LICENSE](LICENSE) file.
