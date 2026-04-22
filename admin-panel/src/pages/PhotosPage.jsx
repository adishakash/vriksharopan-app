import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { CheckCircle, XCircle, ZoomIn } from 'lucide-react';
import toast from 'react-hot-toast';
import api from '../lib/api';
import { format } from 'date-fns';

export default function PhotosPage() {
  const [selected, setSelected] = useState(null);
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['pending-photos'],
    queryFn: () => api.get('/admin/photos/pending').then((r) => r.data.data),
    refetchInterval: 30000,
  });

  const moderateMutation = useMutation({
    mutationFn: ({ id, status }) => api.put(`/admin/photos/${id}/moderate`, { status }),
    onSuccess: (_, vars) => {
      toast.success(`Photo ${vars.status}.`);
      queryClient.invalidateQueries({ queryKey: ['pending-photos'] });
      setSelected(null);
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Action failed.'),
  });

  if (isLoading) {
    return (
      <div className="p-8">
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {[...Array(8)].map((_, i) => (
            <div key={i} className="h-48 bg-gray-200 animate-pulse rounded-xl" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Photo Review</h1>
        <span className="px-3 py-1 bg-yellow-100 text-yellow-800 rounded-full text-sm font-medium">
          {data?.length || 0} pending
        </span>
      </div>

      {data?.length === 0 ? (
        <div className="bg-white rounded-xl shadow-sm p-16 text-center">
          <CheckCircle className="w-12 h-12 text-green-500 mx-auto mb-3" />
          <p className="text-gray-500">All photos reviewed. No pending photos.</p>
        </div>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {data.map((photo) => (
            <div key={photo.id} className="bg-white rounded-xl shadow-sm overflow-hidden group">
              <div className="relative aspect-square">
                <img
                  src={photo.photo_url}
                  alt="Tree"
                  className="w-full h-full object-cover"
                />
                <button
                  onClick={() => setSelected(photo)}
                  className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity"
                >
                  <ZoomIn className="w-8 h-8 text-white" />
                </button>
              </div>
              <div className="p-3">
                <p className="text-xs font-medium text-gray-900">{photo.tree_number}</p>
                <p className="text-xs text-gray-500">{photo.worker_name}</p>
                <p className="text-xs text-gray-400 mt-0.5">
                  {photo.taken_at ? format(new Date(photo.taken_at), 'dd MMM yyyy') : ''}
                </p>
                <div className="flex gap-2 mt-2">
                  <button
                    onClick={() => moderateMutation.mutate({ id: photo.id, status: 'approved' })}
                    disabled={moderateMutation.isPending}
                    className="flex-1 flex items-center justify-center gap-1 py-1.5 bg-green-100 text-green-700 rounded-lg text-xs font-medium hover:bg-green-200"
                  >
                    <CheckCircle className="w-3 h-3" /> Approve
                  </button>
                  <button
                    onClick={() => moderateMutation.mutate({ id: photo.id, status: 'rejected' })}
                    disabled={moderateMutation.isPending}
                    className="flex-1 flex items-center justify-center gap-1 py-1.5 bg-red-100 text-red-700 rounded-lg text-xs font-medium hover:bg-red-200"
                  >
                    <XCircle className="w-3 h-3" /> Reject
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Lightbox */}
      {selected && (
        <div
          className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-8"
          onClick={() => setSelected(null)}
        >
          <div className="bg-white rounded-2xl overflow-hidden max-w-xl w-full" onClick={(e) => e.stopPropagation()}>
            <img src={selected.photo_url} alt="Tree" className="w-full max-h-96 object-contain" />
            <div className="p-6">
              <p className="font-semibold">{selected.tree_number}</p>
              <p className="text-sm text-gray-500">Worker: {selected.worker_name}</p>
              {selected.caption && <p className="text-sm mt-2">{selected.caption}</p>}
              <div className="flex gap-3 mt-4">
                <button
                  onClick={() => moderateMutation.mutate({ id: selected.id, status: 'approved' })}
                  className="flex-1 bg-green-600 text-white py-2 rounded-lg font-medium hover:bg-green-700"
                >
                  Approve
                </button>
                <button
                  onClick={() => moderateMutation.mutate({ id: selected.id, status: 'rejected' })}
                  className="flex-1 bg-red-600 text-white py-2 rounded-lg font-medium hover:bg-red-700"
                >
                  Reject
                </button>
                <button
                  onClick={() => setSelected(null)}
                  className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
