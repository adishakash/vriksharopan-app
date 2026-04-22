'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import axios from 'axios';
import toast from 'react-hot-toast';
import { Gift, Heart } from 'lucide-react';
import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';

const schema = z.object({
  recipient_name: z.string().min(2, 'Recipient name required'),
  recipient_email: z.string().email('Valid email required'),
  message: z.string().max(200).optional(),
  occasion: z.enum(['birthday', 'anniversary', 'wedding', 'memorial', 'other']),
});

type FormData = z.infer<typeof schema>;

const occasions = [
  { value: 'birthday', label: '🎂 Birthday' },
  { value: 'anniversary', label: '💍 Anniversary' },
  { value: 'wedding', label: '💒 Wedding' },
  { value: 'memorial', label: '🕊️ Memorial' },
  { value: 'other', label: '🎁 Other' },
];

export default function GiftPage() {
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const router = useRouter();

  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { occasion: 'birthday' },
  });

  const onSubmit = async (data: FormData) => {
    const token = localStorage.getItem('access_token');
    if (!token) {
      toast.error('Please log in first to gift a tree.');
      router.push('/login');
      return;
    }

    setLoading(true);
    try {
      await axios.post('/api/trees/gift', data, {
        headers: { Authorization: `Bearer ${token}` },
      });
      toast.success('Tree gifted successfully! 🌳');
      setSuccess(true);
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Failed to gift tree. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  if (success) {
    return (
      <div className="min-h-screen bg-green-50 flex items-center justify-center px-4">
        <div className="bg-white rounded-3xl shadow-xl p-12 max-w-md text-center">
          <div className="w-20 h-20 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-6">
            <Heart className="w-10 h-10 text-purple-600" />
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-3">Gift sent! 🎉</h2>
          <p className="text-gray-600 mb-6">
            We&apos;ve notified the recipient. A tree will be planted in their name and they&apos;ll receive monthly updates.
          </p>
          <a href="/dashboard" className="btn-primary">Back to Dashboard</a>
        </div>
      </div>
    );
  }

  return (
    <>
      <Navbar />
      <main className="min-h-screen bg-purple-50 py-16 px-4">
        <div className="max-w-lg mx-auto">
          <div className="text-center mb-10">
            <div className="w-16 h-16 bg-purple-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
              <Gift className="w-8 h-8 text-purple-600" />
            </div>
            <h1 className="text-3xl font-extrabold text-gray-900 mb-2">Gift a Tree</h1>
            <p className="text-gray-600">
              Give the gift of nature. A real tree planted and tracked in someone&apos;s name.
            </p>
          </div>

          <div className="bg-white rounded-2xl shadow-lg border border-gray-100 p-8">
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1">Recipient&apos;s Name *</label>
                <input
                  {...register('recipient_name')}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-purple-500"
                  placeholder="Priya Patel"
                />
                {errors.recipient_name && <p className="text-red-500 text-xs mt-1">{errors.recipient_name.message}</p>}
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1">Recipient&apos;s Email *</label>
                <input
                  type="email"
                  {...register('recipient_email')}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-purple-500"
                  placeholder="priya@email.com"
                />
                {errors.recipient_email && <p className="text-red-500 text-xs mt-1">{errors.recipient_email.message}</p>}
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1">Occasion *</label>
                <select
                  {...register('occasion')}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-purple-500"
                >
                  {occasions.map((o) => (
                    <option key={o.value} value={o.value}>{o.label}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1">Personal Message (optional)</label>
                <textarea
                  {...register('message')}
                  rows={3}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-purple-500 resize-none"
                  placeholder="Write a heartfelt message..."
                />
                {errors.message && <p className="text-red-500 text-xs mt-1">{errors.message.message}</p>}
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-purple-600 hover:bg-purple-700 text-white font-semibold py-3 rounded-xl transition-colors"
              >
                {loading ? 'Sending Gift...' : '🌳 Gift a Tree'}
              </button>
            </form>
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}
