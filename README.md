<<<<<<< HEAD
# 🌟 ALPHABETS — Learn 26 Letters (A–Z)

<p align="center">
  <b>A Modern Full-Stack Platform for Learning the English Alphabet</b>
  <br />
  <i>Interactive Children's Learning App • AI Handwriting Recognition • Admin Management Portal • REST API Backend</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Node.js-18+-339933?style=for-the-badge&logo=node.js&logoColor=white" alt="Node.js" />
  <img src="https://img.shields.io/badge/Express.js-4.x-000000?style=for-the-badge&logo=express&logoColor=white" alt="Express.js" />
  <img src="https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white" alt="MySQL" />
  <img src="https://img.shields.io/badge/React-18-61DAFB?style=for-the-badge&logo=react&logoColor=black" alt="React" />
  <img src="https://img.shields.io/badge/Vite-6.x-646CFF?style=for-the-badge&logo=vite&logoColor=white" alt="Vite" />
  <img src="https://img.shields.io/badge/PyTorch%20%2F%20ONNX-AI%20Recognition-EE4C2C?style=for-the-badge&logo=pytorch&logoColor=white" alt="PyTorch" />
</p>

---

## 📖 Overview

**ALPHABETS** is an end-to-end educational platform that makes learning the 26 English letters interactive, fun and accessible for young children and beginners. It combines a playful Flutter app, an AI handwriting recognition model, a Node.js REST API and a React admin panel.

---

## ✨ Key Features

- 🔤 **Letter Learning:** All 26 letters (A–Z) with phonics sounds, example words, pictures and text-to-speech pronunciation.
- ✍️ **Writing Practice:** Kids trace and write letters on a canvas; an AI model checks the handwriting and gives instant feedback, with a writing history.
- 📚 **Reading & Videos:** Simple reading activities plus alphabet and phonics songs.
- 🎮 **Games & Quizzes:** 15+ mini-games (balloon pop, letter fishing, word ninja, letter train, space letters and more), quizzes, stars and progress tracking.
- 🔐 **User Accounts:** Email/password sign-up and **Continue with Google** sign-in.
- 🖥️ **Admin Dashboard:** Manage learning content, media, videos, game levels and users.
- 🔒 **Secure REST API:** Node.js + Express with JWT authentication, MySQL persistence and Cloudinary media storage.

---

## 📁 Repository Structure

```text
Alphabets/
├── 📱 frontend/              # Flutter app (Android / iOS / Web / Desktop)
│   ├── lib/                  # Screens, widgets, services, models, theme
│   ├── assets/               # Images, audio, icons
│   └── pubspec.yaml          # Flutter dependencies & assets
│
├── ⚙️ backend/               # Node.js + Express REST API
│   ├── server.js             # API entry point
│   ├── src/                  # Controllers, routes, middleware, models, scripts
│   ├── database/             # MySQL / PostgreSQL schemas and seed data
│   └── .env.example          # Environment variable template
│
├── 🖥️ admin-panel/           # React + Vite + TypeScript admin dashboard
│
├── 🧠 ai_model/              # English handwritten letter recognition (CNN)
│   ├── train_english_alphabets.py   # Training script
│   ├── export_english_onnx.py       # Export trained model to ONNX
│   ├── english_best.pth             # Trained PyTorch checkpoint
│   └── english_script_cnn.onnx      # Exported ONNX model
│
└── start_project.bat         # Windows launcher (MySQL + backend + admin panel)
```

---

## 🚀 Quick Start Guide

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.16+)
- [Node.js](https://nodejs.org/) (v18+) & `npm`
- [MySQL Server](https://dev.mysql.com/downloads/mysql/) (v8.0+) or XAMPP
- [Python](https://www.python.org/) (v3.9+) *(optional, only for AI model training)*

> **Windows shortcut:** run `start_project.bat` to start MySQL, the backend and the admin panel together.

---

### 1️⃣ Backend Setup (Node.js & MySQL)

1. Go to the backend folder and install dependencies:
   ```bash
   cd backend
   npm install
   ```

2. Copy `.env.example` to `.env` and fill in your values:
   ```env
   PORT=5000
   DB_HOST=localhost
   DB_PORT=3306
   DB_USER=root
   DB_PASSWORD=your_mysql_password
   DB_NAME=alphabets
   JWT_SECRET=your_jwt_secret_key

   # Google Sign-In (comma-separated OAuth client IDs: web, android, ios)
   GOOGLE_CLIENT_IDS=xxxx.apps.googleusercontent.com
   ```

3. Create and seed the database:
   ```bash
   npm run db:init
   ```

4. Start the development server:
   ```bash
   npm run dev
   ```
   *API:* `http://localhost:5000`

---

### 2️⃣ Admin Panel Setup (React + Vite)

```bash
cd admin-panel
npm install
npm run dev
```
*Dashboard:* `http://localhost:5173`

> **Default Admin Credentials:**
> - **Username:** `superadmin`
> - **Password:** `Admin@123`
>
> Change these before deploying anywhere public.

---

### 3️⃣ Mobile / Web App Setup (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

**Google Sign-In:** create an OAuth **Web application** client in Google Cloud Console and pass its ID when running:

```bash
flutter run -d chrome --web-port 8080 --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
```

- For web, add `http://localhost:8080` (or your chosen port; not 5000, which the backend uses) to the client's **Authorized JavaScript origins**.
- For Android, also create an **Android** OAuth client (package name + SHA-1) and pass the same Web client ID via `--dart-define`.

---

### 4️⃣ AI Handwriting Recognition (Optional)

```bash
cd ai_model
python -m venv .venv
# Windows:
.venv\Scripts\activate
# Linux / macOS:
source .venv/bin/activate
pip install torch torchvision onnx

python train_english_alphabets.py   # train the model
python export_english_onnx.py       # export to ONNX
```

---

## 🛠️ Tech Stack

| Module | Technologies |
| :--- | :--- |
| **Mobile / Web App** | Flutter, Dart, AudioPlayers, Flutter TTS, Video Player, Google Sign-In, CustomPainter |
| **Admin Dashboard** | React 18, TypeScript, Vite, React Router, Lucide Icons, Axios |
| **Backend API** | Node.js, Express.js, MySQL2, JWT, bcrypt, Helmet, Morgan, Multer, Cloudinary |
| **AI / ML Model** | PyTorch, ONNX |
| **Database** | MySQL (PostgreSQL schema also included) |

---

## 🤝 Contributing

Contributions, issues and feature requests are welcome!
See the [Issues](https://github.com/arjunea-tech/Alphabets/issues) page.

1. Fork the project
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **ISC License**.

---

<p align="center">
  Made with ❤️ for young learners by the <b>ALPHABETS Team</b>
</p>
=======

>>>>>>> 352fb8f8d06a1fafc74052ee0337302c5dac9dde
