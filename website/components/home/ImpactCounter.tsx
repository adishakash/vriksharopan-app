'use client';

import { useInView } from 'react-intersection-observer';
import CountUp from 'react-countup';
import { TreePine, Wind, Users, MapPin } from 'lucide-react';

const stats = [
  { icon: TreePine, value: 50000, suffix: '+', label: 'Trees Planted', color: 'text-green-600' },
  { icon: Wind, value: 1088, suffix: ' tonnes', label: 'CO₂ Absorbed', color: 'text-blue-600' },
  { icon: Users, value: 12000, suffix: '+', label: 'Happy Customers', color: 'text-purple-600' },
  { icon: MapPin, value: 180, suffix: '+', label: 'Cities Covered', color: 'text-orange-600' },
];

export default function ImpactCounter() {
  const { ref, inView } = useInView({ triggerOnce: true, threshold: 0.2 });

  return (
    <section className="bg-white py-16 border-y border-gray-100">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div ref={ref} className="grid grid-cols-2 lg:grid-cols-4 gap-8">
          {stats.map(({ icon: Icon, value, suffix, label, color }) => (
            <div key={label} className="text-center">
              <div className={`w-12 h-12 rounded-2xl bg-gray-50 flex items-center justify-center mx-auto mb-3`}>
                <Icon className={`w-6 h-6 ${color}`} />
              </div>
              <div className={`text-3xl lg:text-4xl font-extrabold ${color} mb-1`}>
                {inView ? (
                  <CountUp end={value} duration={2.5} separator="," />
                ) : (
                  '0'
                )}
                {suffix}
              </div>
              <p className="text-gray-600 text-sm font-medium">{label}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
