'use client';

import { useState } from 'react';
import { Star, ChevronLeft, ChevronRight } from 'lucide-react';

const testimonials = [
  {
    name: 'Ritu Malhotra',
    city: 'Delhi',
    text: 'I planted 5 trees in my late father\'s memory. Every month I get photos and see them growing. It\'s deeply meaningful.',
    trees: 5,
    rating: 5,
    avatar: '👩‍💼',
  },
  {
    name: 'Kiran Bhat',
    city: 'Bengaluru',
    text: 'As a developer, I was skeptical. But the GPS tracking and monthly photos are real. My trees are actually growing!',
    trees: 3,
    rating: 5,
    avatar: '👨‍💻',
  },
  {
    name: 'Sunita Rao',
    city: 'Pune',
    text: 'Our company planted 200 trees for CSR. The reporting is excellent — we can share impact data with our investors.',
    trees: 200,
    rating: 5,
    avatar: '👩‍💼',
  },
  {
    name: 'Amit Verma',
    city: 'Jaipur',
    text: '₹99 per month for a real tree? I gifted one to my wife for her birthday. She got a beautiful digital certificate.',
    trees: 2,
    rating: 5,
    avatar: '👨‍🌾',
  },
];

export default function Testimonials() {
  const [current, setCurrent] = useState(0);

  const prev = () => setCurrent((c) => (c === 0 ? testimonials.length - 1 : c - 1));
  const next = () => setCurrent((c) => (c === testimonials.length - 1 ? 0 : c + 1));

  const t = testimonials[current];

  return (
    <section className="py-24 bg-green-50">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
        <h2 className="text-4xl font-extrabold text-gray-900 mb-3">Real People, Real Trees</h2>
        <p className="text-gray-600 mb-12">Join thousands of Indians who are making a difference.</p>

        <div className="bg-white rounded-3xl shadow-lg p-10 relative">
          {/* Stars */}
          <div className="flex justify-center gap-1 mb-6">
            {Array.from({ length: t.rating }).map((_, i) => (
              <Star key={i} className="w-5 h-5 text-yellow-400 fill-yellow-400" />
            ))}
          </div>

          <p className="text-xl text-gray-700 italic mb-8 leading-relaxed">&ldquo;{t.text}&rdquo;</p>

          <div className="flex items-center justify-center gap-3">
            <span className="text-4xl">{t.avatar}</span>
            <div className="text-left">
              <p className="font-bold text-gray-900">{t.name}</p>
              <p className="text-sm text-gray-500">{t.city} · {t.trees} tree{t.trees > 1 ? 's' : ''} planted</p>
            </div>
          </div>

          {/* Nav */}
          <div className="flex justify-center gap-3 mt-8">
            <button
              onClick={prev}
              className="w-10 h-10 rounded-full border border-gray-200 flex items-center justify-center hover:bg-green-50 transition-colors"
            >
              <ChevronLeft className="w-5 h-5 text-gray-600" />
            </button>
            {testimonials.map((_, i) => (
              <button
                key={i}
                onClick={() => setCurrent(i)}
                className={`w-2.5 h-2.5 rounded-full transition-colors ${i === current ? 'bg-green-600' : 'bg-gray-300'}`}
              />
            ))}
            <button
              onClick={next}
              className="w-10 h-10 rounded-full border border-gray-200 flex items-center justify-center hover:bg-green-50 transition-colors"
            >
              <ChevronRight className="w-5 h-5 text-gray-600" />
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
