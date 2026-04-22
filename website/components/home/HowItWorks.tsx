'use client';

import { CreditCard, Shovel, Camera, BarChart3 } from 'lucide-react';

const steps = [
  {
    step: '01',
    icon: CreditCard,
    title: 'Subscribe for ₹99/month',
    description: 'Choose how many trees you want to plant. Pay securely via Razorpay. Cancel anytime.',
    color: 'bg-green-50 text-green-600',
  },
  {
    step: '02',
    icon: Shovel,
    title: 'We assign a local worker',
    description: 'A trained field worker near your selected region plants and cares for your tree.',
    color: 'bg-blue-50 text-blue-600',
  },
  {
    step: '03',
    icon: Camera,
    title: 'Get monthly photo updates',
    description: 'Your worker uploads geo-tagged photos every month so you can watch your tree grow.',
    color: 'bg-purple-50 text-purple-600',
  },
  {
    step: '04',
    icon: BarChart3,
    title: 'Track your real impact',
    description: 'See your CO₂ offset, oxygen generated, and environmental impact in real-time.',
    color: 'bg-orange-50 text-orange-600',
  },
];

export default function HowItWorks() {
  return (
    <section id="how-it-works" className="py-24 bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="text-4xl font-extrabold text-gray-900 mb-4">How It Works</h2>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            From subscription to a thriving tree — simple, transparent, and impactful.
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
          {steps.map(({ step, icon: Icon, title, description, color }, i) => (
            <div key={step} className="relative">
              {/* Connector line */}
              {i < steps.length - 1 && (
                <div className="hidden lg:block absolute top-8 left-full w-full h-0.5 bg-gradient-to-r from-green-200 to-transparent z-0" />
              )}

              <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow relative z-10">
                <div className="flex items-start gap-4 mb-4">
                  <div className={`w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 ${color}`}>
                    <Icon className="w-6 h-6" />
                  </div>
                  <span className="text-3xl font-black text-gray-100">{step}</span>
                </div>
                <h3 className="font-bold text-gray-900 mb-2">{title}</h3>
                <p className="text-gray-600 text-sm leading-relaxed">{description}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
