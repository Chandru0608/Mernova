# Flutter platform setup

This package includes the Flutter application source (`lib/` and `pubspec.yaml`). To generate the complete platform folders for your installed Flutter SDK, run `flutter create .` from this app directory. Then replace `android/app/src/main/AndroidManifest.xml` with the contents of `android_manifest_template.xml` (or merge the INTERNET permission and `android:usesCleartextTraffic="true"` attribute into the generated manifest). This keeps generated Gradle files compatible with the Flutter SDK installed on your computer.
