import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import DataTable from 'react-data-table-component';
import { Search, TreePine, MapPin } from 'lucide-react';
import api from '../lib/api';
import { format } from 'date-fns';

const HealthBadge = ({ health }) => {
  const styles = {
    healthy: 'bg-green-100 text-green-800',
    needs_water: 'bg-blue-100 text-blue-800',
    needs_fertilizer: 'bg-yellow-100 text-yellow-800',
    damaged: 'bg-red-100 text-red-800',
    dead: 'bg-gray-800 text-gray-100',
    unknown: 'bg-gray-100 text-gray-600',
  };
  return (
    <span className={`px-2 py-1 rounded-full text-xs font-medium ${styles[health] || styles.unknown}`}>
      {health?.replace('_', ' ')}
    </span>
  );
};

export default function TreesPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  const { data, isLoading } = useQuery({
    queryKey: ['trees-admin', page, search, statusFilter],
    queryFn: () =>
      api.get('/trees', { params: { page, limit: 20, status: statusFilter || undefined } })
         .then((r) => r.data.data),
    keepPreviousData: true,
  });

  const columns = [
    { name: 'Tree #', selector: (r) => r.tree_number, sortable: true },
    { name: 'Species', selector: (r) => r.common_name || r.species || '—' },
    { name: 'Customer', selector: (r) => r.customer_name || '—' },
    { name: 'Worker', selector: (r) => r.worker_name || 'Unassigned' },
    { name: 'Health', cell: (r) => <HealthBadge health={r.health} />, center: true },
    {
      name: 'Location',
      cell: (r) =>
        r.latitude && r.longitude ? (
          <a
            href={`https://maps.google.com/?q=${r.latitude},${r.longitude}`}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1 text-blue-600 text-xs hover:underline"
          >
            <MapPin className="w-3 h-3" /> View Map
          </a>
        ) : (
          <span className="text-gray-400 text-xs">No location</span>
        ),
      center: true,
    },
    {
      name: 'Planted',
      selector: (r) => r.planted_at ? format(new Date(r.planted_at), 'dd MMM yyyy') : 'Not yet',
    },
  ];

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold text-gray-900 mb-6 flex items-center gap-2">
        <TreePine className="w-6 h-6 text-green-600" /> Tree Management
      </h1>

      <div className="bg-white rounded-xl shadow-sm p-4 mb-6 flex gap-4">
        <select
          value={statusFilter}
          onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
          className="border border-gray-300 rounded-lg px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-green-500"
        >
          <option value="">All Statuses</option>
          <option value="pending_assignment">Pending Assignment</option>
          <option value="assigned">Assigned</option>
          <option value="planted">Planted</option>
          <option value="active">Active</option>
        </select>
      </div>

      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <DataTable
          columns={columns}
          data={data?.trees || []}
          progressPending={isLoading}
          pagination
          paginationServer
          paginationTotalRows={data?.total || 0}
          onChangePage={setPage}
          paginationPerPage={20}
          noDataComponent={<div className="py-10 text-gray-500">No trees found.</div>}
          customStyles={{
            headRow: { style: { backgroundColor: '#f9fafb', borderBottom: '1px solid #e5e7eb' } },
            headCells: { style: { fontSize: '12px', fontWeight: '600', color: '#6b7280', textTransform: 'uppercase' } },
          }}
        />
      </div>
    </div>
  );
}
