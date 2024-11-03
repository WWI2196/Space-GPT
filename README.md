# Space GPT

A sophisticated Flutter-based chat application featuring a space-themed UI that integrates with the Gemini Pro language model.

## 🚀 Features

- Space-themed user interface with custom animations
- Real-time chat integration with Gemini Pro AI
- Customizable user and bot avatars
- Cross-platform support (Android, iOS, Windows, macOS, Linux)
- High-performance image caching and preloading
- Message grouping and timestamps
- Dark mode optimized design
- Typing indicators
- Scroll-to-bottom functionality
- Message copy and formatting support

## 🛠 Tech Stack

- Flutter/Dart (SDK ^3.5.3)
- BLoC Pattern for state management (bloc, flutter_bloc)
- Dio for HTTP requests
- Lottie for animations (^3.1.3)
- Google's Gemini Pro API
- Custom image caching system
- Cupertino Icons (^1.0.8)

## 📁 Project Structure

```bash
lib/
├── bloc/
│   ├── chat_bloc.dart                 
│   ├── chat_event.dart
│   └── chat_state.dart              
├── utils/
│   └── constants.dart                  
├── repos/
│   └── chat_repo.dart  
├── model/
│   └── chat_messgae_model.dart                              
├── models/
│   └── profile_model.dart                  
├── pages/
│   └── home_page.dart
├── screens/
│   └── profile_selector_screen.dart               
└── main.dart                     
```

## 🚦 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio/VS Code with Flutter plugins
- Gemini Pro API key

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/space_gpt.git
cd space_gpt
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure API key in constants.dart:
```dart
const String apiKey = 'YOUR_API_KEY_HERE';
```

4. Run the application:
```bash
flutter run
```

## ⚙️ Configuration

### Theme Customization
```dart
theme: ThemeData(
  fontFamily: "Space Mono",
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.grey.shade900,
  primaryColor: Colors.pink.shade900,
)
```

### Avatar Profiles
Add custom avatars in:
- user_profiles
- bot_profiles

## 🔧 Development Resources

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Online documentation](https://docs.flutter.dev/)

## ⚡ Performance Optimizations

- Image preloading and caching
- Optimized message rendering with RepaintBoundary
- Efficient message grouping
- Virtual scrolling implementation

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Flutter development team
- Google's Gemini Pro API
- Space Mono font family
