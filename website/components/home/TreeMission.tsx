import { Globe, Shield, Heart, Sprout } from 'lucide-react';

export default function TreeMission() {
  return (
    <section className="py-24 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid lg:grid-cols-2 gap-16 items-center">
          {/* Visual */}
          <div className="relative">
            <div className="bg-gradient-to-br from-green-100 to-emerald-100 rounded-3xl p-10 text-center">
              <div className="text-8xl mb-4">🌳</div>
              <p className="text-2xl font-bold text-gray-900 mb-2">21 Years to Maturity</p>
              <p className="text-gray-600 mb-8">Every tree you plant today keeps giving for decades</p>
              <div className="grid grid-cols-3 gap-4 text-center">
                {[
                  { year: 'Year 1', action: 'Sapling planted & geo-tagged' },
                  { year: 'Year 5', action: 'Absorbing 100+ kg CO₂' },
                  { year: 'Year 21+', action: 'Full canopy, thriving ecosystem' },
                ].map(({ year, action }) => (
                  <div key={year} className="bg-white rounded-xl p-3 shadow-sm">
                    <p className="font-bold text-green-700 text-sm">{year}</p>
                    <p className="text-xs text-gray-500 mt-1">{action}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Content */}
          <div>
            <h2 className="text-4xl font-extrabold text-gray-900 mb-4">
              Our Mission: A Greener India
            </h2>
            <p className="text-lg text-gray-600 mb-8 leading-relaxed">
              India has lost millions of hectares of forest cover in the last century.
              Vrisharopan is a people-powered movement to reverse that — one subscription at a time.
              Every rupee you spend directly plants and maintains a real tree.
            </p>

            <div className="space-y-5">
              {[
                {
                  icon: Globe,
                  title: 'Transparent & accountable',
                  desc: 'Every tree has GPS coordinates, a unique ID, and photo history. No greenwashing.',
                  color: 'text-blue-600 bg-blue-50',
                },
                {
                  icon: Heart,
                  title: 'Supporting rural livelihoods',
                  desc: 'Workers earn ₹20/tree/month — a reliable income for rural families across India.',
                  color: 'text-red-600 bg-red-50',
                },
                {
                  icon: Shield,
                  title: 'Long-term commitment',
                  desc: 'We plant native species that thrive in local conditions. Not just photo-ops.',
                  color: 'text-purple-600 bg-purple-50',
                },
                {
                  icon: Sprout,
                  title: 'Biodiversity first',
                  desc: 'We prioritize fruit trees, medicinal plants, and native species over monocultures.',
                  color: 'text-green-600 bg-green-50',
                },
              ].map(({ icon: Icon, title, desc, color }) => (
                <div key={title} className="flex items-start gap-4">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${color.split(' ')[1]}`}>
                    <Icon className={`w-5 h-5 ${color.split(' ')[0]}`} />
                  </div>
                  <div>
                    <p className="font-semibold text-gray-900">{title}</p>
                    <p className="text-gray-600 text-sm mt-0.5">{desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
