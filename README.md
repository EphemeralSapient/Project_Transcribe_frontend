# Project Transcribe

This is frontend for the given project, it is designed to streamline healthcare operations.
It enables 
    1. Tracking and management of patient details through voice or hand written records.
    2. Use state-of-art transformer based models for OCR, Voice-to-Text and summarization. 
    3. Switch between in-house LLM deployement and cloud service provider instantly.
    4. Maintain patient records with HIPPA and GDPR compliance.

In-house LLM deployement guide can be found on Project Transcribe backend repo.

**Note**: Database and server hosting is required and can be done within locally or cloud provided.

# Project Structure

So far I've ensured the code is maintainable and used LLM for simplifiying, and have designed for
mobile screen as of now.

Everything can be found under `/lib` and within that, each major UI is separated into folders and
sub-files for better readability.

There are 4 major role and screen UI,
    1. Doctor
    2. Pharmacist
    3. Receptionist
    4. Patient

Please do create `.env` file before run and you can refer `example.env` for further reference.

# Getting Started

### Required tools or framework
- [Flutter SDK](https://flutter.dev/docs/get-started/install)

### Installation

1. **Clone the repository:**

   ```sh
   git clone https://github.com/EphemeralSapient/project_transcribe_frontend.git
   cd project_transcribe_frontend
   ```

2. **Get Dependencies:**

   Run the command below to fetch Flutter and Dart package dependencies defined in 

pubspec.yaml

:

   ```sh
   flutter pub get
   ```

3. **Running the App:**

   Choose your target device (e.g., emulator, simulator, or physical device) and run:

   ```sh
   flutter run
   ```

## Build & Deployment

- **Android:** Use Android Studio or run `flutter build apk` from the terminal.
- **iOS/macOS:** Open the respective Xcode workspace and build.
- **Web:** Run `flutter run -d chrome` or `flutter build web`.
- **Desktop (Windows/Linux):** Use the Flutter desktop build command (e.g., `flutter build windows`).


# Demo

Grab the `.apk` file from Github Actions of this repo and use the following 

- **User ID** : Semp
- **Password** : 12345678

# Contact

You can find me on discord by username of `semp1337`