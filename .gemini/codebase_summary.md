# Habo (Mebo) - Codebase Summary

## 📋 Project Overview

**Habo** (branded as **Mebo** in the UI) is an **open-source habit tracking application** built with **Flutter**. It's a comprehensive habit management system with advanced features including:

- ✅ Multiple habit types (Boolean, Numeric, Diary, Money Tracker, Meter)
- ⏰ 24-hour temporary tasks with Instagram Stories-style UI
- 🏙️ GitVille - Visual city generation based on habit completion
- 📊 Statistics and progress tracking
- 🔔 Smart notifications
- 🌓 Dark/Light theme support with Material You
- 🔐 Biometric authentication
- 📱 Home widgets
- 🗃️ Category organization
- 💾 Backup/Restore functionality
- 🌍 Multi-language support (via Weblate)

---

## 🏗️ Architecture Overview

### Core Architecture Pattern

The app follows a **Provider-based state management** pattern with **repository pattern** for data access:

```
UI Layer (Screens/Widgets)
    ↓
Provider (State Management)
    ↓
Manager Layer (Business Logic)
    ↓
Repository Layer (Data Access)
    ↓
Database (SQLite)
```

### Key Components

#### 1. **State Management**

- **AppStateManager**: Navigation state
- **SettingsManager**: App settings and preferences
- **HabitsManager**: Habit business logic and operations

#### 2. **Data Layer**

- **HaboModel**: SQLite database management
- **Repositories**: Abstract data access (Habit, Event, Category, Backup)
- **SQLite Implementations**: Concrete repository implementations

#### 3. **Services (Dependency Injection via ServiceLocator)**

- **BackupService**: Import/Export functionality
- **NotificationService**: Notification scheduling
- **UIFeedbackService**: User feedback (SnackBars)
- **BiometricAuthService**: Fingerprint/Face authentication
- **HomeWidgetService**: Widget updates

---

## 📁 Directory Structure

```
lib/
├── constants.dart                 # App-wide constants (colors, enums)
├── main.dart                      # App entry point
├── themes.dart                    # Theme definitions
├── extensions.dart                # Dart extensions
├── helpers.dart                   # Utility functions
│
├── habits/                        # Habit-related UI
│   ├── habit.dart                 # Habit widget (calendar view)
│   ├── habits_manager.dart        # Habit business logic
│   ├── habits_screen.dart         # Main habits screen
│   ├── edit_habit_screen.dart     # Create/Edit habit form
│   ├── diary_entry_screen.dart    # Grid diary entry UI
│   ├── calendar_column.dart       # Main calendar list
│   ├── calendar_header.dart       # Week day header
│   └── one_day.dart               # Single day cell
│
├── model/                         # Data models
│   ├── habo_model.dart            # Database operations
│   ├── habit_data.dart            # Habit data model
│   ├── category.dart              # Category model
│   ├── backup.dart                # Backup data structure
│   └── settings_data.dart         # Settings model
│
├── repositories/                  # Data access layer
│   ├── repository_factory.dart    # Factory pattern
│   ├── habit_repository.dart      # Abstract habit repo
│   ├── event_repository.dart      # Abstract event repo
│   ├── category_repository.dart   # Abstract category repo
│   ├── backup_repository.dart     # Abstract backup repo
│   └── sqlite_*.dart              # SQLite implementations
│
├── services/                      # Business services
│   ├── service_locator.dart       # DI container
│   ├── backup_service.dart        # Backup logic
│   ├── notification_service.dart  # Notification logic
│   ├── ui_feedback_service.dart   # UI feedback
│   ├── biometric_auth_service.dart # Auth logic
│   └── home_widget_service.dart   # Widget updates
│
├── navigation/                    # Routing
│   ├── app_router.dart            # Router delegate
│   ├── app_state_manager.dart     # Navigation state
│   ├── routes.dart                # Route constants
│   └── route_information_parser.dart
│
├── widgets/                       # Reusable widgets
│   ├── hour_24_stories.dart       # 24h tasks story circles
│   ├── story_detail_modal.dart    # Story detail dialog
│   ├── money_input_modal.dart     # Money tracker input
│   ├── meter_input_modal.dart     # Meter input
│   ├── progress_input_modal.dart  # Numeric progress input
│   ├── category_filter_row.dart   # Category filter chips
│   ├── biometric_auth_wrapper.dart # Auth wrapper
│   └── week_view_widget.dart      # Week overview
│
├── location/                      # GitVille feature
│   ├── location_screen.dart       # GitVille screen
│   ├── city_generator.dart        # City data generation
│   ├── local_server.dart          # Local asset server
│   └── gitville/                  # GitVille web assets
│       ├── web/                   # HTML/JS/CSS
│       └── data/                  # Generated city data
│
├── statistics/                    # Analytics
│   ├── statistics_screen.dart     # Stats page
│   ├── statistics.dart            # Stats calculations
│   ├── statistics_card.dart       # Individual stat cards
│   └── monthly_graph.dart         # Monthly chart
│
├── settings/                      # Settings
│   ├── settings_screen.dart       # Settings UI
│   └── settings_manager.dart      # Settings logic
│
├── onboarding/                    # First-time experience
│   └── onboarding_screen.dart
│
├── whats_new/                     # Release notes
│   └── whats_new_screen.dart
│
└── generated/                     # Auto-generated
    └── l10n.dart                  # Localization
```

---

## 🎯 Core Features Deep Dive

### 1. **Habit Types**

#### Boolean Habits

- Simple check/skip/fail tracking
- Two-day rule support (allows one missed day)
- Streak calculation

#### Numeric Habits (Progress)

- Track progress toward a target (e.g., "Read 100 pages")
- Visual progress indicators
- Partial completion tracking

#### Diary Habits

- **Grid diary layout** with custom questions
- JSON storage of multi-question entries
- Visual fill indicator showing completion percentage
- Questions defined per habit

#### Money Tracker (Savings)

- Track wallet balance (not savings goal)
- Add/subtract amounts daily
- Min/Max balance tracking
- Piggy bank icon visualization

#### Meter Habits

- Rate-based tracking (e.g., "Rate your mood 1-10")
- Custom min/max values
- Optional labels for scale points
- Visual meter display

### 2. **24-Hour Tasks (Stories Feature)**

**Instagram Stories-inspired temporary tasks:**

- Tasks auto-delete after 24 hours
- Circular progress ring showing time remaining
- Color-coded by urgency (green → orange → red)
- Actions:
  - **Tap**: Open detail modal
  - **Long press**: Edit task
  - **Complete**: Records stats, deletes task
  - **Skip**: Records skip, deletes task
- Description field for context
- Displayed prominently at top of home screen

**Implementation Details:**

- `is24Hour` flag in `HabitData`
- `createdAt` timestamp for age calculation
- Automatic cleanup via `_deleteExpired24HourHabits()` in `HabitsManager`
- Filtered from main habit list (`calendar_column.dart`)

### 3. **GitVille City Generation**

**Visual representation of habit data as a virtual city:**

#### How It Works:

1. Collects all unique dates with habit events across all habits
2. Sorts dates chronologically (oldest → newest)
3. Generates grid layout with:
   - **Center (0,0)**: User's house (gold, always has terrace)
   - **Surrounding**: One house per date
4. Each house's attributes are **deterministically seeded by date**:
   - Color (HSV color generation)
   - Roof style (0-2)
   - Door style (0-2)
   - Window style (0-2)
   - Chimney style (0-2)
   - Wall style (0-2)
5. **House quality depends on habits completed that day**:
   - **Terrace**: 3+ habits completed OR any diary filled
   - **Abandoned**: Any habit failed that day
   - **Facing**: Based on grid position

#### Key Files:

- `city_generator.dart`: City data generation logic
- `location_screen.dart`: WebView wrapper
- `local_server.dart`: Local HTTP server for assets
- `gitville/web/`: HTML/JS rendering (isometric view)

**Data Flow:**

```
Habits → City Generator → JSON → Local Server → WebView
```

### 4. **Database Schema**

**SQLite Database (Version 11):**

#### Tables:

**habits**

```sql
id, position, title, twoDayRule, cue, routine, reward, showReward,
advanced, notification, notTime, sanction, showSanction, accountant,
habitType, targetValue, partialValue, unit, questions, meterMin,
meterMax, meterLabels, archived, is24Hour, description, createdAt
```

**events**

```sql
id, date, event (JSON array: [DayType, comment?, value?])
```

**categories**

```sql
id, title, iconCodePoint, fontFamily
```

**habit_categories** (Junction table)

```sql
habitId, categoryId
```

#### Event Structure:

Events are stored as JSON arrays:

- `[DayType.check, "comment"]` - Boolean completion
- `[DayType.fail, "comment"]` - Failure
- `[DayType.skip, "comment"]` - Skip
- `[DayType.progress, "comment", value]` - Numeric progress
- `[DayType.diary, "{JSON}"]` - Diary entry
- `[DayType.savings, "comment", balance]` - Money tracker
- `[DayType.meter, "comment", value]` - Meter rating

### 5. **Navigation System**

**Router 2.0 Pattern:**

- `AppRouter` (RouterDelegate): Main router
- `HaboRouteInformationParser`: URL parsing
- `AppStateManager`: Navigation state
- **Pages-based navigation** (declarative)

**Routes:**

- `/` - Main habits screen
- `/statistics` - Statistics
- `/settings` - Settings
- `/create` - Create habit
- `/edit` - Edit habit
- `/location` - GitVille
- `/whatsnew` - Release notes

### 6. **Notification System**

**Features:**

- Per-habit scheduled notifications
- Time-based reminders
- Smart notification messages (contextual)
- Permission handling
- Reset/refresh capabilities

**Implementation:**

- `awesome_notifications` package
- `NotificationService` for scheduling
- Stored in habit data (`notification`, `notTime`)

---

## 🔄 Data Flow Examples

### Creating a Habit

```
EditHabitScreen
  → User inputs data
  → Validates form
  → HabitsManager.addHabit()
    → Creates Habit object
    → HabitRepository.insertHabit()
      → HaboModel.insertHabit()
        → SQLite INSERT
    → Updates UI (notifyListeners)
    → Schedules notification
    → Updates home widget
```

### Marking a Day

```
OneDayButton (tap)
  → Shows input modal (if numeric/meter/etc)
  → HabitsManager.addEvent()
    → EventRepository.insertEvent()
      → HaboModel.insertEvent()
        → SQLite INSERT/UPDATE
    → Habit.refresh() (updates streak)
    → notifyListeners()
    → Updates home widget
```

### GitVille Generation

```
LocationScreen.initState()
  → Starts LocalAssetServer (copies web assets)
  → CityGenerator.generateAndSave(habits)
    → Collects all event dates
    → Generates city layout
    → Creates house data per date
    → Writes JSON to gitville/data/
  → WebView loads local server
  → JS reads JSON, renders isometric city
```

---

## 🎨 UI/UX Highlights

### Design Philosophy

- **Material Design 3** with dynamic colors
- **Minimalistic** and clean interface
- **Gesture-driven** interactions
- **Responsive** layouts

### Key UI Components

**Home Screen (`HabitsScreen`):**

- App bar: Logo, Location, Archive, Statistics, Settings
- Calendar header (week days)
- **24-hour stories row** (horizontal scrollable)
- **Category filter chips** (optional)
- **Reorderable habit list** (drag to reorder)
- FAB: Create new habit

**Habit Card (`Habit` widget):**

- Expandable calendar view
- Month navigation
- Custom markers per habit type:
  - Boolean: Checkmark/X
  - Numeric: Progress bar
  - Diary: Grid icon with fill indicator
  - Money: Piggy bank with balance
  - Meter: Gauge icon
- Streak counter
- Long-press to edit

**24-Hour Story Circle:**

- Progress ring (shows time elapsed)
- Color coding (green/orange/red)
- Time remaining badge
- Tap → Detail modal
- Long press → Edit

**Category Filter:**

- Horizontal chip selector
- Filter habits by category
- "All" chip to show everything

---

## 🔧 Technical Details

### State Management

- **Provider** package for dependency injection
- **ChangeNotifier** pattern
- Separate managers for concerns (Habits, Settings, AppState)

### Database

- **sqflite** for mobile platforms
- **sqflite_common_ffi** for desktop
- Migration system (v1 → v11)
- SplayTreeMap for sorted event storage

### Persistence

- **SQLite** for habits/events/categories
- **SharedPreferences** for settings
- **File system** for backups (JSON export)

### Localization

- **flutter_localizations** + **intl**
- **flutter_intl** code generation
- **Weblate** integration for community translations
- `S.of(context)` for translated strings

### Theming

- Light/Dark mode
- Material You (dynamic colors)
- Custom theme presets
- Per-habit custom colors

### Performance

- **Lazy loading** of month data
- **Efficient event queries** (by date range)
- **Widget context caching** for updates
- **Debounced home widget updates**

---

## 🚀 Key Workflows

### Day Change Detection

```dart
// main.dart
_startDayChangeTimer() {
  // Calculates time until next midnight
  // Triggers HabitsManager.checkDayChange()
  // Deletes expired 24-hour habits
  // Updates UI
}
```

### Backup/Restore

```dart
// BackupService
createBackup() {
  → Exports all habits, events, categories to JSON
  → Saves to file system (with timestamp)
}

loadBackup() {
  → Reads JSON file
  → Validates structure
  → Clears existing data
  → Imports new data
  → Rebuilds database
}
```

### Statistics Calculation

```dart
// Statistics.dart
calculateStats() {
  → Iterates all habits and events
  → Counts completions, fails, skips
  → Calculates streaks (current, best)
  → Groups by month/year
  → Returns aggregated data
}
```

---

## 📦 Dependencies (Key Packages)

**UI:**

- `flutter` (SDK)
- `google_fonts` - Typography
- `fl_chart` - Charts/graphs
- `awesome_dialog` - Dialogs
- `table_calendar` - Calendar widget
- `flutter_svg` - SVG rendering
- `percent_indicator` - Progress indicators

**State:**

- `provider` - State management

**Data:**

- `sqflite` / `sqflite_common_ffi` - SQLite
- `shared_preferences` - Settings
- `path_provider` - File paths

**Features:**

- `awesome_notifications` - Notifications
- `local_auth` - Biometrics
- `home_widget` - Home screen widgets
- `webview_flutter` - WebView (GitVille)
- `shelf` / `shelf_static` - Local server

**Utilities:**

- `intl` - Internationalization
- `url_launcher` - External links
- `package_info_plus` - App version
- `file_picker` / `flutter_file_dialog` - File I/O
- `dynamic_color` - Material You colors

---

## 🐛 Known Issues & Notes

### From Conversation History:

1. **GitVille Export Issue**: Location screen fails to load in exported APK (likely asset path issue)
2. **Statistics Loading**: Infinite loading states (appears resolved)
3. **Layout Adjustments**: Money tracker modal overflow issues (resolved)
4. **24-Hour Tasks**: Implemented with auto-deletion mechanism

### Code Comments:

- Onboarding is **disabled** in current version
- "What's New" screen is **disabled** for clean launch
- App router intentionally does NOT listen to HabitsManager changes (prevents navigation glitches)

---

## 🔐 Security & Privacy

- **Biometric authentication** option (fingerprint/face)
- **Local-only data** (no cloud sync)
- **File-based backups** (user controlled)
- **No analytics** or tracking
- **No network permissions** (except for GitHub API in GitVille context, if used)

---

## 🌟 Unique Features

1. **24-Hour Stories**: Temporary tasks with visual countdown
2. **GitVille**: Gamified visualization as a city
3. **Grid Diary**: Multi-question diary with grid layout
4. **Money Tracker**: Balance tracking (not just savings)
5. **Meter Habits**: Custom rating scales
6. **Category System**: Organize and filter habits
7. **Two-Day Rule**: Forgiveness for occasional misses
8. **Home Widgets**: At-a-glance habit status

---

## 📝 Code Quality

- **Type-safe** Dart code
- **Null safety** enabled
- **Repository pattern** for data access
- **Service locator** for DI
- **Widget composition** for reusability
- **Separation of concerns** (UI/Logic/Data)
- **Future-proof migrations** (database versioning)

---

## 🎓 Learning Points

This codebase demonstrates:

- ✅ Proper Flutter architecture (Provider + Repositories)
- ✅ SQLite database management with migrations
- ✅ Complex UI with custom painters and animations
- ✅ File I/O and backup systems
- ✅ Local HTTP server for web content
- ✅ Notification scheduling
- ✅ Biometric authentication
- ✅ Multi-language support
- ✅ Theme management
- ✅ Home widget integration
- ✅ Reorderable lists
- ✅ Modal bottom sheets and dialogs
- ✅ Date/time calculations
- ✅ JSON serialization
- ✅ Gesture detection

---

## 🔮 Potential Enhancements

Based on the codebase structure:

1. **Cloud sync** (optional, encrypted)
2. **Habit templates** (pre-built habit sets)
3. **Social features** (share achievements)
4. **Advanced analytics** (predictive insights)
5. **Habit dependencies** (one habit unlocks another)
6. **Custom themes** (user-created color schemes)
7. **API integration** (external data sources)
8. **Desktop optimization** (already supports Windows/Linux/macOS)
9. **Habit groups** (morning routine, evening routine, etc.)
10. **Voice commands** (accessibility)

---

## 📞 Contact & Community

- **GitHub**: `xpavle00/Habo`
- **License**: GPL-3.0
- **Translations**: Weblate
- **App Store**: Available on Play Store, IzzyOnDroid, iOS App Store

---

_Last Updated: 2026-01-23_
_Codebase Version: 3.1.1+1_
