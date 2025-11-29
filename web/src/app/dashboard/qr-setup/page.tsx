'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase'
import { QrCode, Nfc, Download, Copy, Check } from 'lucide-react'
import { QRCodeSVG } from 'qrcode.react'
import type { Cafe } from '@/types'

export default function QRSetupPage() {
  const [cafe, setCafe] = useState<Cafe | null>(null)
  const [loading, setLoading] = useState(true)
  const [copied, setCopied] = useState(false)
  const [nfcTagId, setNfcTagId] = useState('')
  const [savingNfc, setSavingNfc] = useState(false)

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
      setNfcTagId(cafes[0].nfc_tag_id || '')
    }

    setLoading(false)
  }

  const getQRUrl = () => {
    if (!cafe) return ''
    // URL that customers will scan to get the app / collect stamp
    return `https://findmeacoffee.in/stamp/${cafe.id}`
  }

  const getNfcUrl = () => {
    if (!cafe) return ''
    return `findmeacoffee://stamp/${cafe.id}`
  }

  const copyToClipboard = async (text: string) => {
    await navigator.clipboard.writeText(text)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  const downloadQR = () => {
    const svg = document.getElementById('qr-code')
    if (!svg) return

    const svgData = new XMLSerializer().serializeToString(svg)
    const canvas = document.createElement('canvas')
    const ctx = canvas.getContext('2d')
    const img = new Image()

    img.onload = () => {
      canvas.width = 400
      canvas.height = 400
      ctx?.drawImage(img, 0, 0, 400, 400)
      const pngFile = canvas.toDataURL('image/png')
      const downloadLink = document.createElement('a')
      downloadLink.download = `${cafe?.name || 'cafe'}-qr-code.png`
      downloadLink.href = pngFile
      downloadLink.click()
    }

    img.src = 'data:image/svg+xml;base64,' + btoa(svgData)
  }

  const saveNfcTag = async () => {
    if (!cafe) return

    setSavingNfc(true)
    const supabase = createClient()

    await supabase
      .from('cafes')
      .update({ nfc_tag_id: nfcTagId || null })
      .eq('id', cafe.id)

    setSavingNfc(false)
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
        <h1 className="text-2xl font-bold text-gray-900">QR & NFC Setup</h1>
        <p className="text-gray-600">Set up stamps collection for your customers</p>
      </div>

      <div className="grid lg:grid-cols-2 gap-8">
        {/* QR Code Section */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 bg-amber-100 rounded-xl flex items-center justify-center">
              <QrCode className="w-5 h-5 text-amber-800" />
            </div>
            <div>
              <h2 className="font-semibold text-gray-900">QR Code</h2>
              <p className="text-sm text-gray-500">For first-time customers to download the app</p>
            </div>
          </div>

          <div className="flex justify-center mb-6">
            <div className="p-4 bg-white rounded-2xl border-2 border-gray-100">
              <QRCodeSVG
                id="qr-code"
                value={getQRUrl()}
                size={200}
                level="H"
                includeMargin
              />
            </div>
          </div>

          <div className="space-y-3">
            <div className="flex items-center gap-2 p-3 bg-gray-50 rounded-xl">
              <input
                type="text"
                value={getQRUrl()}
                readOnly
                className="flex-1 bg-transparent text-sm text-gray-600 outline-none"
              />
              <button
                onClick={() => copyToClipboard(getQRUrl())}
                className="p-2 hover:bg-gray-200 rounded-lg transition"
              >
                {copied ? (
                  <Check className="w-4 h-4 text-green-600" />
                ) : (
                  <Copy className="w-4 h-4 text-gray-500" />
                )}
              </button>
            </div>

            <button
              onClick={downloadQR}
              className="w-full flex items-center justify-center gap-2 bg-amber-800 text-white py-3 px-4 rounded-xl font-semibold hover:bg-amber-900 transition"
            >
              <Download className="w-4 h-4" />
              Download QR Code
            </button>
          </div>

          <div className="mt-6 p-4 bg-amber-50 rounded-xl">
            <p className="text-sm text-amber-800">
              <strong>Tip:</strong> Print this QR code and display it at your counter.
              First-time customers can scan it to download the app.
            </p>
          </div>
        </div>

        {/* NFC Setup Section */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 bg-blue-100 rounded-xl flex items-center justify-center">
              <Nfc className="w-5 h-5 text-blue-700" />
            </div>
            <div>
              <h2 className="font-semibold text-gray-900">NFC Tag Setup</h2>
              <p className="text-sm text-gray-500">For quick stamp collection</p>
            </div>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                NFC Tag ID (optional)
              </label>
              <input
                type="text"
                value={nfcTagId}
                onChange={(e) => setNfcTagId(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-amber-500 focus:border-transparent outline-none"
                placeholder="e.g., NFC-001"
              />
              <p className="text-sm text-gray-500 mt-1">
                Enter a unique ID for tracking purposes
              </p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                URL to program on NFC tag
              </label>
              <div className="flex items-center gap-2 p-3 bg-gray-50 rounded-xl">
                <input
                  type="text"
                  value={getNfcUrl()}
                  readOnly
                  className="flex-1 bg-transparent text-sm text-gray-600 outline-none"
                />
                <button
                  onClick={() => copyToClipboard(getNfcUrl())}
                  className="p-2 hover:bg-gray-200 rounded-lg transition"
                >
                  <Copy className="w-4 h-4 text-gray-500" />
                </button>
              </div>
            </div>

            <button
              onClick={saveNfcTag}
              disabled={savingNfc}
              className="w-full bg-blue-600 text-white py-3 px-4 rounded-xl font-semibold hover:bg-blue-700 transition disabled:opacity-50"
            >
              {savingNfc ? 'Saving...' : 'Save NFC Settings'}
            </button>
          </div>

          <div className="mt-6 p-4 bg-blue-50 rounded-xl">
            <p className="text-sm text-blue-800 mb-2">
              <strong>How to set up NFC:</strong>
            </p>
            <ol className="text-sm text-blue-800 space-y-1 list-decimal list-inside">
              <li>Buy NTAG213/215 NFC tags (₹30-50 each)</li>
              <li>Use an NFC writer app on your phone</li>
              <li>Write the URL above to the tag</li>
              <li>Stick the tag at your counter</li>
              <li>Customers tap their phone to collect stamps!</li>
            </ol>
          </div>
        </div>
      </div>

      {/* Instructions */}
      <div className="mt-8 bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
        <h2 className="font-semibold text-gray-900 mb-4">How It Works</h2>
        <div className="grid md:grid-cols-3 gap-6">
          <div className="text-center">
            <div className="w-12 h-12 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-3">
              <span className="text-xl font-bold text-amber-800">1</span>
            </div>
            <h3 className="font-medium text-gray-900 mb-1">First Visit</h3>
            <p className="text-sm text-gray-500">
              Customer scans QR code and downloads the app
            </p>
          </div>
          <div className="text-center">
            <div className="w-12 h-12 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-3">
              <span className="text-xl font-bold text-amber-800">2</span>
            </div>
            <h3 className="font-medium text-gray-900 mb-1">Collect Stamps</h3>
            <p className="text-sm text-gray-500">
              Customer taps NFC tag to collect a stamp each visit
            </p>
          </div>
          <div className="text-center">
            <div className="w-12 h-12 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-3">
              <span className="text-xl font-bold text-amber-800">3</span>
            </div>
            <h3 className="font-medium text-gray-900 mb-1">Earn Reward</h3>
            <p className="text-sm text-gray-500">
              After {cafe.stamps_required} stamps, they show you the redemption code
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
