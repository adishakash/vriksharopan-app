import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { Toaster } from 'react-hot-toast';

const inter = Inter({ subsets: ['latin'], display: 'swap' });

export const metadata: Metadata = {
  title: 'Vrisharopan - Plant a Tree, Change the World',
  description:
    'Plant trees across India for just ₹99/month. Track your tree with GPS, get monthly photos, and measure your environmental impact.',
  keywords: ['plant trees India', 'tree plantation', 'carbon offset India', 'vrisharopan'],
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || 'https://vrisharopan.in'),
  openGraph: {
    title: 'Vrisharopan - Plant a Tree, Change the World',
    description: 'Plant trees across India for just ₹99/month.',
    url: 'https://vrisharopan.in',
    siteName: 'Vrisharopan',
    images: [{ url: '/og-image.jpg', width: 1200, height: 630 }],
    type: 'website',
  },
  twitter: { card: 'summary_large_image', site: '@vrisharopan' },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.className}>
      <body className="bg-white">
        <Toaster position="top-right" />
        {children}
      </body>
    </html>
  );
}
