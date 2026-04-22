import { Link, useLocation, Outlet } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import {
  LayoutDashboard, Users, Shovel, TreePine, CreditCard,
  Image, Bell, BarChart3, LogOut, Leaf, ChevronRight,
} from 'lucide-react';
import clsx from 'clsx';

const navItems = [
  { to: '/',              label: 'Dashboard',      icon: LayoutDashboard },
  { to: '/customers',     label: 'Customers',      icon: Users },
  { to: '/workers',       label: 'Workers',         icon: Shovel },
  { to: '/trees',         label: 'Trees',           icon: TreePine },
  { to: '/payments',      label: 'Payments',        icon: CreditCard },
  { to: '/photos',        label: 'Photo Review',    icon: Image },
  { to: '/notifications', label: 'Notifications',   icon: Bell },
  { to: '/analytics',     label: 'Analytics',       icon: BarChart3 },
];

export default function AdminLayout() {
  const { admin, logout } = useAuth();
  const { pathname } = useLocation();

  return (
    <div className="flex h-screen bg-gray-100 overflow-hidden">
      {/* Sidebar */}
      <aside className="w-64 bg-white shadow-lg flex flex-col flex-shrink-0">
        {/* Logo */}
        <div className="flex items-center gap-3 px-6 py-5 border-b">
          <div className="w-9 h-9 bg-green-600 rounded-lg flex items-center justify-center">
            <Leaf className="w-5 h-5 text-white" />
          </div>
          <div>
            <p className="font-bold text-gray-900 text-sm">Vrisharopan</p>
            <p className="text-xs text-gray-500">Admin Panel</p>
          </div>
        </div>

        {/* Nav */}
        <nav className="flex-1 px-4 py-4 space-y-1 overflow-y-auto">
          {navItems.map(({ to, label, icon: Icon }) => {
            const active = pathname === to || (to !== '/' && pathname.startsWith(to));
            return (
              <Link
                key={to}
                to={to}
                className={clsx(
                  'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
                  active
                    ? 'bg-green-50 text-green-700 border-l-2 border-green-600'
                    : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                )}
              >
                <Icon className="w-4 h-4 flex-shrink-0" />
                <span className="flex-1">{label}</span>
                {active && <ChevronRight className="w-3 h-3" />}
              </Link>
            );
          })}
        </nav>

        {/* User info + logout */}
        <div className="px-4 py-4 border-t">
          <div className="flex items-center gap-3 mb-3 px-3">
            <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center text-green-700 font-bold text-sm">
              {admin?.name?.[0]?.toUpperCase()}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-gray-900 truncate">{admin?.name}</p>
              <p className="text-xs text-gray-500 truncate">{admin?.role}</p>
            </div>
          </div>
          <button
            onClick={logout}
            className="flex items-center gap-2 w-full px-3 py-2 rounded-lg text-sm text-red-600 hover:bg-red-50 transition-colors"
          >
            <LogOut className="w-4 h-4" />
            Sign out
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main className="flex-1 overflow-y-auto">
        <Outlet />
      </main>
    </div>
  );
}
