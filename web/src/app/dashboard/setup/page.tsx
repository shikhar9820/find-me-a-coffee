'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { Coffee, MapPin, Gift, ArrowRight } from 'lucide-react'

export default function SetupPage() {
  const router = useRouter()
  const [step, setStep] = useState(1)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const [formData, setFormData] = useState({
    name: '',
    address: '',
    city: 'Delhi',
    stamps_required: 10,
    reward_description: 'Free coffee',
  })

  const handleSubmit = async () => {
    if (!formData.name) {
      setError('Please enter your cafe name')
      return
    }

    setLoading(true)
    setError(null)

    const supabase = createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
      router.push('/')
      return
    }

    const { error: insertError } = await supabase.from('cafes').insert({
      owner_id: user.id,
      name: formData.name,
      address: formData.address,
      city: formData.city,
      stamps_required: formData.stamps_required,
      reward_description: formData.reward_description,
    })

    if (insertError) {
      setError(insertError.message)
      setLoading(false)
      return
    }

    router.push('/dashboard')
  }

  return (
    <div className="max-w-2xl mx-auto">
      <div className="text-center mb-8">
        <div className="w-16 h-16 bg-amber-800 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <Coffee className="w-8 h-8 text-white" />
        </div>
        <h1 className="text-2xl font-bold text-gray-900 mb-2">Set Up Your Cafe</h1>
        <p className="text-gray-600">Let&apos;s get your loyalty program running</p>
      </div>

      {/* Progress */}
      <div className="flex items-center justify-center gap-2 mb-8">
        {[1, 2, 3].map((s) => (
          <div
            key={s}
            className={`w-3 h-3 rounded-full transition-colors ${
              s <= step ? 'bg-amber-800' : 'bg-gray-300'
            }`}
          />
        ))}
      </div>

      <div className="bg-white rounded-2xl p-8 shadow-sm border border-gray-100">
        {/* Step 1: Basic Info */}
        {step === 1 && (
          <div className="space-y-6">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 bg-amber-100 rounded-xl flex items-center justify-center">
                <Coffee className="w-5 h-5 text-amber-800" />
              </div>
              <div>
                <h2 className="font-semibold text-gray-900">Basic Information</h2>
                <p className="text-sm text-gray-500">Tell us about your cafe</p>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Cafe Name *
              </label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-amber-500 focus:border-transparent outline-none"
                placeholder="Blue Tokai Coffee"
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
                placeholder="Hauz Khas Village, New Delhi"
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

            <button
              onClick={() => setStep(2)}
              className="w-full bg-amber-800 text-white py-3 px-4 rounded-xl font-semibold hover:bg-amber-900 transition flex items-center justify-center gap-2"
            >
              Next
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* Step 2: Reward Setup */}
        {step === 2 && (
          <div className="space-y-6">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 bg-green-100 rounded-xl flex items-center justify-center">
                <Gift className="w-5 h-5 text-green-700" />
              </div>
              <div>
                <h2 className="font-semibold text-gray-900">Reward Setup</h2>
                <p className="text-sm text-gray-500">Configure your loyalty reward</p>
              </div>
            </div>

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
              <p className="text-sm text-gray-500 mt-2">
                Customers will earn a reward after collecting {formData.stamps_required} stamps
              </p>
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
                placeholder="Free Americano"
              />
              <p className="text-sm text-gray-500 mt-1">
                This is what customers will see as their reward
              </p>
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => setStep(1)}
                className="flex-1 bg-gray-100 text-gray-700 py-3 px-4 rounded-xl font-semibold hover:bg-gray-200 transition"
              >
                Back
              </button>
              <button
                onClick={() => setStep(3)}
                className="flex-1 bg-amber-800 text-white py-3 px-4 rounded-xl font-semibold hover:bg-amber-900 transition flex items-center justify-center gap-2"
              >
                Next
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

        {/* Step 3: Confirm */}
        {step === 3 && (
          <div className="space-y-6">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 bg-blue-100 rounded-xl flex items-center justify-center">
                <MapPin className="w-5 h-5 text-blue-700" />
              </div>
              <div>
                <h2 className="font-semibold text-gray-900">Confirm Details</h2>
                <p className="text-sm text-gray-500">Review and create your cafe</p>
              </div>
            </div>

            <div className="bg-gray-50 rounded-xl p-6 space-y-4">
              <div className="flex justify-between">
                <span className="text-gray-500">Cafe Name</span>
                <span className="font-medium text-gray-900">{formData.name || '-'}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Address</span>
                <span className="font-medium text-gray-900">{formData.address || 'Not set'}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">City</span>
                <span className="font-medium text-gray-900">{formData.city}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Stamps Required</span>
                <span className="font-medium text-gray-900">{formData.stamps_required}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Reward</span>
                <span className="font-medium text-gray-900">{formData.reward_description}</span>
              </div>
            </div>

            {error && (
              <div className="p-3 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm">
                {error}
              </div>
            )}

            <div className="flex gap-3">
              <button
                onClick={() => setStep(2)}
                className="flex-1 bg-gray-100 text-gray-700 py-3 px-4 rounded-xl font-semibold hover:bg-gray-200 transition"
              >
                Back
              </button>
              <button
                onClick={handleSubmit}
                disabled={loading}
                className="flex-1 bg-amber-800 text-white py-3 px-4 rounded-xl font-semibold hover:bg-amber-900 transition disabled:opacity-50 flex items-center justify-center gap-2"
              >
                {loading ? (
                  <span className="animate-spin">⏳</span>
                ) : (
                  <>
                    Create Cafe
                    <ArrowRight className="w-4 h-4" />
                  </>
                )}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
