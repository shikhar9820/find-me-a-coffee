'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase'
import { Settings, Save, MapPin } from 'lucide-react'
import type { Cafe } from '@/types'

export default function SettingsPage() {
  const [cafe, setCafe] = useState<Cafe | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)

  const [formData, setFormData] = useState({
    name: '',
    address: '',
    city: '',
    stamps_required: 10,
    reward_description: '',
  })

  useEffect(() => {
    loadCafe()
  }, [])

  const loadCafe = async () => {
    const supabase = createClient()
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const { data: cafes } = await supabase
      .from('cafes')
      .select('*')
      .eq('owner_id', user.id)
      .limit(1)

    if (cafes && cafes.length > 0) {
      setCafe(cafes[0])
      setFormData({
        name: cafes[0].name,
        address: cafes[0].address || '',
        city: cafes[0].city || '',
        stamps_required: cafes[0].stamps_required,
        reward_description: cafes[0].reward_description,
      })
    }

    setLoading(false)
  }

  const handleSave = async () => {
    if (!cafe) return

    setSaving(true)
    const supabase = createClient()

    await supabase
      .from('cafes')
      .update({
        name: formData.name,
        address: formData.address,
        city: formData.city,
        stamps_required: formData.stamps_required,
        reward_description: formData.reward_description,
      })
      .eq('id', cafe.id)

    setSaving(false)
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
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
        <p className="text-gray-500">No cafe found.</p>
      </div>
    )
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Settings</h1>
        <p className="text-gray-600">Manage your cafe details and reward settings</p>
      </div>

      <div className="max-w-2xl">
        {/* Basic Info */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 mb-6">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 bg-amber-100 rounded-xl flex items-center justify-center">
              <Settings className="w-5 h-5 text-amber-800" />
            </div>
            <div>
              <h2 className="font-semibold text-gray-900">Cafe Information</h2>
              <p className="text-sm text-gray-500">Basic details about your cafe</p>
            </div>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Cafe Name
              </label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-amber-500 focus:border-transparent outline-none"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Address
              </label>
              <input
                type="text"
                value={formData.address}
                onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-amber-500 focus:border-transparent outline-none"
                placeholder="e.g., Hauz Khas Village, New Delhi"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                City
              </label>
              <select
                value={formData.city}
                onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-amber-500 focus:border-transparent outline-none"
              >
                <option value="">Select city</option>
                <option value="Delhi">Delhi</option>
                <option value="Mumbai">Mumbai</option>
                <option value="Bangalore">Bangalore</option>
                <option value="Hyderabad">Hyderabad</option>
                <option value="Chennai">Chennai</option>
                <option value="Kolkata">Kolkata</option>
                <option value="Pune">Pune</option>
                <option value="Other">Other</option>
              </select>
            </div>
          </div>
        </div>

        {/* Reward Settings */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 mb-6">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 bg-green-100 rounded-xl flex items-center justify-center">
              <MapPin className="w-5 h-5 text-green-700" />
            </div>
            <div>
              <h2 className="font-semibold text-gray-900">Reward Settings</h2>
              <p className="text-sm text-gray-500">Configure your loyalty program</p>
            </div>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Stamps Required for Reward
              </label>
              <div className="grid grid-cols-4 gap-3">
                {[5, 8, 10, 12].map((num) => (
                  <button
                    key={num}
                    onClick={() => setFormData({ ...formData, stamps_required: num })}
                    className={`py-3 rounded-xl font-semibold transition ${
                      formData.stamps_required === num
                        ? 'bg-amber-800 text-white'
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                    }`}
                  >
                    {num}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Reward Description
              </label>
              <input
                type="text"
                value={formData.reward_description}
                onChange={(e) => setFormData({ ...formData, reward_description: e.target.value })}
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-amber-500 focus:border-transparent outline-none"
                placeholder="e.g., Free Americano"
              />
              <p className="text-sm text-gray-500 mt-1">
                This is what customers will see as their reward
              </p>
            </div>
          </div>
        </div>

        {/* Save Button */}
        <button
          onClick={handleSave}
          disabled={saving}
          className="w-full bg-amber-800 text-white py-3 px-4 rounded-xl font-semibold hover:bg-amber-900 transition disabled:opacity-50 flex items-center justify-center gap-2"
        >
          {saving ? (
            <span className="animate-spin">⏳</span>
          ) : saved ? (
            <>
              <span>✓</span> Saved!
            </>
          ) : (
            <>
              <Save className="w-4 h-4" />
              Save Changes
            </>
          )}
        </button>

        {/* Warning */}
        <div className="mt-6 p-4 bg-amber-50 rounded-xl">
          <p className="text-sm text-amber-800">
            <strong>Note:</strong> Changing the stamps required won&apos;t affect customers who already have stamps.
            They&apos;ll continue with their current progress based on the old requirement until they redeem.
          </p>
        </div>
      </div>
    </div>
  )
}
