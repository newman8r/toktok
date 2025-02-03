# Development Stack Details

## Environment Setup

### Flutter Installation
- Location: `/home/newman/development/flutter`
- Version: 3.19.3 (stable channel)
- Dart SDK: 3.3.1
- DevTools: 2.31.1

### Android Studio
- Version: Hedgehog (2023.1.1)
- Location: `/opt/android-studio`
- Components:
  - Android SDK
  - Flutter plugin
  - Dart plugin
  - KVM enabled for hardware acceleration

### System Configuration
- OS: Debian 12 (linux 6.1.0-30-amd64)
- KVM Configuration:
  - User added to `kvm` and `libvirt` groups
  - Required packages installed:
    ```bash
    qemu-kvm
    libvirt-daemon-system
    libvirt-clients
    bridge-utils
    ```

## Project Structure
```
project3/
├── apps/
│   └── mobile/        # Flutter mobile app
├── backend/
│   └── firebase/      # Firebase configuration and functions
├── docs/
│   ├── arch_advice.md # Architecture guidelines
│   └── stack_details.md # This file
└── README.md
```

## Development Workflow

### Primary Development Environment
- **Cursor**: Main IDE for coding
  - Used for all code editing
  - Integrated terminal for Flutter commands
  - Git operations
  - File management

### Android Studio Role
- Keep minimized but running
- Used only for:
  - Android Virtual Device (AVD) management
  - Android SDK updates
  - Android-specific debugging
  - Not used for regular coding

### Common Flutter Commands
```bash
# Check Flutter installation
flutter doctor

# List available devices
flutter devices

# List available emulators
flutter emulators

# Launch an emulator
flutter emulators --launch <emulator_id>

# Run the app
flutter run

# Get dependencies
flutter pub get

# Run tests
flutter test
```

## Android Configuration
- Build System: Gradle
- JDK: Embedded JDK (Android Studio default)
- Android language: Kotlin
- iOS language: Swift
- Platforms enabled: Android, iOS, Web, Linux, Windows, macOS

## Hardware Acceleration
- KVM enabled for better emulator performance
- Verified through:
  ```bash
  ls -l /dev/kvm
  groups | grep -E 'kvm|libvirt'
  ```

## Initial Setup Verification
To verify the setup is working:
1. Ensure Android Studio is running (minimized)
2. Launch an emulator
3. Run `flutter doctor` to verify all components
4. Test with `flutter run` in the project directory

## Troubleshooting
- If emulator is slow: Verify KVM is properly configured
- If Flutter can't find Android Studio: Ensure Android Studio has completed initial setup
- For permission issues: Verify user groups (kvm, libvirt) 