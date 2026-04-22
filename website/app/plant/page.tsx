'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import axios from 'axios';
import toast from 'react-hot-toast';
import { TreePine, Minus, Plus, CheckCircle } from 'lucide-react';
import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';

const schema = z.object({
  name: z.string().min(2, 'Name is required'),
  email: z.string().email('Valid email required'),
  password: z
    .string()
    .min(8, 'Min 8 characters')
    .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, 'Must have upper, lower and number'),
  mobile: z.string().regex(/^[6-9]\d{9}$/, 'Valid 10-digit Indian mobile number'),
  address: z.string().min(5, 'Address required'),
  city: z.string().min(2, 'City required'),
  state: z.string().min(2, 'State required'),
  pin_code: z.string().regex(/^\d{6}$/, '6-digit PIN code required'),
  referral_code: z.string().optional(),
});

type FormData = z.infer<typeof schema>;

declare global {
  interface Window { Razorpay: any; }
}

export default function PlantPage() {
  const [treeCount, setTreeCount] = useState(1);
  const [loading, setLoading] = useState(false);
  const [registered, setRegistered] = useState(false);
  const [authToken, setAuthToken] = useState('');

  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const monthlyAmount = treeCount * 99;

  const loadRazorpay = (): Promise<boolean> => {
    return new Promise((resolve) => {
      if (window.Razorpay) { resolve(true); return; }
      const script = document.createElement('script');
      script.src = 'https://checkout.razorpay.com/v1/checkout.js';
      script.onload = () => resolve(true);
      script.onerror = () => resolve(false);
      document.body.appendChild(script);
    });
  };

  const onSubmit = async (data: FormData) => {
    setLoading(true);
    try {
      // 1. Register
      const registerRes = await axios.post('/api/auth/register', {
        ...data,
        role: 'customer',
      });

      const token = registerRes.data.data.accessToken;
      setAuthToken(token);
      setRegistered(true);

      // 2. Create subscription
      const subRes = await axios.post(
        '/api/payments/create-subscription',
        { tree_count: treeCount },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      const { subscriptionId, razorpayKeyId, amount } = subRes.data.data;

      // 3. Load Razorpay
      const loaded = await loadRazorpay();
      if (!loaded) {
        toast.error('Payment failed to load. Please try again.');
        setLoading(false);
        return;
      }

      const options = {
        key: razorpayKeyId,
        subscription_id: subscriptionId,
        name: 'Vrisharopan',
        description: `${treeCount} Tree(s) × ₹99/month`,
        image: '/logo.png',
        prefill: { name: data.name, email: data.email, contact: data.mobile },
        notes: { treeCount },
        theme: { color: '#16a34a' },
        handler: () => {
          toast.success('Payment successful! Welcome to Vrisharopan. 🌳');
          window.location.href = '/success';
        },
        modal: {
          ondismiss: () => {
            toast('Payment cancelled. You can retry from your account.');
            setLoading(false);
          },
        },
      };

      new window.Razorpay(options).open();
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const inlineError = (field: keyof FormData) =>
    errors[field] && (
      <p className="text-red-500 text-xs mt-1">{errors[field]!.message as string}</p>
    );

  return (
    <>
      <Navbar />
      <main className="min-h-screen bg-green-50 py-16 px-4">
        <div className="max-w-5xl mx-auto grid lg:grid-cols-2 gap-10">
          {/* Left: info panel */}
          <div>
            <h1 className="text-4xl font-extrabold text-gray-900 mb-4">
              Plant Your Tree Today
            </h1>
            <p className="text-gray-600 mb-8">
              Every tree is planted, photographed, and geo-tagged by a local worker.
              You receive monthly updates and can track it on the map forever.
            </p>

            {/* Tree counter */}
            <div className="bg-white rounded-2xl shadow-sm border border-green-100 p-6 mb-6">
              <p className="text-sm font-medium text-gray-600 mb-3">How many trees?</p>
              <div className="flex items-center gap-4">
                <button
                  onClick={() => setTreeCount((c) => Math.max(1, c - 1))}
                  className="w-10 h-10 rounded-full border-2 border-gray-200 flex items-center justify-center hover:border-green-500"
                >
                  <Minus className="w-4 h-4" />
                </button>
                <span className="text-4xl font-bold text-green-700 w-12 text-center">{treeCount}</span>
                <button
                  onClick={() => setTreeCount((c) => Math.min(100, c + 1))}
                  className="w-10 h-10 rounded-full border-2 border-gray-200 flex items-center justify-center hover:border-green-500"
                >
                  <Plus className="w-4 h-4" />
                </button>
              </div>
              <div className="mt-4 pt-4 border-t border-gray-100 flex justify-between">
                <span className="text-gray-600">Monthly cost</span>
                <span className="font-bold text-green-700 text-xl">₹{monthlyAmount}/month</span>
              </div>
            </div>

            {/* Benefits */}
            <ul className="space-y-3">
              {[
                'GPS-tagged tree location on live map',
                'Monthly health photos by your worker',
                'Tree health status updates',
                'Real-time CO₂ impact dashboard',
                'Share on social media',
                'Certificate of plantation',
              ].map((b) => (
                <li key={b} className="flex items-center gap-2 text-gray-700 text-sm">
                  <CheckCircle className="w-4 h-4 text-green-600 flex-shrink-0" />
                  {b}
                </li>
              ))}
            </ul>
          </div>

          {/* Right: form */}
          <div className="bg-white rounded-2xl shadow-lg border border-gray-100 p-8">
            <div className="flex items-center gap-2 mb-6">
              <TreePine className="w-5 h-5 text-green-600" />
              <h2 className="text-xl font-bold text-gray-900">Create Your Account</h2>
            </div>

            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-gray-700 mb-1">Full Name *</label>
                  <input {...register('name')} className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-green-500" placeholder="Arjun Sharma" />
                  {inlineError('name')}
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-700 mb-1">Mobile *</label>
                  <input {...register('mobile')} className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-green-500" placeholder="9876543210" />
                  {inlineError('mobile')}
                </div>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1">Email *</label>
                <input type="email" {...register('email')} className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-green-500" placeholder="arjun@email.com" />
                {inlineError('email')}
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1">Password *</label>
                <input type="password" {...register('password')} className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-green-500" placeholder="Min 8 chars, upper+lower+number" />
                {inlineError('password')}
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1">Address *</label>
                <input {...register('address')} className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-green-500" placeholder="House/Flat, Street, Area" />
                {inlineError('address')}
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block text-xs font-medium text-gray-700 mb-1">City *</label>
                  <input {...register('city')} className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-green-500" placeholder="Mumbai" />
                  {inlineError('city')}
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-700 mb-1">State *</label>
                  <input {...register('state')} className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-green-500" placeholder="Maharashtra" />
                  {inlineError('state')}
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-700 mb-1">PIN *</label>
                  <input {...register('pin_code')} className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-green-500" placeholder="400001" />
                  {inlineError('pin_code')}
                </div>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1">Referral Code (optional)</label>
                <input {...register('referral_code')} className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-green-500" placeholder="ABCD1234" />
              </div>

              <button
                type="submit"
                disabled={loading}
                className="btn-primary w-full text-base py-3 mt-2"
              >
                {loading ? 'Processing...' : `Plant ${treeCount} Tree${treeCount > 1 ? 's' : ''} – ₹${monthlyAmount}/month`}
              </button>

              <p className="text-xs text-center text-gray-500">
                By registering you agree to our{' '}
                <a href="/terms" className="text-green-600 underline">Terms</a> and{' '}
                <a href="/privacy" className="text-green-600 underline">Privacy Policy</a>.
                Secured by Razorpay.
              </p>
            </form>
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}
