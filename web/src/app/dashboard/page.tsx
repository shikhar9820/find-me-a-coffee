'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase'
import { Coffee, Users, Gift, TrendingUp } from 'lucide-react'
import type { CafeStats, Cafe } from '@/types'

export default function DashboardPage() {
  const [stats, setStats] = useState<CafeStats | null>(null)
  const [cafe, setCafe] = useState<Cafe | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadDashboard()
  }, [])

  const loadDashboard = async () => {
    const supabase = createClient()
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    // Get cafe
    const { data: cafes } = await supabase
      .from('cafes')
      .select('*')
      .eq('owner_id', user.id)
      .limit(1)

    if (cafes && cafes.length > 0) {
      setCafe(cafes[0])

      // Get stats
      const { data: statsData } = await supabase
        .rpc('get_cafe_stats', { p_cafe_id: cafes[0].id })

      if (statsData) {
        setStats(statsData)
      }
    }

    setLoading(false)
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin text-4xl">☕</div>
      </div>
    )
  }

  if (!cafe) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500">No cafe found. Please set up your cafe first.</p>
      </div>
    )
  }

  const statCards = [
    {
      label: 'Total Stamps',
      value: stats?.total_stamps || 0,
      icon: Coffee,
      color: 'bg-amber-500',
      subtext: `${stats?.stamps_today || 0} today`
    },
    {
      label: 'Active Customers',
      value: stats?.active_customers || 0,
      icon: Users,
      color: 'bg-blue-500',
      subtext: 'Last 30 days'
    },
    {
      label: 'Redemptions',
      value: stats?.total_redemptions || 0,
      icon: Gift,
      color: 'bg-green-500',
      subtext: 'All time'
    },
    {
      label: 'This Week',
      value: stats?.stamps_this_week || 0,
      icon: TrendingUp,
      color: 'bg-purple-500',
      subtext: 'Stamps collected'
    },
  ]

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-600">Welcome back! Here&apos;s how your cafe is doing.</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {statCards.map((stat) => (
          <div
            key={stat.label}
            className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100"
          >
            <div className="flex items-start justify-between">
              <div>
                <p className="text-sm text-gray-500 mb-1">{stat.label}</p>
                <p className="text-3xl font-bold text-gray-900">{stat.value}</p>
                <p className="text-xs text-gray-400 mt-1">{stat.subtext}</p>
              </div>
              <div className={`${stat.color} p-3 rounded-xl`}>
                <stat.icon className="w-6 h-6 text-white" />
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Cafe Info Card */}
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 mb-8">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Your Cafe</h2>
        <div className="grid md:grid-cols-2 gap-6">
          <div>
            <p className="text-sm text-gray-500">Name</p>
            <p className="font-medium text-gray-900">{cafe.name}</p>
          </div>
          <div>
            <p className="text-sm text-gray-500">Location</p>
            <p className="font-medium text-gray-900">{cafe.address || 'Not set'}</p>
          </div>
          <div>
            <p className="text-sm text-gray-500">Stamps Required</p>
            <p className="font-medium text-gray-900">{cafe.stamps_required} stamps</p>
          </div>
          <div>
            <p className="text-sm text-gray-500">Reward</p>
            <p className="font-medium text-gray-900">{cafe.reward_description}</p>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h2>
        <div className="grid md:grid-cols-3 gap-4">
          <a
            href="/dashboard/qr-setup"
            className="flex items-center gap-3 p-4 bg-amber-50 rounded-xl hover:bg-amber-100 transition"
          >
            <div className="w-10 h-10 bg-amber-800 rounded-lg flex items-center justify-center">
              <Coffee className="w-5 h-5 text-white" />
            </div>
            <div>
              <p className="font-medium text-gray-900">Set up NFC/QR</p>
              <p className="text-sm text-gray-500">Get your stamp codes</p>
            </div>
          </a>
          <a
            href="/dashboard/customers"
            className="flex items-center gap-3 p-4 bg-blue-50 rounded-xl hover:bg-blue-100 transition"
          >
            <div className="w-10 h-10 bg-blue-500 rounded-lg flex items-center justify-center">
              <Users className="w-5 h-5 text-white" />
            </div>
            <div>
              <p className="font-medium text-gray-900">View Customers</p>
              <p className="text-sm text-gray-500">See who&apos;s collecting</p>
            </div>
          </a>
          <a
            href="/dashboard/settings"
            className="flex items-center gap-3 p-4 bg-gray-50 rounded-xl hover:bg-gray-100 transition"
          >
            <div className="w-10 h-10 bg-gray-500 rounded-lg flex items-center justify-center">
              <Gift className="w-5 h-5 text-white" />
            </div>
            <div>
              <p className="font-medium text-gray-900">Edit Rewards</p>
              <p className="text-sm text-gray-500">Change stamp rules</p>
            </div>
          </a>
        </div>
      </div>
    </div>
  )
}
