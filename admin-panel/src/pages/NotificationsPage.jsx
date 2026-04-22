import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { Send, Bell } from 'lucide-react';
import toast from 'react-hot-toast';
import api from '../lib/api';

export default function NotificationsPage() {
  const [form, setForm] = useState({ title: '', body: '' });

  const broadcastMutation = useMutation({
    mutationFn: (data) => api.post('/admin/notifications/broadcast', data),
    onSuccess: () => {
      toast.success('Broadcast sent to all users.');
      setForm({ title: '', body: '' });
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Broadcast failed.'),
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!form.title.trim() || !form.body.trim()) {
      toast.error('Title and body are required.');
      return;
    }
    broadcastMutation.mutate(form);
  };

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold text-gray-900 mb-6 flex items-center gap-2">
        <Bell className="w-6 h-6 text-green-600" /> Notifications
      </h1>

      <div className="max-w-xl bg-white rounded-xl shadow-sm p-8">
        <h2 className="text-lg font-semibold mb-1">Send Broadcast Notification</h2>
        <p className="text-sm text-gray-500 mb-6">
          This will send a push notification to all active users with the app installed.
        </p>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Title</label>
            <input
              value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
              className="w-full border border-gray-300 rounded-lg px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-green-500"
              placeholder="Notification title"
              maxLength={100}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Message</label>
            <textarea
              value={form.body}
              onChange={(e) => setForm({ ...form, body: e.target.value })}
              rows={4}
              className="w-full border border-gray-300 rounded-lg px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-green-500 resize-none"
              placeholder="Notification message body..."
              maxLength={500}
            />
            <p className="text-xs text-gray-400 text-right">{form.body.length}/500</p>
          </div>
          <button
            type="submit"
            disabled={broadcastMutation.isPending}
            className="flex items-center gap-2 bg-green-600 hover:bg-green-700 disabled:bg-green-400 text-white px-6 py-2.5 rounded-lg font-medium text-sm transition"
          >
            <Send className="w-4 h-4" />
            {broadcastMutation.isPending ? 'Sending...' : 'Send Broadcast'}
          </button>
        </form>
      </div>
    </div>
  );
}
