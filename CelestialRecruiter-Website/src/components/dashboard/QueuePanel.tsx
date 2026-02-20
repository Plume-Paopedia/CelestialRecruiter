'use client';

import { useMemo } from 'react';
import { CLASS_COLORS } from '@/lib/constants';
import { useData } from '@/components/dashboard/DataContext';

function getClassColor(className: string): string {
  const key = className.toLowerCase().replace(' ', '-');
  return CLASS_COLORS[key] || '#d4c5a9';
}

function formatTimestamp(ts?: number): string {
  if (!ts) return 'Unknown';
  const diff = Math.floor((Date.now() / 1000) - ts);
  if (diff < 60) return 'just now';
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return `${Math.floor(diff / 86400)}d ago`;
}

export function QueuePanel() {
  const { data } = useData();

  const queueEntries = useMemo(() => {
    if (!data) return [];

    const contacts = data.contacts;
    const queueKeys = data.queue || Object.keys(contacts).filter(k => {
      const s = contacts[k].status;
      return s === 'new' || s === 'contacted' || s === 'invited';
    });

    const THREE_DAYS = 3 * 86400;
    const now = Math.floor(Date.now() / 1000);

    return queueKeys
      .filter(key => contacts[key])
      .slice(0, 50)
      .map(key => {
        const c = contacts[key];
        // For "new" contacts: show "expired" if older than 3 days, else "pending"
        let status: string = c.status;
        if (c.status === 'new' || c.status === 'contacted') {
          const age = c.firstSeen ? now - c.firstSeen : 0;
          status = age >= THREE_DAYS ? 'expired' : 'pending';
        }
        return {
          name: c.name,
          className: c.classLabel || c.classFile || (c.status === 'joined' ? '—' : 'Unknown'),
          level: c.level || (c.status === 'joined' ? '—' : 0),
          status: status as 'pending' | 'expired' | 'invited' | 'joined',
          addedAt: formatTimestamp(c.firstSeen),
        };
      });
  }, [data]);

  return (
    <div>
      <div className="panel-card">
        <div className="panel-title">
          <span className="panel-icon">{'\u2630'}</span>
          Recruitment Queue
        </div>

        {/* Bulk actions */}
        {(
          <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem' }}>
            {['Select All', 'Invite Selected', 'Remove Selected'].map((label) => (
              <div
                key={label}
                style={{
                  padding: '0.4rem 0.75rem',
                  fontSize: '0.75rem',
                  fontWeight: 600,
                  color: label === 'Remove Selected' ? '#f87171' : '#C9AA71',
                  border: `1px solid ${label === 'Remove Selected' ? 'rgba(248, 113, 113, 0.2)' : '#352c20'}`,
                  borderRadius: 3,
                  background: label === 'Remove Selected' ? 'rgba(248, 113, 113, 0.06)' : 'rgba(201, 170, 113, 0.06)',
                  cursor: 'default',
                }}
              >
                {label}
              </div>
            ))}
          </div>
        )}

        {/* Queue table */}
        {queueEntries.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '2rem', color: '#6b5f4d', fontSize: '0.82rem' }}>
            Queue is empty. Import your addon data to see queued players.
          </div>
        ) : (
          <>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Class</th>
                  <th>Level</th>
                  <th>Status</th>
                  <th>Added</th>
                </tr>
              </thead>
              <tbody>
                {queueEntries.map((entry) => (
                  <tr key={entry.name}>
                    <td style={{ fontWeight: 600 }}>{entry.name}</td>
                    <td>
                      <span
                        className="class-dot"
                        style={{ backgroundColor: getClassColor(entry.className) }}
                      />
                      {entry.className}
                    </td>
                    <td>{entry.level}</td>
                    <td>
                      <span className={`status-badge ${entry.status}`}>
                        {entry.status}
                      </span>
                    </td>
                    <td style={{ color: '#6b5f4d', fontSize: '0.78rem' }}>{entry.addedAt}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            <div style={{ marginTop: '0.75rem', fontSize: '0.7rem', color: '#6b5f4d', textAlign: 'right' }}>
              {queueEntries.length} entries in queue
            </div>
          </>
        )}
      </div>
    </div>
  );
}
