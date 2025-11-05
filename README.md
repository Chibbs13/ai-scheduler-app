# AI-Powered Todo Scheduler App

A Flutter application for managing tasks and schedules with AI assistance. The app helps you create, organize, and manage todos with the ability to generate tasks from natural language using an AI assistant.

## What It Does

- Create and manage todo items
- Chat with an AI assistant to generate tasks from natural language
- View tasks on a calendar
- Set reminders and notifications
- Organize tasks with tags and categories

## Getting Started

### Prerequisites

- Flutter SDK (>=3.2.3)
- Python 3.8+
- OpenAI API key

### Installation

1. Clone the repository:

```bash
git clone https://github.com/Chibbs13/ai-scheduler-app.git
cd ai-scheduler-app
```

2. Set up the Flutter app:

```bash
cd practice_app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

3. Set up the backend:

```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

4. Create a `.env` file in the `backend/` directory:

```
OPENAI_API_KEY=your_openai_api_key_here
```

### Running the App

1. Start the backend server:

```bash
cd backend
source venv/bin/activate
python app.py
```

2. In a new terminal, run the Flutter app:

```bash
cd practice_app
flutter run
```

The backend runs on `http://localhost:5000` and the Flutter app will connect to it automatically.
