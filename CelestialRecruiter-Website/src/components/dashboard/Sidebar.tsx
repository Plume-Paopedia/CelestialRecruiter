'use client';

import { DASHBOARD_MODULES } from '@/lib/constants';
import { useTier } from './TierContext';
import { useData } from './DataContext';

interface SidebarProps {
  activeModule: string;
  onModuleChange: (id: string) => void;
}

export function Sidebar({ activeModule, onModuleChange }: SidebarProps) {
  const { hasAccess } = useTier();
  const { isLive } = useData();

  return (
    <aside className="dashboard-sidebar">
      <div className="sidebar-brand">
        <a href="/">Celestial Recruiter</a>
      </div>

      <nav className="sidebar-nav" aria-label="Dashboard navigation">
        <div className="sidebar-section-label">Recruitment</div>
        {DASHBOARD_MODULES.filter(m => ['overview', 'scanner', 'queue', 'templates', 'blacklist'].includes(m.id)).map((mod) => {
          const locked = !hasAccess(mod.minTier);
          return (
            <button
              key={mod.id}
              className={`sidebar-link ${activeModule === mod.id ? 'active' : ''} ${locked ? 'locked' : ''}`}
              onClick={() => !locked && onModuleChange(mod.id)}
              aria-current={activeModule === mod.id ? 'page' : undefined}
              aria-disabled={locked}
              aria-label={`${mod.label}${locked ? ' (locked)' : ''}`}
            >
              <span className="link-icon" aria-hidden="true">{mod.icon}</span>
              <span className="link-label">{mod.label}</span>
              {locked && <span className="lock-badge" aria-hidden="true">{'\u{1F512}'}</span>}
            </button>
          );
        })}

        <div className="sidebar-section-label">Intelligence</div>
        {DASHBOARD_MODULES.filter(m => ['analytics', 'campaigns'].includes(m.id)).map((mod) => {
          const locked = !hasAccess(mod.minTier);
          return (
            <button
              key={mod.id}
              className={`sidebar-link ${activeModule === mod.id ? 'active' : ''} ${locked ? 'locked' : ''}`}
              onClick={() => !locked && onModuleChange(mod.id)}
              aria-current={activeModule === mod.id ? 'page' : undefined}
              aria-disabled={locked}
              aria-label={`${mod.label}${locked ? ' (locked)' : ''}`}
            >
              <span className="link-icon" aria-hidden="true">{mod.icon}</span>
              <span className="link-label">{mod.label}</span>
              {locked && <span className="lock-badge" aria-hidden="true">{'\u{1F512}'}</span>}
            </button>
          );
        })}

        <div className="sidebar-section-label">Integrations</div>
        {DASHBOARD_MODULES.filter(m => ['discord'].includes(m.id)).map((mod) => {
          const locked = !hasAccess(mod.minTier);
          return (
            <button
              key={mod.id}
              className={`sidebar-link ${activeModule === mod.id ? 'active' : ''} ${locked ? 'locked' : ''}`}
              onClick={() => !locked && onModuleChange(mod.id)}
              aria-current={activeModule === mod.id ? 'page' : undefined}
              aria-disabled={locked}
              aria-label={`${mod.label}${locked ? ' (locked)' : ''}`}
            >
              <span className="link-icon" aria-hidden="true">{mod.icon}</span>
              <span className="link-label">{mod.label}</span>
              {locked && <span className="lock-badge" aria-hidden="true">{'\u{1F512}'}</span>}
            </button>
          );
        })}

        <div className="sidebar-section-label">System</div>
        {DASHBOARD_MODULES.filter(m => ['settings'].includes(m.id)).map((mod) => (
          <button
            key={mod.id}
            className={`sidebar-link ${activeModule === mod.id ? 'active' : ''}`}
            onClick={() => onModuleChange(mod.id)}
            aria-current={activeModule === mod.id ? 'page' : undefined}
            aria-label={mod.label}
          >
            <span className="link-icon" aria-hidden="true">{mod.icon}</span>
            <span className="link-label">{mod.label}</span>
          </button>
        ))}

        {/* Import link */}
        <a
          href="/dashboard/import"
          className="sidebar-link import-link"
          style={{ textDecoration: 'none' }}
        >
          <span className="link-icon">{'\u21E7'}</span>
          <span className="link-label">Import Data</span>
          {isLive && <span className="live-dot" />}
        </a>
      </nav>
    </aside>
  );
}
