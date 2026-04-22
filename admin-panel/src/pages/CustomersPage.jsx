import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import DataTable from 'react-data-table-component';
import { Search } from 'lucide-react';
import toast from 'react-hot-toast';
import api from '../lib/api';
import { format } from 'date-fns';

const StatusBadge = ({ status }) => {
  const styles = {
    active: 'bg-green-100 text-green-800',
    inactive: 'bg-gray-100 text-gray-800',
    suspended: 'bg-red-100 text-red-800',
  };
  return (
    <span className={`px-2 py-1 rounded-full text-xs font-medium ${styles[status] || styles.inactive}`}>
      {status}
    </span>
  );
};

export default function CustomersPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['customers', page, search],
    queryFn: () =>
      api.get('/admin/customers', { params: { page, limit: 20, search: search || undefined } })
         .then((r) => r.data.data),
    keepPreviousData: true,
  });

  const toggleStatusMutation = useMutation({
    mutationFn: ({ id, status }) => api.put(`/admin/customers/${id}/status`, { status }),
    onSuccess: () => {
      toast.success('Customer status updated.');
      queryClient.invalidateQueries({ queryKey: ['customers'] });
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Update failed.'),
  });

  const columns = [
    { name: 'Name', selector: (r) => r.name, sortable: true },
    { name: 'Email', selector: (r) => r.email },
    { name: 'Mobile', selector: (r) => r.mobile || '—' },
    { name: 'Total Trees', selector: (r) => r.total_trees || 0, sortable: true, center: true },
    { name: 'Active Trees', selector: (r) => r.active_trees || 0, sortable: true, center: true },
    { name: 'Status', cell: (r) => <StatusBadge status={r.status} />, center: true },
    {
      name: 'Joined',
      selector: (r) => r.created_at ? format(new Date(r.created_at), 'dd MMM yyyy') : '—',
      sortable: true,
    },
    {
      name: 'Actions',
      cell: (r) => (
        <button
          onClick={() =>
            toggleStatusMutation.mutate({
              id: r.id,
              status: r.status === 'active' ? 'suspended' : 'active',
            })
          }
          className={`px-2 py-1 rounded text-xs font-medium ${
            r.status === 'active'
              ? 'bg-red-100 text-red-700 hover:bg-red-200'
              : 'bg-green-100 text-green-700 hover:bg-green-200'
          }`}
        >
          {r.status === 'active' ? 'Suspend' : 'Activate'}
        </button>
      ),
    },
  ];

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Customer Management</h1>
      <div className="bg-white rounded-xl shadow-sm p-4 mb-6 flex gap-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            placeholder="Search customers..."
            className="pl-9 pr-4 py-2 border border-gray-300 rounded-lg w-full text-sm outline-none focus:ring-2 focus:ring-green-500"
          />
        </div>
      </div>
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <DataTable
          columns={columns}
          data={data?.customers || []}
          progressPending={isLoading}
          pagination
          paginationServer
          paginationTotalRows={data?.total || 0}
          onChangePage={setPage}
          paginationPerPage={20}
          noDataComponent={<div className="py-10 text-gray-500">No customers found.</div>}
          customStyles={{
            headRow: { style: { backgroundColor: '#f9fafb', borderBottom: '1px solid #e5e7eb' } },
            headCells: { style: { fontSize: '12px', fontWeight: '600', color: '#6b7280', textTransform: 'uppercase' } },
          }}
        />
      </div>
    </div>
  );
}
