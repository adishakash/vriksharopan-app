import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import DataTable from 'react-data-table-component';
import api from '../lib/api';
import { format } from 'date-fns';
import { IndianRupee } from 'lucide-react';

const StatusBadge = ({ status }) => {
  const styles = {
    captured: 'bg-green-100 text-green-800',
    pending: 'bg-yellow-100 text-yellow-800',
    failed: 'bg-red-100 text-red-800',
    refunded: 'bg-gray-100 text-gray-800',
  };
  return (
    <span className={`px-2 py-1 rounded-full text-xs font-medium ${styles[status] || styles.pending}`}>
      {status}
    </span>
  );
};

export default function PaymentsPage() {
  const [page, setPage] = useState(1);

  const { data, isLoading } = useQuery({
    queryKey: ['payments-admin', page],
    queryFn: () =>
      api.get('/payments', { params: { page, limit: 20 } }).then((r) => r.data.data),
    keepPreviousData: true,
  });

  const columns = [
    { name: 'Payment ID', selector: (r) => r.razorpay_payment_id || '—', grow: 2 },
    { name: 'Amount', selector: (r) => `₹${Number(r.amount).toLocaleString('en-IN')}`, sortable: true },
    { name: 'Type', selector: (r) => r.payment_type },
    { name: 'Method', selector: (r) => r.method || '—' },
    { name: 'Status', cell: (r) => <StatusBadge status={r.status} />, center: true },
    {
      name: 'Date',
      selector: (r) => r.created_at ? format(new Date(r.created_at), 'dd MMM yyyy HH:mm') : '—',
      sortable: true,
    },
  ];

  const totalRevenue = (data?.payments || [])
    .filter((p) => p.status === 'captured')
    .reduce((sum, p) => sum + parseFloat(p.amount || 0), 0);

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold text-gray-900 mb-6 flex items-center gap-2">
        <IndianRupee className="w-6 h-6 text-green-600" /> Payments
      </h1>

      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <DataTable
          columns={columns}
          data={data?.payments || []}
          progressPending={isLoading}
          pagination
          paginationServer
          paginationTotalRows={data?.total || 0}
          onChangePage={setPage}
          paginationPerPage={20}
          noDataComponent={<div className="py-10 text-gray-500">No payments found.</div>}
          customStyles={{
            headRow: { style: { backgroundColor: '#f9fafb', borderBottom: '1px solid #e5e7eb' } },
            headCells: { style: { fontSize: '12px', fontWeight: '600', color: '#6b7280', textTransform: 'uppercase' } },
          }}
        />
      </div>
    </div>
  );
}
