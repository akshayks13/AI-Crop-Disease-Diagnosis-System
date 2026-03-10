# 📱 Running Flutter App on a Real Mobile Device

This guide explains how to run the Flutter mobile application on a physical Android device while the backend runs locally.

## ⚠️ Important Networking Note

When using a real phone:

- **localhost does NOT point to your laptop.**
- **127.0.0.1 does NOT work.**
- You must expose your backend using a public tunnel like ngrok.

---

## 🚀 Step-by-Step Setup (Recommended Method – ngrok)

### 1️⃣ Start the Backend

From the backend folder:

```bash
cd backend
python -m uvicorn app.main:app --port 8000 --reload
```

Verify backend is running:

```
http://localhost:8000/docs
```

### 2️⃣ Install ngrok

Download from:

👉 https://ngrok.com/download

Unzip and add to system PATH (or run from folder).

### 3️⃣ Authenticate ngrok (One-Time Setup)

Sign up:

👉 https://dashboard.ngrok.com/signup

Copy your authtoken and run:

```bash
ngrok config add-authtoken YOUR_AUTHTOKEN
```

### 4️⃣ Expose Backend via ngrok

Run:

```bash
ngrok http 8000
```

You will see:

```
Forwarding  https://random-name.ngrok-free.dev -> http://localhost:8000
```

Copy the HTTPS URL.

**Example:**

```
https://random-name.ngrok-free.dev
```

### 5️⃣ Update Flutter API Base URL

Open:

```
frontend/flutter_app/lib/core/api/api_config.dart
```

Replace:

```dart
static const String baseUrl = 'http://localhost:8000';
```

With:

```dart
static const String baseUrl = 'https://random-name.ngrok-free.dev';
```

⚠️ **No trailing slash.**

### 6️⃣ Clean & Run Flutter

```bash
cd frontend/flutter_app
flutter clean
flutter pub get
flutter run --dart-define=BASE_URL= < update url from ngrok > 
```

Select your connected Android device.

### 7️⃣ Allow ngrok Warning Page (First Time Only)

When opening in phone browser:

```
https://random-name.ngrok-free.dev/docs
```

Click "Visit Site" once to bypass ngrok warning.

---

## ✅ Verify Everything Works

Open on phone browser:

```
https://random-name.ngrok-free.dev/docs
```

If Swagger loads, the mobile app will work.

---

## 🔁 Alternative Methods (Advanced)

### Option A – Same WiFi Network

1. Connect laptop and phone to same WiFi
2. Start backend with:

```bash
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

3. Use laptop IPv4 address as base URL

⚠️ **Does NOT work on restricted networks (college/carrier NAT).**

### Option B – Android Emulator

Use special loopback address:

```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

---

## 🧠 Common Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| Login fails | Still using localhost | Update baseUrl |
| Timeout | ngrok not running | Restart ngrok |
| 401 error | Wrong credentials | Check default users |
| CORS error | Middleware missing | Enable CORS in FastAPI |

---

## 🏁 Production Recommendation

For production deployment:

1. Deploy backend to Render / Railway / VPS
2. Replace ngrok URL with deployed HTTPS URL
3. Use environment variables for baseUrl

---

## 🎯 Final Checklist

- ✅ Backend running
- ✅ ngrok running
- ✅ baseUrl updated
- ✅ Flutter cleaned & rebuilt
- ✅ Swagger accessible on phone
