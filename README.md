
# TaskManager Assignment

A brief description of what this project does and who it's for

# TaskFlow — Flodo AI Take-Home Assignment

A full-stack task management app with a **FastAPI + SQLite** backend and **Flutter** frontend.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Python 3.12, FastAPI, SQLAlchemy (async), SQLite |
| Environment | Poetry |
| Frontend | Flutter / Dart |
| State Mgmt | Riverpod |
| HTTP | Dio |
| Local Storage | SharedPreferences (draft persistence) |
| UI Extras | flutter_animate, shimmer, google_fonts |

---

## Getting Started

### Prerequisites
- Python 3.10+
- [Poetry](https://python-poetry.org/docs/#installation)
- Flutter 3.x SDK

---

### 1. Backend

```bash
cd backend

# Install dependencies
poetry install

# Start the server
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API will be live at: **http://localhost:8000**  
Interactive docs: **http://localhost:8000/docs**

---

### 2. Flutter App

```bash
cd flutter_app

# Install packages
flutter pub get

# Run on device/emulator
flutter run

# Android emulator specifically
flutter run -d emulator-5554

# iOS simulator
flutter run -d iPhone
```

> **Note:** For Android emulator, update `lib/services/api_service.dart`:  
> Change `baseUrl` from `http://localhost:8000` → `http://10.0.2.2:8000`

---

## Features

### Core (All Implemented)

| Feature | Details |
|---|---|
| Task Model | Title, Description, Due Date, Status, Blocked By |
| CRUD | Full create, read, update, delete |
| Blocked UI | Greyed-out card with lock icon when blocker is not "Done" |
| Drafts | New task form auto-saves to SharedPreferences; restored on reopen |
| Search | Debounced text search (300ms) — filters by title |
| Filter | Status filter chips: All / To-Do / In Progress / Done |
| 2s Delay | Backend simulates 2-second delay on create & update |
| Loading State | Spinner shown during save; Save button disabled to prevent double-tap |

### Stretch Goal: Debounced Autocomplete Search

- Search input on main screen filters in real-time
- Debounced: API call fires **300ms after the user stops typing**, not on every keystroke
- Implemented via `Timer` cancellation in `TaskListNotifier.updateSearch()`

---

## API Endpoints

```
GET    /tasks/            # List all (supports ?search=&status=)
POST   /tasks/            # Create task (2s delay)
GET    /tasks/{id}        # Get single task
PUT    /tasks/{id}        # Update task (2s delay)
DELETE /tasks/{id}        # Delete task
GET    /health            # Health check
```

---

## Project Structure

```
taskflow/
├── backend/
│   ├── app/
│   │   ├── main.py        # FastAPI app, CORS, lifespan
│   │   ├── models.py      # SQLAlchemy async models + DB setup
│   │   ├── schemas.py     # Pydantic request/response schemas
│   │   └── routes.py      # All CRUD route handlers
│   ├── pyproject.toml     # Poetry config
│   └── poetry.lock
│
├── flutter_app/
│   ├── lib/
│   │   ├── main.dart              # App entry, ProviderScope
│   │   ├── models/
│   │   │   └── task.dart          # Task model + TaskStatus enum
│   │   ├── services/
│   │   │   ├── api_service.dart   # Dio HTTP client
│   │   │   └── draft_service.dart # SharedPreferences draft save/load
│   │   ├── providers/
│   │   │   └── task_provider.dart # Riverpod state + debounce logic
│   │   ├── screens/
│   │   │   ├── task_list_screen.dart  # Main list with search & filter
│   │   │   └── task_form_screen.dart  # Create/edit form
│   │   ├── widgets/
│   │   │   └── task_card.dart    # Task card with blocked state
│   │   └── utils/
│   │       └── app_theme.dart    # Colors, typography, theme
│   └── pubspec.yaml
│
├── run_backend.sh
└── README.md
```

---

## Design Decisions

### Why async SQLAlchemy?
FastAPI is async-first. Using `aiosqlite` + `AsyncSession` means the server never blocks on DB I/O, even during the simulated 2-second delay — the event loop stays free for other requests.

### Simulated delay placement
The `asyncio.sleep(2)` is placed **before** the DB write (not after), so:
1. The Flutter UI shows a spinner immediately
2. The user sees the loading state for the full 2 seconds
3. The DB write happens at the end, keeping data consistency

### Draft persistence
Drafts auto-save on every keystroke via `TextEditingController` listeners. `SharedPreferences` is used for instant synchronous-feeling writes. Draft is cleared only on successful save, so accidental back-swipes or app minimization never lose work.

### Blocked task logic
A task is visually "blocked" if `blocked_by_id != null` AND the blocking task's status is not `"Done"`. The blocking task's status is resolved server-side and returned as `blocked_by_title` in the response. The Flutter card applies a red-tinted border, grey text, and a lock icon.

---

## AI Usage

This project was built with Claude (claude.ai) as the primary AI assistant.

### Prompts that were most helpful

1. **"Build a FastAPI async CRUD API with SQLAlchemy for a Task model..."** — Generated the initial models, schemas, and routes in one pass with clean separation of concerns.

2. **"Create a Riverpod AsyncNotifier that debounces search after 300ms using Timer"** — Produced a clean implementation using `Timer.cancel()` pattern that's idiomatic Dart.

3. **"Design a dark Flutter theme using Plus Jakarta Sans with amber accent, avoiding typical AI purple gradients"** — Got a distinctive navy/amber theme instead of generic purple-on-white.

### Where AI gave bad code / hallucinated

**Issue:** Claude initially placed `asyncio.sleep(2)` *after* `await db.commit()` in the route handlers. This meant the response would take 2 extra seconds after the DB write was already done — the user would see the spinner only during network latency, not a full 2-second wait.

**Fix:** Moved `await asyncio.sleep(2)` to *before* the `db.add(task)` call, so the loading state is visible for the full 2 seconds as the spec requires.

**Issue 2:** Claude generated `DropdownButton` with a `String` type but the `blocked_by_id` field is nullable (`String?`). The widget crashed at runtime because the `null` sentinel value didn't match the non-nullable type.

**Fix:** Typed the dropdown as `DropdownButton<String?>` and added an explicit `null` option as the first item.

### Stretch Goal (Debounced Autocomplete Search) :
## 📁 task_list_screen.dart

- Added debounce support using a timer
- Introduced a `_debounce` field to control delayed execution
- Ensured debounce timer is cancelled in `dispose()` to prevent memory leaks
- Replaced immediate search trigger with a 300 ms debounced call
- Cleared and cancelled debounce when search input is reset
- Passed `searchQuery` (`rawSearch`) into all `TaskCard` usages for highlighting support


## 📁 task_card.dart

- Added a new parameter: `searchQuery` (default: empty string for backward compatibility)
- Refactored title styling into a reusable variable
- Implemented `_buildHighlightedTitle` helper to:
  - Traverse the task title
  - Identify matching substrings based on search query
  - Apply highlight styling (accent color + subtle background)
- Replaced plain title rendering with highlighted rich text
