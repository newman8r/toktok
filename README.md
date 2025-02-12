# Crystal Gems - A Magical Video Creation Studio 🎥✨

A beautifully crafted Flutter application that transforms your videos into magical crystal gems. Experience an enchanting interface with crystal-themed animations and powerful video editing capabilities.

## ✨ Features

### Crystal Explorer Interface
- **Hexagonal Navigation**: Unique spatial navigation system with a crystal cave-like interface
- **Crystal Video Player**: Immersive video playback with crystal-themed controls
- **Animated Transitions**: Smooth spatial transitions between editing modes with crystal shard effects
- **Haptic Feedback**: Tactile response for enhanced interaction
- **Dynamic Lighting**: Beautiful crystal-themed gradients and ambient effects

### Video Enhancement
- **AI Music Magic**: Generate magical background music that matches your video's mood
- **Smart Trimming**: Crystal-precise video trimming with frame-accurate controls
- **Object Detection**: AI-powered object recognition to discover hidden treasures in your videos
- **Meta Editing**: Enhance your gem's details with custom metadata
- **Info Analysis**: Crystal-clear insights about your video content

### Magical Experience
- **Crystal Shatter Effects**: Beautiful deletion animations with flying crystal shards
- **Ambient Sound Effects**: Mystical audio feedback for actions
- **Particle Systems**: Dynamic particle effects for trash and deletion animations
- **Gem Collection**: Organize and manage your video gems in a beautiful gallery
- **Publishing Studio**: Share your enhanced crystal gems with magical transitions

### Crystal-Clear UI
- **Ruby Accents**: Danger and deletion actions themed with ruby crystals
- **Sapphire Elements**: Cool, calming interface elements
- **Amethyst Highlights**: Magical accent colors for special features
- **Emerald Touches**: Success and confirmation indicators
- **Deep Cave Theme**: Dark mode interface with crystal highlights

### Smart Features
- **Auto-Save**: Never lose your progress with automatic saving
- **Gesture Controls**: Intuitive touch controls for video manipulation
- **Progress Tracking**: Crystal-clear progress indicators for all operations
- **Error Handling**: Graceful error recovery with themed error messages
- **Responsive Design**: Adapts beautifully to any screen size

## 🏗️ Architecture

The application follows a clean, layered architecture:

```
lib/
├── models/          # Data models and entities
├── pages/           # UI screens and widgets
├── services/        # Business logic and API integration
├── theme/           # App-wide styling and theming
└── widgets/         # Reusable UI components
```

### Key Components

- **Authentication Service**: Handles user registration, login, and session management
- **Cloudinary Service**: Manages video upload, processing, and delivery
- **Gem Service**: Core business logic for video management and social features
- **Custom Widgets**: Reusable components following consistent design patterns
- **Search Service**: Handles content discovery and filtering
- **Tag Management**: Organizes and manages video metadata

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode
- Firebase project
- Cloudinary account

### Environment Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/toktok.git
cd toktok
```

2. Create a `.env` file in the root directory:
```
CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
CLOUDINARY_CLOUD_NAME=your_cloud_name
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## 📱 Building for Production

### Android

1. Create a keystore (if not already created):
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Build APK for Firebase Distribution:
```bash
flutter build apk --release
```

The release APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### iOS

1. Set up signing in Xcode
2. Build the app:
```bash
flutter build ipa
```

## 🔧 Technical Details

### State Management
- Clean separation of UI and business logic
- Efficient state management using Flutter's built-in state solutions
- Reactive programming patterns for real-time updates

### Performance Optimizations
- Lazy loading of videos
- Efficient memory management
- Image and video caching
- Background processing for uploads
- Smart search indexing
- Optimized tag filtering

### Security Features
- Secure Firebase Authentication
- Protected API endpoints
- Environment variable management
- Proper key and secret handling
- Safe navigation handling

## 📚 Dependencies

Core dependencies:
- `firebase_core`: ^2.24.2
- `firebase_auth`: ^4.15.3
- `cloud_firestore`: ^4.13.6
- `firebase_storage`: ^11.5.6
- `camera`: ^0.10.5+9
- `video_player`: ^2.8.2
- `permission_handler`: ^11.3.0
- `cloudinary`: ^1.2.0
- `flutter_dotenv`: ^5.1.0

## 🎯 Future Roadmap

Planned features and improvements:
- Enhanced video editing capabilities
- Social sharing integrations
- Advanced analytics dashboard
- AI-powered content recommendations
- Collaborative features
- Multi-platform support (web, desktop)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Cloudinary for video hosting
- All contributors and supporters

---

Built with ❤️ using Flutter
