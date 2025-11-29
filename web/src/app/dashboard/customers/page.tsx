'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase'
import { Users, Coffee, Calendar } from 'lucide-react'
import type { Cafe } from '@/types'

interface CustomerData {
  user_id: string
  user_name: string | null
  user_phone: string
  stamp_count: number
  last_visit: string
}

export default function CustomersPage() {
  const [cafe, setCafe] = useState<Cafe | null>(null)
  const [customers, setCustomers] = useState<CustomerData[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadCustomers()
  }, [])

  const loadCustomers = async () => {
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

    // Get customers with stamps at this cafe
    const { data: stampData } = await supabase
      .from('stamps')
      .select(`
        user_id,
        stamped_at,
        users (
          name,
          phone
        )
      `)
      .eq('cafe_id', cafes[0].id)
      .order('stamped_at', { ascending: false })

    if (stampData) {
      // Aggregate by user
      const customerMap = new Map<string, CustomerData>()

      stampData.forEach((stamp) => {
        const existing = customerMap.get(stamp.user_id)
        // Supabase returns joined data as array or object depending on relationship
        const userData = Array.isArray(stamp.users) ? stamp.users[0] : stamp.users
        if (existing) {
          existing.stamp_count++
          if (stamp.stamped_at > existing.last_visit) {
            existing.last_visit = stamp.stamped_at
          }
        } else {
          customerMap.set(stamp.user_id, {
            user_id: stamp.user_id,
            user_name: userData?.name || null,
            user_phone: userData?.phone || 'Unknown',
            stamp_count: 1,
            last_visit: stamp.stamped_at,
          })
        }
      })

      // Sort by last visit
      const customerList = Array.from(customerMap.values())
        .sort((a, b) => new Date(b.last_visit).getTime() - new Date(a.last_visit).getTime())

      setCustomers(customerList)
    }

    setLoading(false)
  }

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr)
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    const days = Math.floor(diff / (1000 * 60 * 60 * 24))

    if (days === 0) return 'Today'
    if (days === 1) return 'Yesterday'
    if (days < 7) return `${days} days ago`
    return date.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })
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
        <h1 className="text-2xl font-bold text-gray-900">Customers</h1>
        <p className="text-gray-600">People collecting stamps at your cafe</p>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-xl flex items-center justify-center">
              <Users className="w-5 h-5 text-blue-700" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{customers.length}</p>
              <p className="text-sm text-gray-500">Total Customers</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-amber-100 rounded-xl flex items-center justify-center">
              <Coffee className="w-5 h-5 text-amber-700" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">
                {customers.reduce((sum, c) => sum + c.stamp_count, 0)}
              </p>
              <p className="text-sm text-gray-500">Total Stamps</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-100 rounded-xl flex items-center justify-center">
              <Calendar className="w-5 h-5 text-green-700" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">
                {customers.filter(c => {
                  const lastVisit = new Date(c.last_visit)
                  const weekAgo = new Date()
                  weekAgo.setDate(weekAgo.getDate() - 7)
                  return lastVisit > weekAgo
                }).length}
              </p>
              <p className="text-sm text-gray-500">Active This Week</p>
            </div>
          </div>
        </div>
      </div>

      {/* Customer List */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="p-4 border-b border-gray-100">
          <h2 className="font-semibold text-gray-900">All Customers</h2>
        </div>

        {customers.length === 0 ? (
          <div className="p-12 text-center">
            <Users className="w-12 h-12 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-500">No customers yet</p>
            <p className="text-sm text-gray-400 mt-1">
              They&apos;ll appear here when they start collecting stamps
            </p>
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {customers.map((customer) => (
              <div
                key={customer.user_id}
                className="p-4 hover:bg-gray-50 transition"
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 bg-amber-100 rounded-full flex items-center justify-center">
                      <span className="text-amber-800 font-semibold">
                        {customer.user_name?.[0]?.toUpperCase() || customer.user_phone?.[0] || '?'}
                      </span>
                    </div>
                    <div>
                      <p className="font-medium text-gray-900">
                        {customer.user_name || 'Anonymous'}
                      </p>
                      <p className="text-sm text-gray-500">{customer.user_phone}</p>
                    </div>
                  </div>

                  <div className="text-right">
                    <div className="flex items-center gap-1 justify-end">
                      <Coffee className="w-4 h-4 text-amber-600" />
                      <span className="font-semibold text-gray-900">
                        {customer.stamp_count}
                      </span>
                      <span className="text-gray-500">/ {cafe?.stamps_required}</span>
                    </div>
                    <p className="text-sm text-gray-500">
                      Last visit: {formatDate(customer.last_visit)}
                    </p>
                  </div>
                </div>

                {/* Progress bar */}
                <div className="mt-3">
                  <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-amber-500 rounded-full transition-all"
                      style={{
                        width: `${Math.min(
                          (customer.stamp_count / (cafe?.stamps_required || 10)) * 100,
                          100
                        )}%`,
                      }}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
