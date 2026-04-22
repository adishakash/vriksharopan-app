import { useQuery } from '@tanstack/react-query';
import {
  LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, Legend,
} from 'recharts';
import api from '../lib/api';

export default function AnalyticsPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['analytics'],
    queryFn: () => api.get('/admin/analytics?period=12').then((r) => r.data.data),
  });

  const fmt = (m) => {
    if (!m) return '';
    const [y, mo] = m.split('-');
    return new Date(y, mo - 1).toLocaleString('en-IN', { month: 'short', year: '2-digit' });
  };

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Analytics</h1>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Trees per Month */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="text-base font-semibold text-gray-900 mb-4">Trees Planted per Month</h2>
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={data?.treesPerMonth || []}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="month" tickFormatter={fmt} tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip labelFormatter={fmt} />
              <Bar dataKey="trees_planted" fill="#16a34a" name="Trees" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Revenue per Month */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="text-base font-semibold text-gray-900 mb-4">Revenue per Month (INR)</h2>
          <ResponsiveContainer width="100%" height={220}>
            <LineChart data={data?.revenuePerMonth || []}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="month" tickFormatter={fmt} tick={{ fontSize: 11 }} />
              <YAxis tickFormatter={(v) => `₹${(v / 1000).toFixed(0)}K`} tick={{ fontSize: 11 }} />
              <Tooltip formatter={(v) => `₹${Number(v).toLocaleString('en-IN')}`} labelFormatter={fmt} />
              <Line type="monotone" dataKey="revenue" stroke="#7c3aed" strokeWidth={2} dot={false} name="Revenue" />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Top Workers */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="text-base font-semibold text-gray-900 mb-4">Top Workers by Trees Planted</h2>
          <div className="space-y-3">
            {(data?.workerProductivity || []).map((w, i) => (
              <div key={w.id} className="flex items-center gap-3">
                <span className="w-6 text-center text-sm font-bold text-gray-400">#{i + 1}</span>
                <div className="flex-1">
                  <div className="flex justify-between text-sm">
                    <span className="font-medium">{w.name}</span>
                    <span className="text-gray-500">{w.total_trees_planted} trees</span>
                  </div>
                  <div className="mt-1 h-1.5 bg-gray-100 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-green-500 rounded-full"
                      style={{
                        width: `${Math.min(100, (w.total_trees_planted / (data?.workerProductivity?.[0]?.total_trees_planted || 1)) * 100)}%`,
                      }}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Top Customers */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="text-base font-semibold text-gray-900 mb-4">Top Customers by Trees</h2>
          <div className="space-y-3">
            {(data?.topCustomers || []).map((c, i) => (
              <div key={c.id} className="flex items-center gap-3">
                <span className="w-6 text-center text-sm font-bold text-gray-400">#{i + 1}</span>
                <div className="flex-1">
                  <div className="flex justify-between text-sm">
                    <span className="font-medium">{c.name}</span>
                    <span className="text-gray-500">
                      {c.total_trees} trees · ₹{Number(c.total_paid || 0).toLocaleString('en-IN')}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
