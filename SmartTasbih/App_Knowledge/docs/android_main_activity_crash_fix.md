# Fix: `MainActivity` Crash & IDE Errors (SmartTasbih / Flutter Android)

## 1. Context

- Project: Flutter app `SmartTasbih`
- Android module: `android/app`
- Package / namespace:
    - `namespace = "com.smarttasbih.app"` (in `android/app/build.gradle.kts`)
    - `applicationId = "com.smarttasbih.app"`
- Main activity file:
    - Path: `android/app/src/main/kotlin/com/smarttasbih/app/MainActivity.kt`
    - Content:

      ```kotlin
      package com.smarttasbih.app
  
      import io.flutter.embedding.android.FlutterActivity
  
      class MainActivity : FlutterActivity()
      ```

- Manifest file:
    - Path: `android/app/src/main/AndroidManifest.xml`
    - Relevant part:

      ```xml
      <manifest xmlns:android="http://schemas.android.com/apk/res/android">
          <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  
          <application
              android:label="smarttasbih"
              android:name="${applicationName}"
              android:icon="@mipmap/ic_launcher">
  
              <activity
                  android:name=".MainActivity"
                  android:exported="true"
                  android:launchMode="singleTop"
                  android:taskAffinity=""
                  android:theme="@style/LaunchTheme"
                  android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
                  android:hardwareAccelerated="true"
                  android:windowSoftInputMode="adjustResize">
  
                  <meta-data
                      android:name="io.flutter.embedding.android.NormalTheme"
                      android:resource="@style/NormalTheme" />
  
                  <intent-filter>
                      <action android:name="android.intent.action.MAIN" />
                      <category android:name="android.intent.category.LAUNCHER" />
                  </intent-filter>
  
                  <intent-filter android:autoVerify="true">
                      <action android:name="android.intent.action.VIEW" />
                      <category android:name="android.intent.category.DEFAULT" />
                      <category android:name="android.intent.category.BROWSABLE" />
                      <data
                          android:scheme="com.smarttasbih.app"
                          android:host="login-callback" />
                  </intent-filter>
              </activity>
  
              <meta-data
                  android:name="flutterEmbedding"
                  android:value="2" />
          </application>
  
          <queries>
              <intent>
                  <action android:name="android.intent.action.PROCESS_TEXT" />
                  <data android:mimeType="text/plain" />
              </intent>
          </queries>
      </manifest>
      ```

## 2. Problem Summary

### 2.1 Runtime crash (real error)

Saat `flutter run`:

```text
FATAL EXCEPTION: main
Process: com.smarttasbih.app, PID: XXXXX
java.lang.RuntimeException: Unable to instantiate activity ComponentInfo{com.smarttasbih.app/com.smarttasbih.app.MainActivity}:
java.lang.ClassNotFoundException: Didn't find class "com.smarttasbih.app.MainActivity"
