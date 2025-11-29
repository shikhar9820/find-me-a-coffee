'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase'
import { Coffee, ArrowRight } from 'lucide-react'
import Link from 'next/link'

export default function Home() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [isLogin, setIsLogin] = useState(true)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleAuth = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    const supabase = createClient()

    try {
      if (isLogin) {
        const { error } = await supabase.auth.signInWithPassword({
          email,
          password,
        })
        if (error) throw error
        window.location.href = '/dashboard'
      } else {
        const { error } = await supabase.auth.signUp({
          email,
          password,
        })
        if (error) throw error

        // Create cafe owner profile
        const { data: { user } } = await supabase.auth.getUser()
        if (user) {
          await supabase.from('cafe_owners').insert({
            id: user.id,
            email: user.email,
          })
        }

        window.location.href = '/dashboard/setup'
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'An error occurred')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex">
      {/* Left side - Branding */}
      <div className="hidden lg:flex lg:w-1/2 bg-amber-800 text-white p-12 flex-col justify-between">
        <div>
          <div className="flex items-center gap-3 mb-8">
            <div className="w-12 h-12 bg-white rounded-xl flex items-center justify-center">
              <Coffee className="w-7 h-7 text-amber-800" />
            </div>
            <span className="text-2xl font-bold">Find Me A Coffee</span>
          </div>
          <h1 className="text-4xl font-bold leading-tight mb-4">
            Build customer loyalty without Zomato&apos;s cuts
          </h1>
          <p className="text-amber-200 text-lg">
            Free loyalty platform for independent cafes in India.
            Your customers collect stamps, earn rewards, and keep coming back.
          </p>
        </div>

        <div className="space-y-6">
          <div className="flex items-start gap-4">
            <div className="w-8 h-8 bg-amber-700 rounded-lg flex items-center justify-center flex-shrink-0">
              <span className="text-sm font-bold">1</span>
            </div>
            <div>
              <h3 className="font-semibold">Set up your reward</h3>
              <p className="text-amber-200 text-sm">Choose how many stamps for a free coffee</p>
            </div>
          </div>
          <div className="flex items-start gap-4">
            <div className="w-8 h-8 bg-amber-700 rounded-lg flex items-center justify-center flex-shrink-0">
              <span className="text-sm font-bold">2</span>
            </div>
            <div>
              <h3 className="font-semibold">Get your NFC tag</h3>
              <p className="text-amber-200 text-sm">Customers tap to collect stamps instantly</p>
            </div>
          </div>
          <div className="flex items-start gap-4">
            <div className="w-8 h-8 bg-amber-700 rounded-lg flex items-center justify-center flex-shrink-0">
              <span className="text-sm font-bold">3</span>
            </div>
            <div>
              <h3 className="font-semibold">Watch them return</h3>
              <p className="text-amber-200 text-sm">Track customer loyalty on your dashboard</p>
            </div>
          </div>
        </div>

        <p className="text-amber-300 text-sm">
          Trusted by independent cafes across Delhi
        </p>
      </div>

      {/* Right side - Auth form */}
      <div className="flex-1 flex items-center justify-center p-8">
        <div className="w-full max-w-md">
          <div className="lg:hidden mb-8">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 bg-amber-800 rounded-xl flex items-center justify-center">
                <Coffee className="w-6 h-6 text-white" />
              </div>
              <span className="text-xl font-bold text-gray-900">Find Me A Coffee</span>
            </div>
          </div>

          <h2 className="text-2xl font-bold text-gray-900 mb-2">
            {isLogin ? 'Welcome back' : 'Create your account'}
          </h2>
          <p className="text-gray-600 mb-8">
            {isLogin
              ? 'Sign in to manage your cafe\'s loyalty program'
              : 'Start building customer loyalty today'}
          </p>

          <form onSubmit={handleAuth} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Email
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-amber-500 focus:border-transparent outline-none transition"
                placeholder="you@example.com"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Password
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-amber-500 focus:border-transparent outline-none transition"
                placeholder="••••••••"
                required
                minLength={6}
              />
            </div>

            {error && (
              <div className="p-3 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-amber-800 text-white py-3 px-4 rounded-xl font-semibold hover:bg-amber-900 transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {loading ? (
                <span className="animate-spin">⏳</span>
              ) : (
                <>
                  {isLogin ? 'Sign In' : 'Create Account'}
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>

          <div className="mt-6 text-center">
            <button
              onClick={() => {
                setIsLogin(!isLogin)
                setError(null)
              }}
              className="text-amber-800 hover:underline text-sm"
            >
              {isLogin
                ? "Don't have an account? Sign up"
                : "Already have an account? Sign in"}
            </button>
          </div>

          <div className="mt-8 pt-8 border-t border-gray-200">
            <p className="text-center text-gray-500 text-sm">
              Looking for the customer app?{' '}
              <Link href="/download" className="text-amber-800 hover:underline">
                Download here
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
