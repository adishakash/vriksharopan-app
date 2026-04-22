import Link from 'next/link';
import { Download, Smartphone } from 'lucide-react';

export default function DownloadApp() {
  return (
    <section className="py-24 bg-gradient-to-br from-green-700 to-emerald-800 text-white">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 grid lg:grid-cols-2 gap-12 items-center">
        <div>
          <div className="flex items-center gap-2 bg-green-600/50 text-green-100 px-4 py-2 rounded-full text-sm font-semibold mb-6 w-fit">
            <Smartphone className="w-4 h-4" />
            Android App — Free Download
          </div>
          <h2 className="text-4xl font-extrabold mb-4">
            Track Your Trees<br />on the Go
          </h2>
          <p className="text-green-100 text-lg mb-8 leading-relaxed">
            See real-time photos, GPS location, health status, and impact metrics
            for all your trees — right from your phone.
          </p>

          <div className="flex flex-col sm:flex-row gap-4">
            <a
              href="https://play.google.com/store"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-3 bg-white text-gray-900 hover:bg-gray-100 px-6 py-3.5 rounded-xl font-semibold transition-colors"
            >
              <Download className="w-5 h-5 text-green-600" />
              <div className="text-left">
                <p className="text-xs text-gray-500">Get it on</p>
                <p className="font-bold">Google Play</p>
              </div>
            </a>
          </div>

          <p className="mt-4 text-green-200 text-sm">
            iOS App coming soon
          </p>
        </div>

        {/* Mock phone */}
        <div className="hidden lg:flex justify-center">
          <div className="bg-white/10 border border-white/20 rounded-[2rem] p-4 w-56">
            <div className="bg-green-800/50 rounded-[1.5rem] h-96 flex flex-col items-center justify-center gap-4">
              <div className="text-5xl">🌳</div>
              <div className="text-center">
                <p className="font-bold text-lg">Tree VR-2024-000042</p>
                <p className="text-green-200 text-sm">Mango · Growing</p>
                <p className="text-xs text-green-300 mt-1">📍 Nashik, Maharashtra</p>
              </div>
              <div className="bg-green-600/50 rounded-xl px-4 py-2 text-sm">
                Last update: 2 days ago
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
