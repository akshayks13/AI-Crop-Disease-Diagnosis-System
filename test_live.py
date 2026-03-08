"""Live Render endpoint tests — register + ML diagnosis."""
import urllib.request
import urllib.error
import json
import io
import mimetypes
import os
import uuid

BASE = "https://ai-crop-disease-diagnosis-system-aumh.onrender.com"


def req(method, path, body=None, token=None, timeout=30):
    data = json.dumps(body).encode() if body else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    r = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(r, timeout=timeout) as resp:
            return resp.status, json.loads(resp.read())
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read())
        except Exception:
            return e.code, {}
    except Exception as exc:
        return 0, {"error": str(exc)}


def req_multipart(path, fields, files, token, timeout=60):
    """POST multipart/form-data with one or more file fields."""
    boundary = uuid.uuid4().hex
    body_parts = []
    for name, value in fields.items():
        body_parts.append(
            f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"\r\n\r\n{value}\r\n'
            .encode()
        )
    for name, (filename, data, ctype) in files.items():
        body_parts.append(
            f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"; filename="{filename}"\r\nContent-Type: {ctype}\r\n\r\n'
            .encode() + data + b"\r\n"
        )
    body_parts.append(f"--{boundary}--\r\n".encode())
    body = b"".join(body_parts)
    headers = {
        "Content-Type": f"multipart/form-data; boundary={boundary}",
        "Authorization": f"Bearer {token}",
    }
    r = urllib.request.Request(BASE + path, data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(r, timeout=timeout) as resp:
            return resp.status, json.loads(resp.read())
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read())
        except Exception:
            return e.code, {}
    except Exception as exc:
        return 0, {"error": str(exc)}


def section(title):
    print(f"\n{'='*55}")
    print(f"  {title}")
    print("=" * 55)


# ── 1. Health ───────────────────────────────────────────────
section("1. Health")
s, d = req("GET", "/health")
print(f"  HTTP {s}  {d}")

# ── 2. Login farmer1 (get token) ────────────────────────────
section("2. Login farmer1@example.com")
s, d = req("POST", "/auth/login", {"email": "farmer1@example.com", "password": "farmer123"})
print(f"  HTTP {s}")
token = None
if s == 200:
    token = d.get("access_token")
    user = d.get("user", {})
    print(f"  Token:  {str(token)[:50]}...")
    print(f"  User:   {user.get('email')}  role={user.get('role')}  status={user.get('status')}")
else:
    print(f"  FAILED: {json.dumps(d)[:300]}")

# ── 3. Register new user ─────────────────────────────────────
section("3. Register new user (background OTP)")
new_email = "rendertest_march08@example.com"
s, d = req(
    "POST",
    "/auth/register",
    {"email": new_email, "password": "Test1234!", "full_name": "BG Tester", "role": "FARMER"},
    timeout=30,
)
print(f"  HTTP {s}  (should be 201, instant)")
print(f"  Body: {json.dumps(d)[:300]}")

# ── 4. Re-register same email (unverified re-send) ───────────
section("4. Re-register same email (re-send OTP path)")
s, d = req(
    "POST",
    "/auth/register",
    {"email": new_email, "password": "Test1234!", "full_name": "BG Tester", "role": "FARMER"},
    timeout=30,
)
print(f"  HTTP {s}  (should be 201, instant)")
print(f"  Body: {json.dumps(d)[:300]}")

# ── 5. Register duplicate verified email ────────────────────
section("5. Register duplicate verified email (farmer1)")
s, d = req(
    "POST",
    "/auth/register",
    {"email": "farmer1@example.com", "password": "any", "full_name": "Dup", "role": "FARMER"},
    timeout=15,
)
print(f"  HTTP {s}  (should be 409 Conflict)")
print(f"  Body: {json.dumps(d)[:200]}")

if not token:
    print("\n  SKIPPING ML test — no token")
    raise SystemExit(1)

# ── 6. ML diagnosis (file upload) ────────────────────────────
section("6. ML Diagnosis  /diagnosis/predict  (apple_scab.jpeg)")
local_img = "/Users/akshayks/Desktop/SE_Proj/apple_scab.jpeg"
with open(local_img, "rb") as f:
    img_bytes = f.read()
print(f"  Using apple_scab.jpeg ({len(img_bytes)} bytes)")

try:
    s, d = req_multipart(
        "/diagnosis/predict",
        fields={"crop_type": "general"},
        files={"file": ("apple_scab.jpeg", img_bytes, "image/jpeg")},
        token=token,
        timeout=120,
    )
    print(f"  HTTP {s}")
    if s == 200:
        print(f"  disease:    {d.get('disease_name') or d.get('disease') or d.get('prediction')}")
        print(f"  confidence: {d.get('confidence')}")
        print(f"  model_used: {d.get('model_used') or d.get('model')}")
        print(f"  severity:   {d.get('severity')}")
        print(f"  Keys:       {list(d.keys())}")
    else:
        print(f"  Body: {json.dumps(d)[:500]}")
except Exception as exc:
    print(f"  ERROR: {exc}")

# ── 7. ML diagnosis endpoint (no token) ──────────────────────
section("7. ML Diagnosis without token (auth guard)")
s, d = req("POST", "/diagnosis/predict", timeout=15)
print(f"  HTTP {s}  (should be 401/422)")

print("\n" + "=" * 55)
print("  ALL TESTS DONE")
print("=" * 55 + "\n")
