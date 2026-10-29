
# 🧭 Smart Navigation System for Visually Impaired People

An AI-powered Smart Navigation System designed to assist visually impaired individuals in navigating their surroundings more safely and independently. The system aims to provide destination guidance through voice interaction, route assistance, and obstacle detection.

## 📌 Project Overview

Navigation in unfamiliar environments can be challenging for visually impaired people. Traditional navigation applications mainly depend on visual maps and directions, which may not be sufficient for users who cannot easily access visual information.

The **Smart Navigation System** aims to improve accessibility by combining voice-based interaction, destination selection, navigation assistance, and obstacle detection in a user-friendly interface.

The system is designed to help users interact with the application using voice commands or text input and receive understandable navigation instructions.

## 🎯 Objectives

- Develop an accessible navigation interface for visually impaired users.
- Enable users to enter destinations using voice or text.
- Provide navigation guidance in an easy-to-understand format.
- Support obstacle detection to improve awareness of nearby obstacles.
- Reduce dependence on visual interfaces.
- Promote independent and accessible navigation.

## ✨ Key Features

- **Voice-Based Interaction:** Allows users to interact with the system through voice input, where implemented.
- **Destination Selection:** Enables users to specify their intended destination.
- **Navigation Assistance:** Provides route information and directional guidance through the supported navigation service.
- **Obstacle Detection:** Identifies obstacles using the implemented detection method.
- **Accessible User Interface:** Designed to make navigation functions easier to access.
- **Audio Feedback:** Communicates supported instructions and alerts through voice output.

## 🛠️ Technologies Used

Update this section to match the technologies actually used in your project.

- **Frontend:** [HTML, CSS, JavaScript / React / other framework]
- **Backend:** [Python Flask / Django / other framework]
- **Programming Language:** [Python / JavaScript / other language]
- **AI/Computer Vision:** [OpenCV / YOLO / other model, if implemented]
- **Voice Processing:** [Speech Recognition / Text-to-Speech library, if implemented]
- **Maps and Routing:** [Google Maps API / OpenStreetMap / other service, if implemented]
- **Development Tools:** Visual Studio Code, Git, GitHub

## ⚙️ System Workflow

1. **Start the Application:** The user opens the Smart Navigation System.
2. **Select a Destination:** The user enters a destination using the available input method.
3. **Process the Destination:** The system processes the destination information.
4. **Generate Navigation Guidance:** The system obtains or calculates route information using the implemented navigation component.
5. **Detect Obstacles:** The obstacle detection component analyzes available sensor or camera input, if supported.
6. **Provide Feedback:** The system communicates navigation instructions or obstacle alerts using the available output method.
7. **Continue Navigation:** The user follows the provided guidance toward the destination.

## 🏗️ System Architecture

The proposed system consists of the following components:

- **User Interface:** Provides access to navigation functions and destination input.
- **Voice Interaction Module:** Handles voice commands and audio feedback, if implemented.
- **Navigation Module:** Processes destination details and provides route guidance.
- **Obstacle Detection Module:** Analyzes input data to identify obstacles, if implemented.
- **Output Module:** Presents navigation instructions and alerts to the user.

These components work together to provide an accessible navigation experience.

## 🚀 Getting Started

## 📋 Prerequisites

Before running the project, install the following:

Flutter SDK

Dart SDK (included with Flutter)

Android Studio or Visual Studio Code

Android SDK and platform tools

Git

An Android phone or emulator

Verify the Flutter installation:

flutter doctor -v

Resolve the relevant setup issues reported by Flutter before proceeding.

## 📂 Project Setup

Step 1: Clone the Repository

git clone https://github.com/Afreen-khamar/smart_navigation.git

Step 2: Open the Project Folder

cd smart_navigation

Step 3: Download Dependencies

flutter pub get

This command downloads the dependencies specified in pubspec.yaml.

Step 4: Check Connected Devices

flutter devices

Connect an Android phone with USB debugging enabled or start an Android emulator.

Step 5: Run the Application

flutter run

The application will be built and launched on the selected device.

## 💻 Terminal Commands Reference

The following commands are useful for development, testing, troubleshooting, and preparing the final Android application.

1. Check Flutter Installation

flutter doctor -v

Purpose: Checks the Flutter development environment, Android SDK, and other required tools.

Where to run: PowerShell or VS Code terminal.

2. Open the Project Folder

cd C:\src\smart_navigation

Purpose: Moves the terminal to the project directory.

Where to run: PowerShell or VS Code terminal.

Note: Replace the example path with the actual location of the cloned project if necessary.

3. Download Project Dependencies

flutter pub get

Purpose: Downloads the packages required by the project.

Where to run: Inside the project folder.

4. Clean Previous Build Files

flutter clean

Purpose: Removes generated build files to help resolve stale-build and compilation issues.

Where to run: Inside the project folder.

5. Analyze the Source Code

flutter analyze

Purpose: Identifies Dart code errors, warnings, and potential quality issues.

Where to run: Inside the project folder.

6. Run Automated Tests

flutter test

Purpose: Executes the automated tests available in the project.

Where to run: Inside the project folder.

7. Check Connected Devices

flutter devices

Purpose: Lists the Android phones, emulators, and other devices available to Flutter.

Where to run: PowerShell or VS Code terminal.

8. Run the Application in Debug Mode

flutter run

Purpose: Builds and launches the application for development and debugging.

Where to run: Inside the project folder.

9. Run the Application in Release Mode

flutter run --release

Purpose: Runs the application in release mode to evaluate its performance on a target device.

Where to run: Inside the project folder, with a compatible device connected.

10. Build the Release APK

flutter build apk --release

Purpose: Generates an installable Android APK for distribution and testing.

Where to run: Inside the project folder.

Output location:

build/app/outputs/flutter-apk/app-release.apk

11. Check Android Devices Using ADB

adb devices

Purpose: Checks whether Android Debug Bridge can communicate with connected Android devices.

Where to run: PowerShell or VS Code terminal.

12. Install or Update the APK

adb install -r "build/app/outputs/flutter-apk/app-release.apk"

Purpose: Installs the generated APK or reinstalls it over an existing version.

Where to run: Inside the project folder, after building the APK.

13. Build Separate APKs for Different CPU Architectures

flutter build apk --split-per-abi --release

Purpose: Generates architecture-specific APKs that can reduce download size for compatible devices.

Where to run: Inside the project folder.

Output location:

build/app/outputs/flutter-apk/

14. Build an Android App Bundle

flutter build appbundle --release

Purpose: Generates an Android App Bundle for publishing through Google Play.

Where to run: Inside the project folder.

Output location:

build/app/outputs/bundle/release/app-release.aab

## 🚀 Recommended Build Sequence

Run the following commands in order to prepare a fresh release build.

flutter clean
flutter pub get
flutter analyze
flutter test
flutter devices
flutter build apk --release

After the build succeeds, connect your Android phone and verify the connection:

adb devices

Install the generated APK:

adb install -r "build/app/outputs/flutter-apk/app-release.apk"

## 🔐 Permissions

Depending on the features implemented, the application may require Android permissions for:

Camera access

Microphone access

Location services

Internet connectivity

Vibration

Ensure that the required permissions are declared in the Android configuration and requested appropriately at runtime. Actual permissions depend on the project's implementation.

## 🧪 Testing

The system can be evaluated using the following test cases:

| Test Case | Expected Result |
|---|---|
| Application launch | The application opens successfully |
| Destination input | The entered destination is processed |
| Voice input | Supported voice commands are recognized |
| Route generation | Navigation information is displayed or communicated |
| Obstacle detection | Supported obstacles are identified |
| Audio feedback | Instructions or alerts are communicated correctly |
| Invalid input | Appropriate feedback is provided |
| Error handling | The application handles failures gracefully |

Actual results should be recorded after testing the implemented features.

## 🔮 Future Enhancements

- Improve obstacle detection accuracy.
- Add real-time GPS tracking and route updates.
- Expand voice-command support.
- Introduce offline navigation capabilities.
- Improve accessibility for users with different needs.
- Add emergency contact and location-sharing features.
- Evaluate the system in real-world navigation scenarios.

## 🌍 Applications

- Accessible navigation assistance
- Indoor or outdoor navigation, depending on supported mapping data
- Mobility assistance for visually impaired individuals
- Assistive technology research and development
- Accessible public-space navigation

## 👥 Contributors

- **Afreen Khamar** 
- **Sureekaa Natarajan**
- **Deepika Murugan**


## 🙌 Acknowledgements

We acknowledge the open-source tools, libraries, and technologies that support the development of accessible navigation solutions.

---

**Smart Navigation System** — Towards safer, more accessible, and independent navigation.
