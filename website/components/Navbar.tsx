'use client';

import Link from 'next/link';
import { useState } from 'react';
import { Leaf, Menu, X } from 'lucide-react';

const navLinks = [
  { href: '/#how-it-works', label: 'How It Works' },
  { href: '/#impact', label: 'Impact' },
  { href: '/plant', label: 'Plant a Tree' },
  { href: '/gift', label: 'Gift a Tree' },
  { href: '/blog', label: 'Blog' },
  { href: '/contact', label: 'Contact' },
];

export default function Navbar() {
  const [open, setOpen] = useState(false);

  return (
    <header className="sticky top-0 z-50 bg-white/90 backdrop-blur-md border-b border-gray-100 shadow-sm">
      <nav className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex items-center justify-between h-16">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-2 font-bold text-xl text-gray-900">
          <div className="w-8 h-8 bg-green-600 rounded-lg flex items-center justify-center">
            <Leaf className="w-5 h-5 text-white" />
          </div>
          Vrisharopan
        </Link>

        {/* Desktop nav */}
        <ul className="hidden md:flex items-center gap-6 text-sm font-medium text-gray-600">
          {navLinks.map(({ href, label }) => (
            <li key={href}>
              <Link href={href} className="hover:text-green-700 transition-colors">
                {label}
              </Link>
            </li>
          ))}
        </ul>

        {/* CTA */}
        <div className="hidden md:flex items-center gap-3">
          <Link href="/login" className="text-sm font-medium text-gray-600 hover:text-green-700">
            Login
          </Link>
          <Link href="/plant" className="btn-primary text-sm py-2 px-4">
            Plant a Tree ₹99/mo
          </Link>
        </div>

        {/* Mobile menu button */}
        <button
          className="md:hidden p-2 rounded-lg hover:bg-gray-100"
          onClick={() => setOpen(!open)}
          aria-label="Toggle menu"
        >
          {open ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
        </button>
      </nav>

      {/* Mobile nav */}
      {open && (
        <div className="md:hidden border-t border-gray-100 bg-white px-4 py-4 space-y-3">
          {navLinks.map(({ href, label }) => (
            <Link
              key={href}
              href={href}
              className="block text-sm font-medium text-gray-700 hover:text-green-700 py-2"
              onClick={() => setOpen(false)}
            >
              {label}
            </Link>
          ))}
          <Link href="/plant" className="btn-primary w-full text-center text-sm">
            Plant a Tree – ₹99/month
          </Link>
        </div>
      )}
    </header>
  );
}
