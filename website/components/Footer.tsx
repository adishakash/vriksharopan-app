import Link from 'next/link';
import { Leaf, Twitter, Instagram, Facebook, Youtube, Mail, Phone } from 'lucide-react';

export default function Footer() {
  return (
    <footer className="bg-gray-900 text-gray-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-10 mb-12">
          {/* Brand */}
          <div className="col-span-2 md:col-span-1">
            <Link href="/" className="flex items-center gap-2 text-white font-bold text-lg mb-4">
              <div className="w-8 h-8 bg-green-600 rounded-lg flex items-center justify-center">
                <Leaf className="w-5 h-5 text-white" />
              </div>
              Vrisharopan
            </Link>
            <p className="text-sm text-gray-400 leading-relaxed">
              India&apos;s largest tree plantation and tracking platform. Plant trees. Track impact. Build a greener India.
            </p>
            <div className="flex gap-4 mt-5">
              {[Twitter, Instagram, Facebook, Youtube].map((Icon, i) => (
                <a key={i} href="#" className="w-8 h-8 bg-gray-800 hover:bg-green-600 rounded-lg flex items-center justify-center transition-colors">
                  <Icon className="w-4 h-4" />
                </a>
              ))}
            </div>
          </div>

          {/* Plant */}
          <div>
            <h4 className="text-white font-semibold mb-4">Plant Trees</h4>
            <ul className="space-y-2 text-sm">
              {['Plant a Tree', 'Gift a Tree', 'Adopt a Tree', 'Corporate Trees', 'Bulk Orders'].map((l) => (
                <li key={l}><a href="#" className="hover:text-green-400 transition-colors">{l}</a></li>
              ))}
            </ul>
          </div>

          {/* Company */}
          <div>
            <h4 className="text-white font-semibold mb-4">Company</h4>
            <ul className="space-y-2 text-sm">
              {['About Us', 'How It Works', 'Impact Dashboard', 'Blog', 'Join as Worker', 'Careers'].map((l) => (
                <li key={l}><a href="#" className="hover:text-green-400 transition-colors">{l}</a></li>
              ))}
            </ul>
          </div>

          {/* Contact */}
          <div>
            <h4 className="text-white font-semibold mb-4">Contact</h4>
            <ul className="space-y-3 text-sm">
              <li className="flex items-center gap-2">
                <Mail className="w-4 h-4 text-green-500 flex-shrink-0" />
                <a href="mailto:hello@vrisharopan.in" className="hover:text-green-400">hello@vrisharopan.in</a>
              </li>
              <li className="flex items-center gap-2">
                <Phone className="w-4 h-4 text-green-500 flex-shrink-0" />
                <a href="tel:+919999000000" className="hover:text-green-400">+91 99990 00000</a>
              </li>
            </ul>
            <div className="mt-5">
              <p className="text-xs text-gray-500 mb-2">Download App</p>
              <div className="flex flex-col gap-2">
                <a href="#" className="flex items-center gap-2 bg-gray-800 hover:bg-gray-700 px-3 py-2 rounded-lg text-xs transition-colors">
                  <span>📱</span> Google Play
                </a>
              </div>
            </div>
          </div>
        </div>

        <div className="border-t border-gray-800 pt-8 flex flex-col md:flex-row justify-between items-center gap-4">
          <p className="text-xs text-gray-500">
            © 2024 Vrisharopan. All rights reserved. Made with ❤️ in India.
          </p>
          <div className="flex gap-6 text-xs text-gray-500">
            <a href="/privacy" className="hover:text-gray-300">Privacy Policy</a>
            <a href="/terms" className="hover:text-gray-300">Terms of Service</a>
            <a href="/refund" className="hover:text-gray-300">Refund Policy</a>
          </div>
        </div>
      </div>
    </footer>
  );
}
