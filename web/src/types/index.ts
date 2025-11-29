export interface CafeOwner {
  id: string
  email: string
  name: string | null
  phone: string | null
  created_at: string
}

export interface Cafe {
  id: string
  owner_id: string
  name: string
  address: string | null
  city: string | null
  latitude: number | null
  longitude: number | null
  logo_url: string | null
  nfc_tag_id: string | null
  qr_code_url: string | null
  stamps_required: number
  reward_description: string
  is_active: boolean
  created_at: string
}

export interface Stamp {
  id: string
  user_id: string
  cafe_id: string
  stamped_at: string
  // Joined data
  user_name?: string
  user_phone?: string
}

export interface Redemption {
  id: string
  user_id: string
  cafe_id: string
  stamps_used: number
  reward_description: string
  redemption_code: string
  is_claimed: boolean
  created_at: string
  claimed_at: string | null
  expires_at: string
  // Joined data
  user_name?: string
  user_phone?: string
}

export interface CafeStats {
  total_stamps: number
  total_redemptions: number
  active_customers: number
  stamps_today: number
  stamps_this_week: number
  stamps_this_month: number
}

export interface CustomerSummary {
  user_id: string
  user_name: string | null
  user_phone: string
  stamp_count: number
  last_visit: string
}
