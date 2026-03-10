# Admin Dashboard Documentation

## 📊 Dashboard Overview

The Admin Dashboard is a **Next.js 16** web application built with **React 19**, **TypeScript**, and **Tailwind CSS**. It provides administrators with tools to manage users, approve experts, monitor system health, and manage content.

---

## 🏗️ Architecture

**Framework**: Next.js 16 (App Router)
**State**: React Server Components + Client Components
**Styling**: Tailwind CSS 4

### Directory Structure (`src/`)

```
src/
├── app/                    # Next.js App Router pages
│   ├── dashboard/          # Main dashboard routes
│   │   ├── page.tsx        # Overview/Metrics
│   │   ├── users/          # User management
│   │   ├── experts/        # Expert approval
│   │   ├── logs/           # System logs
│   │   ├── agronomy/       # Agronomy data management
│   │   └── layout.tsx      # Dashboard shell
│   ├── login/              # Auth page
│   └── layout.tsx          # Root layout
├── components/             # Reusable UI components
│   ├── agronomy/           # Agronomy-specific components
│   ├── charts/             # Recharts visualizations
│   └── shared/             # Buttons, Modals, Tables
├── lib/                    # Utilities
│   └── api.ts              # API client (Axios)
└── types/                  # TypeScript definitions
```

---

## 📦 Key Technologies & Dependencies

### Core Framework
| Package | Version | Purpose |
|---------|---------|---------|
| **next** | 16.1.1 | React framework with SSR, routing, and API routes |
| **react** | 19.2.3 | UI library |
| **typescript** | ^5 | Type safety |

### UI & Styling
| Package | Purpose |
|---------|---------|
| **tailwindcss** | Utility-first CSS framework |
| **lucide-react** | Icon library (modern, tree-shakeable) |
| **recharts** | Data visualization (Charts for metrics) |
| **date-fns** | Date formatting utilities |

### Data Fetching
| Package | Purpose |
|---------|---------|
| **axios** | HTTP client for API requests to FastAPI backend |

### Development Tools
| Package | Purpose |
|---------|---------|
| **eslint** | Linting JavaScript/TypeScript/React |
| **vitest** | Unit testing framework |
| **autoprefixer** | CSS vendor prefixing |

---

## 🔒 Authentication

The dashboard uses **JWT tokens** stored in `localStorage`:
1.  User logs in via `/login`
2.  Backend returns `access_token` (JWT)
3.  Token is stored and sent with every API request via Axios interceptors
4.  Protected routes check for token presence before rendering

---

## 🧪 Testing

**Framework**: Vitest

### Running Tests
```bash
cd frontend/admin_dashboard
npm test              # Run once
npm run test:watch    # Watch mode
```

### Test Coverage
- **API utility tests** (`src/__tests__/api.test.ts`): 22 tests
- Tests validate API endpoint construction, query params, and URL encoding

---

## 🎨 Linting

**Tool**: ESLint 9 with Next.js config

### Running Linter
```bash
npm run lint          # Check for errors
npm run lint -- --fix # Auto-fix issues
```

### Rules
- TypeScript strict mode
- React hooks rules
- Next.js best practices (image optimization, link usage)

---

## 🚀 Build & Deployment

### Development
```bash
npm run dev           # Starts on http://localhost:3000
```

### Production Build
```bash
npm run build         # Creates .next/ optimized bundle
npm start             # Serves production build
```

### Production Deployment — Vercel
The Admin Dashboard is deployed on **Vercel**.

| Setting | Value |
|---------|-------|
| Platform | Vercel |
| Framework preset | Next.js |
| Root directory | `frontend/admin_dashboard` |
| Build command | `npm run build` |
| Output | `.next/` |

Required environment variables in Vercel dashboard:
```
NEXT_PUBLIC_API_URL=https://ai-crop-disease-diagnosis-system-aumh.onrender.com
```

Deploys automatically on every push to `main`.

### Build Validation
CI runs `npm run build` to ensure:
- No TypeScript errors
- All imports resolve
- Build succeeds

---

## 📈 Key Features

### 1. Dashboard Metrics
- Total users, diagnoses, questions
- Daily/weekly trends
- Charts using Recharts
- **Redis-cached** — dashboard stats: 5 min TTL, daily metrics: 1 min TTL (via `GET /admin/dashboard` + `GET /admin/metrics/daily`)

### 2. User Management
- View all users (farmers, experts, admins)
- Filter by role/status
- Suspend/activate accounts

### 3. Expert Approval
- Review pending expert registrations
- View qualifications
- Approve/reject applicants

### 4. System Logs
- Filter by level (INFO, WARN, ERROR)
- Filter by source (auth, diagnosis, etc.)
- Real-time log viewer

### 5. Agronomy Management
- CRUD for Diagnostic Rules
- CRUD for Treatment Constraints
- CRUD for Seasonal Patterns

### 6. Content & Encyclopedia Management
- Manage Crop entries
- Manage Disease entries
- Manage **Pest** entries (PestInfo — damage type, life cycle, IPM controls)

---

## 🔄 Translation

**Status**: Not implemented. The dashboard is currently English-only.

To add multi-language support, you would:
1.  Install `next-intl` or `react-i18next`
2.  Create translation files (e.g., `en.json`, `hi.json`)
3.  Wrap the app with a translation provider
