# EduGuard AI — Setup Guide

## 🚀 Quick Start

### Prerequisites
- Node.js 20+
- Python 3.11+
- PostgreSQL 15+
- Git

---

## 📦 Installation

### 1. Clone & Navigate
```bash
cd eduguard-ai
```

### 2. Database Setup
```bash
# Create database
createdb eduguard

# Run the Sprint 0/1 schema and seed data, in order
psql -d eduguard -f database/001_schema.sql
psql -d eduguard -f database/002_seed.sql
psql -d eduguard -f database/003_views.sql
psql -d eduguard -f database/004_demo_users.sql

# Sprint 1 academic foundation (programs, tracks, terms, prerequisites,
# grade scale, advising plans, etc.)
psql -d eduguard -f database/005_academic_foundation.sql
psql -d eduguard -f database/006_seed_courses.sql
```

> ⚠️ Do not run `database/schema.sql` for new setups — it is a stale,
> Sprint-0-only snapshot kept for reference and does not include the
> Sprint 1/2 academic tables.

> ⚠️ `database/007_sprint2_seed.sql` seeds data into several tables
> (`elective_pools`, `elective_pool_courses`, `notification_templates`,
> `academic_calendar_periods`) that are created by the FastAPI app itself
> on startup (via SQLAlchemy `Base.metadata.create_all()`), not by a SQL
> file. **Start the backend at least once (step 3 below) before running
> `007_sprint2_seed.sql`**, or that script will fail with
> `relation "..." does not exist`.

### 3. Backend Setup
```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cat > .env << EOF
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/eduguard
SECRET_KEY=your-super-secret-key-change-in-production
DEBUG=True
EOF

# Start server (this also creates all Sprint 2 tables on first run)
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Once the server has started successfully at least once, run the Sprint 2
seed data:
```bash
psql -d eduguard -f database/007_sprint2_seed.sql
```

Backend will be available at: `http://localhost:8000`
API Docs: `http://localhost:8000/docs`

### 4. Frontend Setup
```bash
cd frontend

# Install dependencies
npm install

# Start dev server
npm run dev
```

Frontend will be available at: `http://localhost:5173`

---

## 🎨 Design System

### Colors (White & Red Theme)
| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#DC2626` | Buttons, badges, highlights |
| Primary Light | `#EF4444` | Hover states |
| Primary Dark | `#B91C1C` | Active states |
| Primary Muted | `#FEE2E2` | Light backgrounds |
| Primary Subtle | `#FEF2F2` | Subtle backgrounds |

### Status Colors
| Status | Color |
|--------|-------|
| Normal | `#10B981` (Emerald) |
| Low Risk | `#F59E0B` (Amber) |
| High Risk | `#F97316` (Orange) |
| Critical | `#DC2626` (Red) |
| Info | `#3B82F6` (Blue) |

---

## 🧪 Demo Credentials

The system uses demo mode — you can login with any email/password.

Select a role to see the corresponding dashboard:
- **Admin** — Full system access, analytics, all students
- **Professor** — Course management, risk heatmap, student rankings
- **Advisor** — Intervention management, student progress tracking
- **Student** — Personal dashboard, risk score, simulation mode

---

## 🏗️ Architecture

```
eduguard-ai/
├── frontend/          # React + Vite + Tailwind CSS
│   ├── src/
│   │   ├── components/ui/     # Reusable UI components
│   │   ├── components/charts/ # Chart components
│   │   ├── components/layout/ # Layout components
│   │   ├── context/           # React Context (Auth)
│   │   ├── pages/             # Page components
│   │   ├── lib/               # Utilities & mock data
│   │   └── types/             # TypeScript types
│   ├── index.html
│   └── package.json
│
├── backend/           # FastAPI + SQLAlchemy
│   ├── app/
│   │   ├── api/       # API routers
│   │   ├── core/      # Config & security
│   │   ├── models/    # SQLAlchemy models
│   │   ├── db/        # Database setup
│   │   ├── ai/        # Risk prediction model
│   │   └── services/  # Business logic
│   ├── main.py
│   └── requirements.txt
│
├── database/          # PostgreSQL schema
│   └── schema.sql
│
└── docs/              # Documentation
    ├── API.md
    └── SETUP.md
```

---

## 🔧 Environment Variables

### Backend (.env)
```env
DATABASE_URL=postgresql://user:password@localhost:5432/eduguard
SECRET_KEY=your-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
DEBUG=True
MODEL_PATH=./models
```

---

## 📝 Features Checklist

### ✅ Implemented
- [x] Role-based dashboards (Admin, Professor, Advisor, Student)
- [x] Risk assessment with explainable AI
- [x] Time-series performance tracking
- [x] What-If simulation engine
- [x] Intervention plan management
- [x] Quiz builder with analytics
- [x] Notification system
- [x] Gamification (points, streaks, badges)
- [x] White & Red design theme
- [x] Dark mode support
- [x] Responsive design
- [x] Full PostgreSQL schema
- [x] FastAPI backend with JWT auth
- [x] AI risk prediction model

### 🔄 Future Development
- [ ] Real-time WebSocket updates
- [ ] Email/SMS notifications
- [ ] LSTM time-series model
- [ ] Mobile app (React Native)
- [ ] Advanced report generation
- [ ] Integration with LMS (Canvas, Blackboard)
- [ ] Multi-language support

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

---

## 📄 License

MIT License — EduGuard AI Team
