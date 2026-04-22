import { useQuery } from '@tanstack/react-query';
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar
} from 'recharts';
import { Users, Shovel, TreePine, IndianRupee, TrendingUp } from 'lucide-react';
import api from '../lib/api';

const StatCard = ({ title, value, icon: Icon, color, subtitle }) => (
  <div className="bg-white rounded-xl shadow-sm p-6 flex items-start gap-4">
    <div className={`w-12 h-12 ${color} rounded-xl flex items-center justify-center flex-shrink-0`}>
      <Icon className="w-6 h-6 text-white" />
    </div>
    <div>
      <p className="text-sm text-gray-500">{title}</p>
      <p className="text-2xl font-bold text-gray-900 mt-0.5">{value}</p>
      {subtitle && <p className="text-xs text-green-600 mt-1">{subtitle}</p>}
    </div>
  </div>
);

export default function DashboardPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['admin-dashboard'],
    queryFn: () => api.get('/admin/dashboard').then((r) => r.data.data),
    refetchInterval: 60000,
  });

  if (isLoading) {
    return (
      <div className="p-8">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-28 bg-gray-200 animate-pulse rounded-xl" />
          ))}
        </div>
      </div>
    );
  }

  const formatCurrency = (val) => `₹${Number(val || 0).toLocaleString('en-IN')}`;
  const formatMonth = (m) => {
    if (!m) return '';
    const [year, month] = m.split('-');
    return new Date(year, month - 1).toLocaleString('en-IN', { month: 'short', year: '2-digit' });
  };

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Dashboard</h1>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatCard
          title="Total Customers"
          value={data?.totalCustomers?.toLocaleString() || '0'}
          icon={Users}
          color="bg-blue-500"
        />
        <StatCard
          title="Active Workers"
          value={data?.totalWorkers?.toLocaleString() || '0'}
          icon={Shovel}
          color="bg-orange-500"
        />
        <StatCard
          title="Total Trees"
          value={data?.totalTrees?.toLocaleString() || '0'}
          icon={TreePine}
          color="bg-green-500"
        />
        <StatCard
          title="Total Revenue"
          value={formatCurrency(data?.totalRevenue)}
          icon={IndianRupee}
          color="bg-purple-500"
        />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Revenue Chart */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="text-base font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <TrendingUp className="w-4 h-4 text-green-600" />
            Monthly Revenue (INR)
          </h2>
          <ResponsiveContainer width="100%" height={220}>
            <LineChart data={data?.monthlyRevenue || []}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="month" tickFormatter={formatMonth} tick={{ fontSize: 11 }} />
              <YAxis tickFormatter={(v) => `₹${(v/1000).toFixed(0)}K`} tick={{ fontSize: 11 }} />
              <Tooltip formatter={(v) => formatCurrency(v)} labelFormatter={formatMonth} />
              <Line type="monotone" dataKey="revenue" stroke="#16a34a" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Trees by Status */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="text-base font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <TreePine className="w-4 h-4 text-green-600" />
            Trees by Status
          </h2>
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={data?.treesByStatus || []}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="status" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip />
              <Bar dataKey="count" fill="#16a34a" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
