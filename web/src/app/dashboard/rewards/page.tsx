'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase'
import { Gift, Check, X, Clock } from 'lucide-react'
import type { Cafe, Redemption } from '@/types'

export default function RewardsPage() {
  const [cafe, setCafe] = useState<Cafe | null>(null)
  const [redemptions, setRedemptions] = useState<Redemption[]>([])
  const [loading, setLoading] = useState(true)
  const [verifyCode, setVerifyCode] = useState('')
  const [verifying, setVerifying] = useState(false)
  const [verifyResult, setVerifyResult] = useState<{ success: boolean; message: string } | null>(null)

  useEffect(() => {
    loadRedemptions()
  }, [])

  const loadRedemptions = async () => {
    const supabase = createClient()
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    // Get cafe
    const { data: cafes } = await supabase
      .from('cafes')
      .select('*')
      .eq('owner_id', user.id)
      .limit(1)

    if (!cafes || cafes.length === 0) {
      setLoading(false)
      return
    }

    setCafe(cafes[0])

    // Get redemptions
    const { data: redemptionData } = await supabase
      .from('redemptions')
      .select(`
        *,
        users (
          name,
          phone
        )
      `)
      .eq('cafe_id', cafes[0].id)
      .order('created_at', { ascending: false })
      .limit(50)

    if (redemptionData) {
      setRedemptions(redemptionData.map((r: {
        id: string;
        user_id: string;
        cafe_id: string;
        stamps_used: number;
        reward_description: string;
        redemption_code: string;
        is_claimed: boolean;
        created_at: string;
        claimed_at: string | null;
        expires_at: string;
        users: { name: string | null; phone: string } | null
      }) => ({
        ...r,
        user_name: r.users?.name,
        user_phone: r.users?.phone,
      })))
    }

    setLoading(false)
  }

  const verifyRedemption = async () => {
    if (!verifyCode || !cafe) return

    setVerifying(true)
    setVerifyResult(null)

    const supabase = createClient()

    // Find redemption by code
    const { data: redemption } = await supabase
      .from('redemptions')
      .select('*')
      .eq('cafe_id', cafe.id)
      .eq('redemption_code', verifyCode.toUpperCase())
      .single()

    if (!redemption) {
      setVerifyResult({ success: false, message: 'Invalid code. Please check and try again.' })
      setVerifying(false)
      return
    }

    if (redemption.is_claimed) {
      setVerifyResult({ success: false, message: 'This code has already been used.' })
      setVerifying(false)
      return
    }

    const expiresAt = new Date(redemption.expires_at)
    if (expiresAt < new Date()) {
      setVerifyResult({ success: false, message: 'This code has expired.' })
      setVerifying(false)
      return
    }

    // Mark as claimed
    await supabase
      .from('redemptions')
      .update({
        is_claimed: true,
        claimed_at: new Date().toISOString(),
      })
      .eq('id', redemption.id)

    setVerifyResult({
      success: true,
      message: `Verified! Give the customer: ${redemption.reward_description}`,
    })

    setVerifyCode('')
    loadRedemptions() // Refresh list

    setVerifying(false)
  }

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString('en-IN', {
      day: 'numeric',
      month: 'short',
      hour: '2-digit',
      minute: '2-digit',
    })
  }

  const getStatus = (redemption: Redemption) => {
    if (redemption.is_claimed) return 'claimed'
    if (new Date(redemption.expires_at) < new Date()) return 'expired'
    return 'pending'
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin text-4xl">☕</div>
      </div>
    )
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Rewards & Redemptions</h1>
        <p className="text-gray-600">Verify redemption codes from customers</p>
      </div>

      {/* Verify Code Section */}
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 mb-8">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 bg-green-100 rounded-xl flex items-center justify-center">
            <Gift className="w-5 h-5 text-green-700" />
          </div>
          <div>
            <h2 className="font-semibold text-gray-900">Verify Redemption Code</h2>
            <p className="text-sm text-gray-500">Enter the code shown on customer&apos;s phone</p>
          </div>
        </div>

        <div className="flex gap-3">
          <input
            type="text"
            value={verifyCode}
            onChange={(e) => setVerifyCode(e.target.value.toUpperCase())}
            className="flex-1 px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-green-500 focus:border-transparent outline-none text-center text-2xl font-mono tracking-widest"
            placeholder="ABC123"
            maxLength={6}
          />
          <button
            onClick={verifyRedemption}
            disabled={verifying || verifyCode.length < 6}
            className="px-6 bg-green-600 text-white rounded-xl font-semibold hover:bg-green-700 transition disabled:opacity-50"
          >
            {verifying ? '...' : 'Verify'}
          </button>
        </div>

        {verifyResult && (
          <div
            className={`mt-4 p-4 rounded-xl flex items-center gap-3 ${
              verifyResult.success
                ? 'bg-green-50 text-green-800'
                : 'bg-red-50 text-red-800'
            }`}
          >
            {verifyResult.success ? (
              <Check className="w-5 h-5 flex-shrink-0" />
            ) : (
              <X className="w-5 h-5 flex-shrink-0" />
            )}
            <p>{verifyResult.message}</p>
          </div>
        )}
      </div>

      {/* Recent Redemptions */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="p-4 border-b border-gray-100">
          <h2 className="font-semibold text-gray-900">Recent Redemptions</h2>
        </div>

        {redemptions.length === 0 ? (
          <div className="p-12 text-center">
            <Gift className="w-12 h-12 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-500">No redemptions yet</p>
            <p className="text-sm text-gray-400 mt-1">
              They&apos;ll appear here when customers claim rewards
            </p>
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {redemptions.map((redemption) => {
              const status = getStatus(redemption)
              return (
                <div
                  key={redemption.id}
                  className="p-4 hover:bg-gray-50 transition"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                      <div
                        className={`w-10 h-10 rounded-full flex items-center justify-center ${
                          status === 'claimed'
                            ? 'bg-green-100'
                            : status === 'expired'
                            ? 'bg-red-100'
                            : 'bg-amber-100'
                        }`}
                      >
                        {status === 'claimed' && <Check className="w-5 h-5 text-green-700" />}
                        {status === 'expired' && <X className="w-5 h-5 text-red-700" />}
                        {status === 'pending' && <Clock className="w-5 h-5 text-amber-700" />}
                      </div>
                      <div>
                        <p className="font-medium text-gray-900">
                          {redemption.user_name || 'Anonymous'}
                        </p>
                        <p className="text-sm text-gray-500">{redemption.user_phone}</p>
                      </div>
                    </div>

                    <div className="text-right">
                      <p className="font-mono text-lg font-semibold text-gray-900">
                        {redemption.redemption_code}
                      </p>
                      <p className="text-sm text-gray-500">
                        {redemption.reward_description}
                      </p>
                    </div>
                  </div>

                  <div className="mt-3 flex items-center justify-between text-sm">
                    <span className="text-gray-500">
                      Created: {formatDate(redemption.created_at)}
                    </span>
                    <span
                      className={`px-2 py-1 rounded-full text-xs font-medium ${
                        status === 'claimed'
                          ? 'bg-green-100 text-green-800'
                          : status === 'expired'
                          ? 'bg-red-100 text-red-800'
                          : 'bg-amber-100 text-amber-800'
                      }`}
                    >
                      {status === 'claimed' && 'Claimed'}
                      {status === 'expired' && 'Expired'}
                      {status === 'pending' && 'Pending'}
                    </span>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
