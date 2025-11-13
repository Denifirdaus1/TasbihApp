# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development
```bash
flutter run                    # Run the app in debug mode
flutter pub get               # Install dependencies
flutter clean                 # Clean build artifacts
```

### Code Quality
```bash
flutter analyze               # Run static analysis
flutter test                  # Run all tests
flutter test test/widget_test.dart  # Run specific test file
```

### Build
```bash
flutter build apk             # Build Android APK
flutter build ios             # Build iOS app
```

## Architecture Overview

### Core Architecture Pattern
This is a **Flutter + Supabase** application using **feature-based architecture** with **Riverpod** for state management. The app follows a clean architecture pattern with clear separation between data, domain, and presentation layers.

### Application Bootstrap Flow
- `main.dart` → `bootstrap()` → `ProviderScope` → `SmartTasbihApp`
- `bootstrap()` handles Supabase initialization and notification setup
- `app.dart` creates MaterialApp with theme and auth gate navigation

### State Management (Riverpod)
The app uses a sophisticated Riverpod pattern:

- **Global Providers** (`lib/core/providers/global_providers.dart`):
  - `supabaseClientProvider`: Single Supabase client instance
  - `sessionStreamProvider`: Real-time auth state monitoring
  - `currentUserProvider`: Derived from session for user context

- **Repository Pattern**: Each feature has its own repository provider that depends on `supabaseClientProvider`
- **Stream-based Data**: Extensive use of `StreamProvider` for real-time Supabase data
- **Auto-dispose**: Controllers automatically dispose when not needed

### Feature Structure
```
features/
├── auth/                    # Google OAuth authentication
├── dzikir/                  # Prayer counter with batching
├── prayer_circles/          # Community prayer circles
├── profile/                 # User profiles and badges
├── dashboard/               # Main dashboard with Zikir Tree
├── home/                    # Navigation shell
└── recommendations/         # Mood-based zikir recommendations
```

Each feature follows layered architecture:
```
feature_name/
├── data/                    # Repository implementations
├── domain/                  # Models and business logic
└── presentation/            # UI screens and providers
```

### Supabase Integration

**Authentication**:
- Google OAuth with PKCE flow
- Auto-profile creation via PostgreSQL trigger
- Real-time auth state monitoring via `onAuthStateChange`

**Database**:
- Real-time subscriptions on `circle_goals` table
- RPC functions for atomic operations (e.g., `increment_goal_count`)
- Proper primary key configuration for efficient streams

**Configuration**: Supabase credentials in `lib/core/config/app_config.dart`

### Key Architectural Patterns

**Repository Pattern**:
```dart
class FeatureRepository {
  FeatureRepository(this._client);  // SupabaseClient injection

  Future<List<Model>> fetchItems(String userId);
  Stream<List<Model>> watchItems(String id);
  // Feature-specific methods
}
```

**Zikir Counter State Management**:
- Complex StateNotifier with **debounced sync** (3-second delay)
- **Batch processing** (increment by 10 taps or 3 seconds)
- **Offline support** with pending counts
- **Circle integration** for collective prayer goals

**Navigation Flow**:
```
App Start → AuthGate → Session Check →
  ├─ No Session: SignInScreen (Google OAuth)
  └─ Has Session: HomeShell (Bottom Navigation)
```

### Database Setup Required

Before running the app, execute SQL from:
- `App_Knowledge/Main_schema_tabel.md` - Creates all tables and RLS policies
- `App_Knowledge/Project.md` - Auth trigger for auto-profile creation
- `App_Knowledge/solution.md` - RPC functions for batching operations

### Key Files for Understanding
- `bootstrap.dart` - App initialization and Supabase setup
- `global_providers.dart` - Central state management configuration
- `auth_gate.dart` - Authentication flow routing
- `zikir_counter_controller.dart` - Complex StateNotifier pattern example
- `async_value_widget.dart` - Reusable async state handling widget

### Critical Implementation Details

**Zikir Counter Batching**:
- Uses debounced sync to prevent excessive database calls
- Updates are batched (every 10 taps or 3 seconds of inactivity)
- Implements lifecycle management to prevent data loss
- Integrates with prayer circle goals via RPC calls

**Real-time Features**:
- Prayer circles use Supabase Realtime for live progress updates
- Authentication state is monitored via streams
- Database changes trigger automatic UI updates

**Cross-Feature Communication**:
- User context available globally via `currentUserProvider`
- Shared dependencies on central Supabase client
- Goal integration between dzikir counter and prayer circles