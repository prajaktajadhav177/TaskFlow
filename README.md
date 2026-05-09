# ⚡ TaskFlow — Team Task Manager

> A full-stack Flutter app for managing projects, assigning tasks, and tracking team progress with role-based access control.

---

## 📱 Live Demo

| Platform | Link |
|----------|-------|
| 🌐 Web (Chrome) | `https://your-deployed-url.web.app` |
| 🤖 Android APK | Available in releases |

### Demo Credentials

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@taskflow.com | admin123 |
| Member | member@taskflow.com | member123 |

---

## 🎥 Demo Video

[Watch 3-minute demo →](https://your-video-link-here)

---

## ✨ Features

### 🔐 Authentication
- Email & password signup / login
- Role selection at signup (Admin / Member)
- Persistent sessions — stays logged in on app restart
- Password reset via email
- Real-time role sync (no re-login needed after role change)

### 👥 Role-Based Access Control
| Feature | Admin | Member |
|---------|-------|--------|
| Create projects | ✅ | ❌ |
| Delete projects | ✅ | ❌ |
| Add/remove members | ✅ | ❌ |
| Create tasks | ✅ | ❌ |
| Update task status | ✅ | ✅ |
| Add comments | ✅ | ✅ |
| View all tasks | ✅ | ✅ (own projects only) |

### 📁 Project Management
- Create projects with custom icon, color, and deadline
- Real-time progress tracking (completed / total tasks)
- Project status: Active, Completed, Archived
- Overdue detection with visual alerts
- Member avatars and role display

### ✅ Task Management
- Create tasks with title, description, priority, status, tags
- Assign tasks to team members
- Due date with overdue highlighting
- Sub-tasks with individual completion tracking
- Estimated hours tracking
- Priority levels: Low, Medium, High, Critical

### 💬 Collaboration
- Real-time comments on tasks
- Member management (add/remove by email search)
- Role badges (Admin / Member)

### 📊 Dashboard
- Personal stats: Projects, Tasks, Completed, Overdue
- Donut chart — task breakdown by status
- Overall progress ring indicator
- Pending tasks list
- Overdue tasks alert section

### 👤 Profile
- Stats overview
- Edit profile
- Sign out with confirmation

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) |
| State Management | GetX |
| Backend | Firebase (Firestore + Auth) |
| Database | Cloud Firestore (NoSQL) |
| Authentication | Firebase Auth |
| Charts | fl_chart |
| Fonts | Google Fonts (Syne + Space Grotesk) |
| Navigation | GetX routing |

---

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point, Firebase init
├── firebase_options.dart        # Platform Firebase config
│
├── models/
│   ├── user_model.dart          # User data model
│   ├── project_model.dart       # Project + ProjectMember models
│   └── task_model.dart          # Task + SubTask + Comment models
│
├── services/
│   ├── auth_service.dart        # Firebase Auth operations
│   ├── project_service.dart     # Firestore project CRUD + streams
│   ├── task_service.dart        # Firestore task CRUD + streams
│   └── app_controller.dart      # GetX global state controller
│
├── screens/
│   ├── splash_screen.dart       # Launch screen with auth check
│   ├── login_screen.dart        # Email/password login
│   ├── signup_screen.dart       # Registration with role picker
│   ├── home_screen.dart         # Bottom nav shell
│   ├── dashboard_screen.dart    # Stats + charts overview
│   ├── projects_screen.dart     # Project list with filters
│   ├── project_detail_screen.dart # Tasks, Members, Overview tabs
│   ├── create_project_screen.dart # New project form
│   ├── create_task_screen.dart  # New task form
│   ├── task_detail_screen.dart  # Task view + comments + subtasks
│   ├── my_tasks_screen.dart     # Personal task board
│   ├── tasks_screen.dart        # All tasks with search
│   ├── manage_members_screen.dart # Add/remove project members
│   └── profile_screen.dart      # User profile + settings
│
└── utils/
    └── app_theme.dart           # Dark theme, colors, constants
```

---

## 🗄️ Database Schema (Firestore)

### `users/{uid}`
```json
{
  "name": "string",
  "email": "string",
  "role": "admin | member",
  "projectIds": ["projectId1", "projectId2"],
  "isOnline": true,
  "createdAt": "timestamp",
  "photoUrl": null
}
```

### `projects/{projectId}`
```json
{
  "name": "string",
  "description": "string",
  "ownerId": "uid",
  "ownerName": "string",
  "memberIds": ["uid1", "uid2"],
  "members": [{ "uid": "", "name": "", "email": "", "role": "" }],
  "color": "#6C63FF",
  "icon": "🚀",
  "status": "active | completed | archived",
  "totalTasks": 0,
  "completedTasks": 0,
  "deadline": "timestamp | null",
  "createdAt": "timestamp"
}
```

### `tasks/{taskId}`
```json
{
  "title": "string",
  "description": "string",
  "projectId": "string",
  "projectName": "string",
  "creatorId": "uid",
  "assigneeId": "uid | null",
  "assigneeName": "string | null",
  "status": "todo | in_progress | review | done",
  "priority": "low | medium | high | critical",
  "tags": ["tag1", "tag2"],
  "subTasks": [{ "id": "", "title": "", "isDone": false }],
  "comments": [{ "id": "", "authorId": "", "text": "", "createdAt": "" }],
  "dueDate": "timestamp | null",
  "completedAt": "timestamp | null",
  "estimatedHours": 0,
  "createdAt": "timestamp"
}
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Firebase project (free Spark plan works)
- Android Studio / VS Code
- FlutterFire CLI

### 1. Clone the repository
```bash
git clone https://github.com/yourusername/taskflow.git
cd taskflow
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Setup Firebase

**a) Create a Firebase project** at [console.firebase.google.com](https://console.firebase.google.com)

**b) Enable services:**
- Authentication → Email/Password ✅
- Firestore Database → Start in test mode ✅

**c) Install FlutterFire CLI & configure:**
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
Select your project → check ✅ Android + ✅ Web
This auto-generates `lib/firebase_options.dart`

### 4. Firestore Security Rules
In Firebase Console → Firestore → Rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /projects/{projectId} {
      allow read: if request.auth != null &&
        request.auth.uid in resource.data.memberIds;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null &&
        request.auth.uid == resource.data.ownerId;
    }
    match /tasks/{taskId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 5. Run the app

```bash
# Android emulator
flutter run -d emulator-5554

# Chrome (web)
flutter run -d chrome

# Both simultaneously
# Terminal 1:
flutter run -d chrome
# Terminal 2:
flutter run -d emulator-5554
```

---

## 🌐 Deployment (Railway / Firebase Hosting)

### Firebase Hosting (Web)
```bash
# Install Firebase CLI
npm install -g firebase-tools
firebase login

# Initialize hosting
firebase init hosting
# Public directory: build/web
# Single page app: Yes

# Build and deploy
flutter build web --release
firebase deploy
```

### Railway (Backend / if using Node API)
```bash
# Install Railway CLI
npm install -g @railway/cli
railway login
railway init
railway up
```

---

## 📸 Screenshots

| Dashboard | Projects | Task Detail |
|-----------|----------|-------------|
| ![dashboard](screenshots/dashboard.png) | ![projects](screenshots/projects.png) | ![task](screenshots/task.png) |

| Login | Create Project | Profile |
|-------|----------------|---------|
| ![login](screenshots/login.png) | ![create](screenshots/create_project.png) | ![profile](screenshots/profile.png) |

---

## 🐛 Known Issues & Fixes

| Issue | Fix |
|-------|-----|
| Projects not showing | Removed `orderBy` + `arrayContains` combo (requires Firestore index) — now sorts in memory |
| Role shows wrong after signup | Replaced one-time fetch with real-time Firestore stream in `AppController` |
| Firebase duplicate-app crash on hot restart | Added `if (Firebase.apps.isEmpty)` guard in `main.dart` |
| Emulator keyboard not working | Set `windowSoftInputMode="adjustResize"` in AndroidManifest + enable keycode forwarding in emulator settings |

---

## 👨‍💻 Author

**Your Name**
- GitHub: [@prajaktajadhav177](https://github.com/prajaktajadhav177/TaskFlow)
- Email: prajaktajadhav177@gmail.com

---

## 📄 License

This project is licensed under the MIT License.

---

*Built with ⚡ Flutter + Firebase for [Assignment/Hackathon Name]*