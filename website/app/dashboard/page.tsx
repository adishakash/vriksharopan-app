'use client';

import { useEffect, useState } from 'react';
import Image from 'next/image';
import { useRouter } from 'next/navigation';
import axios from 'axios';
import Link from 'next/link';
import { TreePine, Wind, Leaf, Gift, LogOut, User } from 'lucide-react';
import toast from 'react-hot-toast';

interface DashboardData {
  total_trees: number;
  active_trees: number;
  total_co2_absorbed: number;
  total_oxygen_generated: number;
  trees: any[];
}

export default function DashboardPage() {
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [user, setUser] = useState<any>(null);
  const router = useRouter();

  useEffect(() => {
    const token = localStorage.getItem('access_token');
    const userStr = localStorage.getItem('user');
    const parsedUser = userStr ? JSON.parse(userStr) : null;

    if (!token) { router.push('/login'); return; }

    axios
      .get('/api/customers/dashboard', { headers: { Authorization: `Bearer ${token}` } })
      .then((res) => {
        setData(res.data.data);
        if (parsedUser) {
          setUser(parsedUser);
        }
      })
      .catch(() => { router.push('/login'); })
      .finally(() => setLoading(false));
  }, [router]);

  const logout = () => {
    localStorage.clear();
    toast.success('Logged out');
    router.push('/');
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-green-50 flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-green-600 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-gray-600">Loading your impact dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-green-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-100 sticky top-0 z-20 shadow-sm">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 py-4 flex justify-between items-center">
          <Link href="/" className="flex items-center gap-2 font-bold text-gray-900">
            <div className="w-7 h-7 bg-green-600 rounded-lg flex items-center justify-center">
              <Leaf className="w-4 h-4 text-white" />
            </div>
            Vrisharopan
          </Link>
          <div className="flex items-center gap-4">
            <span className="text-sm text-gray-600 hidden md:block">
              <User className="w-4 h-4 inline mr-1" />
              {user?.name}
            </span>
            <button onClick={logout} className="flex items-center gap-1 text-sm text-red-500 hover:text-red-700">
              <LogOut className="w-4 h-4" /> Logout
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-4 sm:px-6 py-10">
        <h1 className="text-2xl font-bold text-gray-900 mb-2">Your Environmental Impact</h1>
        <p className="text-gray-500 mb-8 text-sm">Every tree you plant is working hard for the planet.</p>

        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-5 mb-10">
          {[
            { icon: TreePine, label: 'Total Trees', value: data?.total_trees ?? 0, unit: '', color: 'text-green-600 bg-green-50' },
            { icon: TreePine, label: 'Active Trees', value: data?.active_trees ?? 0, unit: '', color: 'text-emerald-600 bg-emerald-50' },
            { icon: Wind, label: 'CO₂ Absorbed', value: Number(data?.total_co2_absorbed ?? 0).toFixed(1), unit: ' kg/yr', color: 'text-blue-600 bg-blue-50' },
            { icon: Leaf, label: 'Oxygen Generated', value: Number(data?.total_oxygen_generated ?? 0).toFixed(0), unit: ' kg/yr', color: 'text-teal-600 bg-teal-50' },
          ].map(({ icon: Icon, label, value, unit, color }) => (
            <div key={label} className="bg-white rounded-2xl p-5 shadow-sm border border-gray-100">
              <div className={`w-10 h-10 rounded-xl flex items-center justify-center mb-3 ${color.split(' ')[1]}`}>
                <Icon className={`w-5 h-5 ${color.split(' ')[0]}`} />
              </div>
              <p className="text-2xl font-bold text-gray-900">{value}{unit}</p>
              <p className="text-xs text-gray-500 mt-0.5">{label}</p>
            </div>
          ))}
        </div>

        {/* CTA to plant more / gift */}
        <div className="grid md:grid-cols-2 gap-5 mb-10">
          <Link href="/plant" className="bg-green-600 hover:bg-green-700 text-white rounded-2xl p-6 flex items-center gap-4 transition-colors">
            <TreePine className="w-8 h-8 flex-shrink-0" />
            <div>
              <p className="font-bold text-lg">Plant More Trees</p>
              <p className="text-green-100 text-sm">Add more trees to your subscription for ₹99/tree/month</p>
            </div>
          </Link>
          <Link href="/gift" className="bg-purple-600 hover:bg-purple-700 text-white rounded-2xl p-6 flex items-center gap-4 transition-colors">
            <Gift className="w-8 h-8 flex-shrink-0" />
            <div>
              <p className="font-bold text-lg">Gift a Tree</p>
              <p className="text-purple-100 text-sm">Dedicate a tree to someone special for any occasion</p>
            </div>
          </Link>
        </div>

        {/* Trees list */}
        <h2 className="text-lg font-bold text-gray-900 mb-4">Your Trees</h2>
        {data?.trees && data.trees.length > 0 ? (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5">
            {data.trees.map((tree: any) => (
              <div key={tree.id} className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                {tree.cover_photo_url ? (
                  <Image
                    src={tree.cover_photo_url}
                    alt={tree.tree_number}
                    width={640}
                    height={144}
                    className="w-full h-36 object-cover"
                  />
                ) : (
                  <div className="w-full h-36 bg-green-50 flex items-center justify-center">
                    <TreePine className="w-10 h-10 text-green-200" />
                  </div>
                )}
                <div className="p-4">
                  <div className="flex justify-between items-start mb-2">
                    <p className="font-bold text-gray-900 text-sm">{tree.tree_number}</p>
                    <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                      tree.status === 'planted' ? 'bg-green-100 text-green-700' :
                      tree.status === 'growing' ? 'bg-blue-100 text-blue-700' :
                      'bg-gray-100 text-gray-600'
                    }`}>
                      {tree.status}
                    </span>
                  </div>
                  <p className="text-xs text-gray-500">{tree.species_name || 'Species TBD'}</p>
                  {tree.location_name && (
                    <p className="text-xs text-gray-400 mt-1">📍 {tree.location_name}</p>
                  )}
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="bg-white rounded-2xl border border-gray-100 p-12 text-center">
            <TreePine className="w-12 h-12 text-green-200 mx-auto mb-4" />
            <p className="text-gray-500 mb-4">Your trees are being planted. Check back soon!</p>
            <Link href="/plant" className="btn-primary">Plant Your First Tree</Link>
          </div>
        )}
      </main>
    </div>
  );
}
