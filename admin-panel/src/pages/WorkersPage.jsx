import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import DataTable from 'react-data-table-component';
import { Search, CheckCircle, XCircle, UserCheck } from 'lucide-react';
import toast from 'react-hot-toast';
import api from '../lib/api';
import { format } from 'date-fns';

const StatusBadge = ({ status }) => {
  const styles = {
    active: 'bg-green-100 text-green-800',
    inactive: 'bg-gray-100 text-gray-800',
    suspended: 'bg-red-100 text-red-800',
    pending_approval: 'bg-yellow-100 text-yellow-800',
  };
  return (
    <span className={`px-2 py-1 rounded-full text-xs font-medium ${styles[status] || styles.inactive}`}>
      {status?.replace('_', ' ')}
    </span>
  );
};

export default function WorkersPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['workers', page, search, statusFilter],
    queryFn: () =>
      api.get('/admin/workers', { params: { page, limit: 20, search: search || undefined, status: statusFilter || undefined } })
         .then((r) => r.data.data),
    keepPreviousData: true,
  });

  const approveMutation = useMutation({
    mutationFn: (id) => api.put(`/admin/workers/${id}/approve`),
    onSuccess: () => {
      toast.success('Worker approved successfully.');
      queryClient.invalidateQueries({ queryKey: ['workers'] });
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Approval failed.'),
  });

  const columns = [
    { name: 'Name', selector: (r) => r.name, sortable: true },
    { name: 'Email', selector: (r) => r.email },
    { name: 'Mobile', selector: (r) => r.mobile || '—' },
    { name: 'Trees Planted', selector: (r) => r.total_trees_planted || 0, sortable: true, center: true },
    { name: 'Rating', selector: (r) => Number(r.rating || 5).toFixed(1), sortable: true, center: true },
    {
      name: 'Status',
      cell: (r) => <StatusBadge status={r.worker_status || r.status} />,
      center: true,
    },
    {
      name: 'Joined',
      selector: (r) => r.created_at ? format(new Date(r.created_at), 'dd MMM yyyy') : '—',
      sortable: true,
    },
    {
      name: 'Actions',
      cell: (r) => (
        <div className="flex gap-2">
          {r.worker_status === 'pending_approval' && (
            <button
              onClick={() => approveMutation.mutate(r.id)}
              className="flex items-center gap-1 px-2 py-1 bg-green-100 text-green-700 rounded text-xs hover:bg-green-200"
            >
              <UserCheck className="w-3 h-3" /> Approve
            </button>
          )}
        </div>
      ),
    },
  ];

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Workers Management</h1>

      {/* Filters */}
      <div className="bg-white rounded-xl shadow-sm p-4 mb-6 flex gap-4 items-center">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            placeholder="Search workers..."
            className="pl-9 pr-4 py-2 border border-gray-300 rounded-lg w-full text-sm outline-none focus:ring-2 focus:ring-green-500"
          />
        </div>
        <select
          value={statusFilter}
          onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
          className="border border-gray-300 rounded-lg px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-green-500"
        >
          <option value="">All Statuses</option>
          <option value="pending_approval">Pending Approval</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
          <option value="suspended">Suspended</option>
        </select>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <DataTable
          columns={columns}
          data={data?.workers || []}
          progressPending={isLoading}
          pagination
          paginationServer
          paginationTotalRows={data?.total || 0}
          onChangePage={setPage}
          paginationPerPage={20}
          noDataComponent={<div className="py-10 text-gray-500">No workers found.</div>}
          customStyles={{
            headRow: { style: { backgroundColor: '#f9fafb', borderBottom: '1px solid #e5e7eb' } },
            headCells: { style: { fontSize: '12px', fontWeight: '600', color: '#6b7280', textTransform: 'uppercase' } },
            cells: { style: { fontSize: '14px' } },
          }}
        />
      </div>
    </div>
  );
}
