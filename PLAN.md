# Find Me A Coffee - Project Plan

## Vision
A loyalty platform for independent cafés in India. Customers collect stamps via NFC tap, redeem rewards. Cafés get a free tool to build customer loyalty without Zomato's cuts.

## Core Problem
- Independent cafés have no affordable way to build customer loyalty
- Zomato/Swiggy take 20-25% commission and don't help retention
- Paper punch cards are outdated and get lost
- Small cafés can't build their own apps

## Solution
- Free loyalty platform for cafés
- NFC tap to collect stamps (QR fallback for first-time download)
- Café sets their own reward rules (5 stamps, 10 stamps, whatever)
- Café pays for their own free coffee (not us)
- Monetize later via promotions/ads

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| Mobile App | Flutter (iOS + Android) |
| Web Dashboard | Next.js |
| Backend/API | Supabase (PostgreSQL, Auth, API) |
| Hosting (Web) | Vercel |
| NFC Tags | NTAG213/215 |

---

## Features - MVP

### Customer Mobile App (Flutter)

1. **Onboarding**
   - Phone number login (OTP via Supabase/SMS provider)
   - Simple profile (name, optional email)

2. **Home Screen**
   - List of cafés where user has stamps
   - Stamp progress per café (e.g., 4/10)
   - Nearby participating cafés

3. **NFC Stamp Collection**
   - Tap phone on NFC tag
   - App reads café ID from tag
   - Stamp added to user's account
   - Satisfying animation + haptic feedback

4. **QR Fallback**
   - First-time users scan QR at café
   - Opens app store / web link
   - After install, can use NFC

5. **Rewards**
   - View available rewards per café
   - Redeem reward (show screen to café owner)
   - Redemption history

6. **Café Discovery**
   - Map view of nearby participating cafés
   - Basic info: name, address, reward offered
   - Distance from current location

### Café Web Dashboard (Next.js)

1. **Auth**
   - Email/password signup
   - Email verification

2. **Café Profile Setup**
   - Café name, address, logo
   - Operating hours
   - Contact info

3. **Reward Configuration**
   - Set stamps required (e.g., 10)
   - Set reward (e.g., "1 free cold brew")
   - Can have multiple reward tiers later

4. **QR & NFC Setup**
   - Generate unique QR code (downloadable/printable)
   - NFC tag ID registration
   - Instructions for setup

5. **Dashboard**
   - Total stamps given
   - Total redemptions
   - Active customers (stamped in last 30 days)
   - Simple charts

6. **Customer List**
   - View customers who have stamps
   - Stamp count per customer
   - Last visit date

7. **Redemption Verification**
   - When customer shows redemption screen
   - Café enters redemption code OR scans QR on customer's screen
   - Marks reward as claimed

### Admin Panel (Can be part of Next.js app)

1. **Café Management**
   - Approve/reject café signups
   - View all cafés
   - Suspend fraudulent cafés

2. **User Management**
   - View users
   - Handle support issues

3. **Analytics**
   - Total users, cafés, stamps, redemptions
   - Growth metrics

---

## Database Schema (Supabase/PostgreSQL)

### Tables

```sql
-- Users (customers)
users (
  id UUID PRIMARY KEY,
  phone VARCHAR(15) UNIQUE NOT NULL,
  name VARCHAR(100),
  email VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW()
)

-- Cafés
cafes (
  id UUID PRIMARY KEY,
  owner_id UUID REFERENCES cafe_owners(id),
  name VARCHAR(200) NOT NULL,
  address TEXT,
  city VARCHAR(100),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  logo_url TEXT,
  nfc_tag_id VARCHAR(100) UNIQUE,
  qr_code_url TEXT,
  stamps_required INT DEFAULT 10,
  reward_description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
)

-- Café Owners
cafe_owners (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name VARCHAR(100),
  phone VARCHAR(15),
  created_at TIMESTAMP DEFAULT NOW()
)

-- Stamps
stamps (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  cafe_id UUID REFERENCES cafes(id),
  stamped_at TIMESTAMP DEFAULT NOW()
)

-- Redemptions
redemptions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  cafe_id UUID REFERENCES cafes(id),
  stamps_used INT,
  reward_description TEXT,
  redemption_code VARCHAR(20) UNIQUE,
  is_claimed BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  claimed_at TIMESTAMP
)

-- Indexes
CREATE INDEX idx_stamps_user_cafe ON stamps(user_id, cafe_id);
CREATE INDEX idx_stamps_cafe ON stamps(cafe_id);
CREATE INDEX idx_redemptions_user ON redemptions(user_id);
CREATE INDEX idx_cafes_location ON cafes(latitude, longitude);
CREATE INDEX idx_cafes_city ON cafes(city);
```

---

## Project Structure

```
find-me-a-coffee/
├── mobile/                 # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/
│   │   │   └── supabase.dart
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   ├── cafe.dart
│   │   │   ├── stamp.dart
│   │   │   └── redemption.dart
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── cafe_detail_screen.dart
│   │   │   ├── discover_screen.dart
│   │   │   ├── rewards_screen.dart
│   │   │   └── profile_screen.dart
│   │   ├── services/
│   │   │   ├── auth_service.dart
│   │   │   ├── nfc_service.dart
│   │   │   ├── stamp_service.dart
│   │   │   └── location_service.dart
│   │   ├── widgets/
│   │   │   ├── stamp_card.dart
│   │   │   ├── cafe_tile.dart
│   │   │   ├── stamp_animation.dart
│   │   │   └── reward_card.dart
│   │   └── utils/
│   │       └── constants.dart
│   ├── pubspec.yaml
│   └── README.md
│
├── web/                    # Next.js dashboard
│   ├── src/
│   │   ├── app/
│   │   │   ├── layout.tsx
│   │   │   ├── page.tsx
│   │   │   ├── login/
│   │   │   ├── signup/
│   │   │   ├── dashboard/
│   │   │   │   ├── page.tsx
│   │   │   │   ├── customers/
│   │   │   │   ├── rewards/
│   │   │   │   ├── qr-setup/
│   │   │   │   └── settings/
│   │   │   └── admin/
│   │   ├── components/
│   │   │   ├── ui/
│   │   │   ├── dashboard/
│   │   │   └── charts/
│   │   ├── lib/
│   │   │   ├── supabase.ts
│   │   │   └── utils.ts
│   │   └── types/
│   │       └── index.ts
│   ├── package.json
│   └── README.md
│
├── PLAN.md                 # This file
└── README.md
```

---

## Implementation Phases

### Phase 1: Foundation (Current)
- [x] Project planning
- [ ] Initialize Flutter project
- [ ] Initialize Next.js project
- [ ] Setup Supabase project & database schema
- [ ] Basic auth flow (mobile + web)

### Phase 2: Core Mobile App
- [ ] NFC service implementation
- [ ] Stamp collection flow
- [ ] Home screen with stamp cards
- [ ] QR code scanning fallback
- [ ] Stamp animation

### Phase 3: Café Dashboard
- [ ] Café signup & profile setup
- [ ] Reward configuration
- [ ] QR code generation
- [ ] Dashboard analytics
- [ ] Customer list view

### Phase 4: Redemption Flow
- [ ] Reward redemption in mobile app
- [ ] Redemption verification in dashboard
- [ ] Redemption history

### Phase 5: Discovery
- [ ] Location-based café discovery
- [ ] Map view
- [ ] Café detail pages

### Phase 6: Polish & Launch
- [ ] UI/UX polish
- [ ] Animations
- [ ] Testing on multiple devices
- [ ] Play Store & App Store submission
- [ ] Onboard first 10-20 cafés in Delhi

---

## NFC Implementation Details

### Tag Setup
- Use NTAG213 or NTAG215 tags
- Each tag programmed with unique café identifier
- Format: `findmeacoffee://stamp/{cafe_uuid}`
- Tags are read-only after programming (prevent tampering)

### Flutter NFC Flow
```dart
// Pseudocode
1. App listens for NFC tag
2. Tag detected → read NDEF message
3. Parse café ID from URL
4. API call: POST /stamps { cafe_id, user_id }
5. Success → play animation, haptic feedback
6. Update local stamp count
```

### iOS Considerations
- NFC reading requires user to explicitly tap (no background scanning)
- Need to add NFC capability in Xcode
- Works on iPhone 7+

### Android Considerations
- Can enable foreground dispatch for smoother UX
- Works on most phones with NFC hardware
- Need NFC permission in manifest

---

## Security Considerations

1. **Rate Limiting**
   - Max 1 stamp per café per user per 30 minutes
   - Prevents accidental double-taps

2. **Redemption Codes**
   - Short-lived codes (15 min expiry)
   - One-time use
   - Verified server-side

3. **Café Verification**
   - Manual approval for new cafés
   - Verify business exists (GST number optional)

4. **Data Privacy**
   - Minimal data collection
   - Phone number for auth only
   - Location only when actively discovering

---

## Future Features (Post-MVP)

1. **Promotions (Monetization)**
   - Cafés pay to send push notifications
   - Featured café in discovery
   - "Double stamp day" campaigns

2. **Social Features**
   - Share stamp progress
   - Refer a friend

3. **Multiple Reward Tiers**
   - 5 stamps = 10% off
   - 10 stamps = free pastry
   - 20 stamps = free coffee

4. **Analytics Pro**
   - Customer segmentation
   - Churn prediction
   - Best performing hours

5. **Blog/Reviews**
   - User-generated content
   - Café reviews
   - Coffee guides

---

## Launch Strategy (Delhi First)

### Target Areas
1. Hauz Khas Village
2. Shahpur Jat
3. Champa Gali
4. Connaught Place
5. Satya Niketan
6. Majnu Ka Tilla

### Onboarding Plan
1. Personally visit cafés with demo
2. Offer free NFC tags + setup
3. No cost to café (ever, for basic features)
4. Help them announce on Instagram

### Target: 20 cafés, 1000 users in first 2 months

---

## Cost Estimates

| Item | Cost |
|------|------|
| Supabase (free tier) | ₹0 |
| Vercel (free tier) | ₹0 |
| Apple Developer Account | $99/year (~₹8,200) |
| Google Play Developer | $25 one-time (~₹2,100) |
| NFC Tags (100 pcs) | ~₹3,000-5,000 |
| Domain | ~₹800/year |
| **Total Year 1** | **~₹15,000-20,000** |

---

## Next Steps

1. Initialize Flutter project with required dependencies
2. Initialize Next.js project with Supabase
3. Create Supabase project and run schema
4. Build auth flow first (both platforms)
5. Implement NFC stamp collection
6. Build café dashboard
7. Test with real NFC tags
8. Polish and launch

---

*Let's build the best damn loyalty app for Indian cafés.*
