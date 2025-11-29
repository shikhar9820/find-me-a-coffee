# Find Me A Coffee ☕

A loyalty platform for independent cafes in India. Customers collect stamps via NFC tap, earn rewards. Cafes get a free tool to build customer loyalty without Zomato's cuts.

## Features

### For Customers (Mobile App)
- 📱 NFC tap to collect stamps instantly
- 🎁 Redeem rewards when stamp card is full
- 🗺️ Discover participating cafes nearby
- 📊 Track progress across multiple cafes

### For Cafes (Web Dashboard)
- 📈 View customer analytics and stamp statistics
- ⚙️ Configure reward rules (stamps required, reward description)
- 📱 Generate QR codes for first-time customers
- ✅ Verify redemption codes

## Tech Stack

| Component | Technology |
|-----------|------------|
| Mobile App | Flutter |
| Web Dashboard | Next.js 14, TypeScript, Tailwind CSS |
| Backend | Supabase (PostgreSQL, Auth, Realtime) |
| NFC Tags | NTAG213/215 |

## Project Structure

```
find-me-a-coffee/
├── mobile/              # Flutter customer app
│   ├── lib/
│   │   ├── config/      # Supabase config, theme
│   │   ├── models/      # Data models
│   │   ├── screens/     # App screens
│   │   ├── services/    # NFC, auth, stamp services
│   │   └── widgets/     # Reusable UI components
│   └── pubspec.yaml
│
├── web/                 # Next.js cafe dashboard
│   ├── src/
│   │   ├── app/         # App router pages
│   │   ├── components/  # UI components
│   │   ├── lib/         # Supabase client
│   │   └── types/       # TypeScript types
│   └── package.json
│
├── supabase/
│   └── schema.sql       # Database schema
│
└── PLAN.md              # Detailed project plan
```

## Setup Instructions

### 1. Supabase Setup

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to SQL Editor and run the contents of `supabase/schema.sql`
3. Enable Phone Auth in Authentication > Providers (for mobile app)
4. Enable Email Auth for cafe owners
5. Get your project URL and anon key from Settings > API

### 2. Web Dashboard Setup

```bash
cd web

# Install dependencies
npm install

# Copy environment file
cp .env.local.example .env.local

# Edit .env.local with your Supabase credentials
# NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
# NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# Run development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to access the dashboard.

### 3. Mobile App Setup

**Prerequisites:**
- Flutter SDK (3.0+)
- Android Studio / Xcode
- A physical device with NFC (emulators don't support NFC)

```bash
cd mobile

# Install Flutter (if not installed)
# See: https://docs.flutter.dev/get-started/install

# Get dependencies
flutter pub get

# Update Supabase config
# Edit lib/config/supabase_config.dart with your credentials

# Run on device
flutter run
```

### 4. NFC Tag Setup

1. Buy NTAG213 or NTAG215 NFC tags (~₹30-50 each)
2. Install an NFC writer app (e.g., NFC Tools)
3. Write this URL to the tag: `findmeacoffee://stamp/{cafe_uuid}`
4. Get the cafe_uuid from your dashboard after setup
5. Stick the tag at your cafe counter

## How It Works

### Customer Flow
1. First visit: Scan QR code → Download app
2. Subsequent visits: Tap phone on NFC tag → Stamp collected
3. After X stamps: Show redemption code to cafe owner
4. Get free coffee!

### Cafe Owner Flow
1. Sign up at dashboard
2. Set up cafe details and reward rules
3. Print QR code, set up NFC tag
4. View customer analytics
5. Verify redemption codes when customers claim rewards

## Deployment

### Web Dashboard
```bash
# Build for production
npm run build

# Deploy to Vercel
npx vercel
```

### Mobile App
```bash
# Build Android APK
flutter build apk

# Build iOS (requires Mac)
flutter build ios
```

## Business Model

**Free for cafes (MVP):**
- Unlimited stamps
- Basic analytics
- QR code generation

**Future monetization:**
- Promoted placement in discovery
- Push notification campaigns for cafes
- Advanced analytics

## Roadmap

- [x] Core stamp collection (NFC + QR)
- [x] Cafe dashboard
- [x] Redemption flow
- [ ] Push notifications
- [ ] Cafe discovery map
- [ ] Multi-tier rewards
- [ ] Blog/review feature
- [ ] Promotional campaigns

## Contributing

This is currently a personal project. Feel free to fork and adapt for your own use!

## License

MIT

---

Built with ❤️ in Delhi for independent cafes.
