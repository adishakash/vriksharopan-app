'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import axios from 'axios';
import toast from 'react-hot-toast';
import { Mail, Phone, MapPin, Send } from 'lucide-react';
import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';

const schema = z.object({
  name: z.string().min(2, 'Name required'),
  email: z.string().email('Valid email required'),
  subject: z.string().min(3, 'Subject required'),
  message: z.string().min(10, 'Message must be at least 10 characters'),
});

type FormData = z.infer<typeof schema>;

export default function ContactPage() {
  const [loading, setLoading] = useState(false);
  const { register, handleSubmit, reset, formState: { errors } } = useForm<FormData>({ resolver: zodResolver(schema) });

  const onSubmit = async (data: FormData) => {
    setLoading(true);
    try {
      // In production, POST to a contact endpoint or use a form service
      await new Promise((r) => setTimeout(r, 1000));
      toast.success('Message sent! We\'ll get back to you within 24 hours.');
      reset();
    } catch {
      toast.error('Failed to send. Please email us directly.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <Navbar />
      <main className="min-h-screen bg-gray-50 py-16 px-4">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-14">
            <h1 className="text-4xl font-extrabold text-gray-900 mb-4">Contact Us</h1>
            <p className="text-xl text-gray-600 max-w-xl mx-auto">
              Have a question about your tree, subscription, or a bulk order? We&apos;re here to help.
            </p>
          </div>

          <div className="grid lg:grid-cols-2 gap-12">
            {/* Info */}
            <div>
              <h2 className="text-xl font-bold text-gray-900 mb-6">Get in Touch</h2>
              <div className="space-y-5">
                {[
                  { icon: Mail, label: 'Email', value: 'hello@vrisharopan.in', href: 'mailto:hello@vrisharopan.in' },
                  { icon: Phone, label: 'Phone', value: '+91 99990 00000', href: 'tel:+919999000000' },
                  { icon: MapPin, label: 'Office', value: 'Mumbai, Maharashtra, India', href: '#' },
                ].map(({ icon: Icon, label, value, href }) => (
                  <a key={label} href={href} className="flex items-start gap-4 group">
                    <div className="w-10 h-10 bg-green-50 rounded-xl flex items-center justify-center flex-shrink-0 group-hover:bg-green-100 transition-colors">
                      <Icon className="w-5 h-5 text-green-600" />
                    </div>
                    <div>
                      <p className="text-xs text-gray-400 font-medium uppercase tracking-wide">{label}</p>
                      <p className="text-gray-900 font-medium">{value}</p>
                    </div>
                  </a>
                ))}
              </div>

              <div className="mt-10 bg-green-50 rounded-2xl p-6">
                <h3 className="font-bold text-gray-900 mb-2">Bulk / Corporate Orders?</h3>
                <p className="text-gray-600 text-sm">
                  Plant 100+ trees for your company&apos;s CSR initiative. Special pricing available.
                  Email us at <a href="mailto:corporate@vrisharopan.in" className="text-green-700 underline">corporate@vrisharopan.in</a>
                </p>
              </div>
            </div>

            {/* Form */}
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
              <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-medium text-gray-700 mb-1">Name *</label>
                    <input
                      {...register('name')}
                      className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-green-500"
                      placeholder="Arjun Sharma"
                    />
                    {errors.name && <p className="text-red-500 text-xs mt-1">{errors.name.message}</p>}
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-700 mb-1">Email *</label>
                    <input
                      type="email"
                      {...register('email')}
                      className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-green-500"
                      placeholder="you@email.com"
                    />
                    {errors.email && <p className="text-red-500 text-xs mt-1">{errors.email.message}</p>}
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-medium text-gray-700 mb-1">Subject *</label>
                  <input
                    {...register('subject')}
                    className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-green-500"
                    placeholder="Question about my subscription"
                  />
                  {errors.subject && <p className="text-red-500 text-xs mt-1">{errors.subject.message}</p>}
                </div>

                <div>
                  <label className="block text-xs font-medium text-gray-700 mb-1">Message *</label>
                  <textarea
                    {...register('message')}
                    rows={5}
                    className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-green-500 resize-none"
                    placeholder="Tell us how we can help..."
                  />
                  {errors.message && <p className="text-red-500 text-xs mt-1">{errors.message.message}</p>}
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="btn-primary w-full py-3"
                >
                  <Send className="w-4 h-4" />
                  {loading ? 'Sending...' : 'Send Message'}
                </button>
              </form>
            </div>
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}
