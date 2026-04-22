'use client';

import { useEffect } from 'react';
import Link from 'next/link';
import { CheckCircle, Download } from 'lucide-react';

export default function SuccessPage() {
  useEffect(() => {
    // Track conversion
    if (typeof window !== 'undefined' && (window as any).gtag) {
      (window as any).gtag('event', 'purchase', { currency: 'INR' });
    }
  }, []);

  return (
    <div className="min-h-screen bg-green-50 flex items-center justify-center px-4">
      <div className="bg-white rounded-3xl shadow-xl p-12 max-w-lg w-full text-center">
        <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6">
          <CheckCircle className="w-10 h-10 text-green-600" />
        </div>
        <h1 className="text-3xl font-extrabold text-gray-900 mb-3">Welcome to Vrisharopan! 🌳</h1>
        <p className="text-gray-600 mb-8">
          Your payment was successful. We&apos;re assigning a local worker to plant your tree.
          You&apos;ll receive your first update within 7 days.
        </p>

        <div className="bg-green-50 rounded-2xl p-6 mb-8 text-left space-y-3">
          <p className="text-sm font-semibold text-gray-900">What happens next?</p>
          {[
            'A worker near your region is assigned to plant your tree',
            "You'll receive a confirmation email with tree details",
            'Your tree will be geo-tagged and photographed within 7 days',
            'Monthly updates will be sent to your email and app',
          ].map((s, i) => (
            <div key={i} className="flex items-start gap-2 text-sm text-gray-600">
              <span className="w-5 h-5 rounded-full bg-green-200 text-green-700 flex items-center justify-center text-xs font-bold flex-shrink-0 mt-0.5">
                {i + 1}
              </span>
              {s}
            </div>
          ))}
        </div>

        <div className="flex flex-col gap-3">
          <a
            href="https://play.google.com/store"
            target="_blank"
            rel="noopener noreferrer"
            className="btn-primary justify-center"
          >
            <Download className="w-5 h-5" />
            Download the App to Track Your Tree
          </a>
          <Link href="/" className="btn-outline justify-center">
            Back to Home
          </Link>
        </div>
      </div>
    </div>
  );
}
