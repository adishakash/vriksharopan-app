'use client';

import Link from 'next/link';
import { motion } from 'framer-motion';
import { ArrowRight, TreePine, MapPin, Camera } from 'lucide-react';

export default function HeroSection() {
  return (
    <section className="relative overflow-hidden bg-gradient-to-br from-green-50 via-emerald-50 to-teal-50 min-h-[90vh] flex items-center">
      {/* Background decoration */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-[600px] h-[600px] bg-green-200/30 rounded-full blur-3xl" />
        <div className="absolute -bottom-40 -left-40 w-[400px] h-[400px] bg-emerald-200/40 rounded-full blur-3xl" />
      </div>

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 grid lg:grid-cols-2 gap-12 items-center">
        {/* Content */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
        >
          <div className="inline-flex items-center gap-2 bg-green-100 text-green-700 px-4 py-2 rounded-full text-sm font-semibold mb-6">
            <TreePine className="w-4 h-4" />
            Plant Trees. Track Growth. Change India.
          </div>

          <h1 className="text-5xl lg:text-6xl font-extrabold text-gray-900 leading-tight mb-6">
            Plant a Real Tree
            <span className="block text-green-600">for just ₹99/month</span>
          </h1>

          <p className="text-xl text-gray-600 mb-8 leading-relaxed">
            We plant, water, and care for your tree — anywhere in India.
            Track it live on the map, watch it grow through monthly photos,
            and measure your real environmental impact.
          </p>

          {/* Feature pills */}
          <div className="flex flex-wrap gap-3 mb-10">
            {[
              { icon: MapPin, text: 'GPS-tracked location' },
              { icon: Camera, text: 'Monthly photo updates' },
              { icon: TreePine, text: 'Dedicated care worker' },
            ].map(({ icon: Icon, text }) => (
              <div key={text} className="flex items-center gap-2 bg-white border border-green-100 px-3 py-1.5 rounded-full text-sm text-gray-700 shadow-sm">
                <Icon className="w-3.5 h-3.5 text-green-600" />
                {text}
              </div>
            ))}
          </div>

          <div className="flex flex-col sm:flex-row gap-4">
            <Link href="/plant" className="btn-primary text-lg px-8 py-4">
              Plant Your First Tree
              <ArrowRight className="w-5 h-5" />
            </Link>
            <Link href="/#how-it-works" className="btn-outline text-lg px-8 py-4">
              How It Works
            </Link>
          </div>

          <p className="mt-4 text-sm text-gray-500">
            ✓ No long-term commitment · ✓ Cancel anytime · ✓ Razorpay secured
          </p>
        </motion.div>

        {/* Illustration / Stats card */}
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.8, delay: 0.2 }}
          className="hidden lg:block"
        >
          <div className="relative bg-white rounded-3xl shadow-2xl p-8 border border-green-100">
            <div className="text-center mb-6">
              <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <TreePine className="w-10 h-10 text-green-600" />
              </div>
              <h3 className="text-xl font-bold text-gray-900">Your Tree Impact</h3>
              <p className="text-gray-500 text-sm">Per tree, per year</p>
            </div>

            <div className="space-y-4">
              {[
                { label: 'CO₂ Absorbed', value: '21.77 kg', color: 'text-green-600' },
                { label: 'Oxygen Generated', value: '100 kg', color: 'text-blue-600' },
                { label: 'Birds Sheltered', value: '3–5', color: 'text-orange-600' },
                { label: 'Water Conserved', value: '450 liters', color: 'text-cyan-600' },
              ].map(({ label, value, color }) => (
                <div key={label} className="flex justify-between items-center py-3 border-b border-gray-50 last:border-0">
                  <span className="text-gray-600 text-sm">{label}</span>
                  <span className={`font-bold ${color}`}>{value}</span>
                </div>
              ))}
            </div>

            <div className="mt-6 bg-green-50 rounded-xl p-4 text-center">
              <p className="text-green-800 font-semibold text-sm">
                10 trees = 217.7 kg CO₂ absorbed per year
              </p>
              <p className="text-green-600 text-xs mt-1">
                Equal to driving 870 km less
              </p>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
