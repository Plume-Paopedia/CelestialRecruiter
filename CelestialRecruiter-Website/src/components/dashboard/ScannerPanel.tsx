'use client';

import { useMemo } from 'react';
import { CLASS_COLORS } from '@/lib/constants';
import { useTier } from '@/components/dashboard/TierContext';
import { useData } from '@/components/dashboard/DataContext';

function getClassColor(className: string): string {
  const key = className.toLowerCase().replace(' ', '-');
  return CLASS_COLORS[key] || '#d4c5a9';
}

export function ScannerPanel() {
  const { hasAccess } = useTier();
  const { data } = useData();
  const showAutoScan = hasAccess('recruteur');

  const players = useMemo(() => {
    if (!data) return [];
    return Object.values(data.contacts)
      .filter(c => c.status === 'new' || c.status === 'contacted')
      .sort((a, b) => (b.lastSeen || 0) - (a.lastSeen || 0))
      .slice(0, 50)
      .map(c => ({
        name: c.name,
        className: c.classLabel || c.classFile || 'Unknown',
        level: c.level || 0,
        zone: c.zone || 'Unknown',
        guild: c.guild || '',
        status: 'online' as const,
      }));
  }, [data]);

  return (
    <div>
      <div className="panel-card">
        <div className="panel-title">
          <span className="panel-icon">{'\u2295'}</span>
          Scanner
        </div>

        {/* Filters row */}
        <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem' }}>
          <input
            type="text"
            placeholder="Search players..."
            readOnly
            style={{
              flex: 1,
              background: '#211d18',
              border: '1px solid #352c20',
              borderRadius: '3px',
              padding: '0.5rem 0.75rem',
              fontSize: '0.82rem',
              color: '#d4c5a9',
              outline: 'none',
            }}
          />
          <button
            style={{
              background: 'linear-gradient(180deg, rgba(201, 170, 113, 0.15), rgba(139, 115, 64, 0.1))',
              border: '1px solid #6b5635',
              borderRadius: '3px',
              padding: '0.5rem 1rem',
              fontSize: '0.82rem',
              fontWeight: 600,
              color: '#C9AA71',
              cursor: 'default',
              whiteSpace: 'nowrap',
            }}
          >
            Run Scan
          </button>
        </div>

        {/* Auto-Scan toggle (Recruteur+) */}
        {showAutoScan && (
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '0.6rem 0.75rem',
              marginBottom: '1rem',
              background: 'rgba(201, 170, 113, 0.04)',
              borderRadius: '3px',
              border: '1px solid #2a2318',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <span style={{ fontSize: '0.82rem', color: '#d4c5a9' }}>Auto-Scan</span>
              <span style={{ fontSize: '0.7rem', color: '#4ade80' }}>Active - scanning every 30s</span>
            </div>
            <div className="toggle-switch on" />
          </div>
        )}

        {/* Results table */}
        {players.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '2rem', color: '#6b5f4d', fontSize: '0.82rem' }}>
            No scanner results. Import your addon data to see discovered players.
          </div>
        ) : (
          <>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Class</th>
                  <th>Level</th>
                  <th>Zone</th>
                  <th>Guild</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {players.map((player) => (
                  <tr key={player.name}>
                    <td style={{ fontWeight: 600 }}>{player.name}</td>
                    <td>
                      <span
                        className="class-dot"
                        style={{ backgroundColor: getClassColor(player.className) }}
                      />
                      {player.className}
                    </td>
                    <td>{player.level}</td>
                    <td>{player.zone}</td>
                    <td style={{ color: player.guild ? '#d4c5a9' : '#6b5f4d', fontStyle: player.guild ? 'normal' : 'italic' }}>
                      {player.guild || 'No guild'}
                    </td>
                    <td>
                      <span
                        style={{
                          display: 'inline-block',
                          width: 6,
                          height: 6,
                          borderRadius: '50%',
                          backgroundColor: player.status === 'online' ? '#4ade80' : '#fbbf24',
                          marginRight: '0.4rem',
                        }}
                      />
                      {player.status}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            <div style={{ marginTop: '0.75rem', fontSize: '0.7rem', color: '#6b5f4d', textAlign: 'right' }}>
              {players.length} players found
            </div>
          </>
        )}
      </div>
    </div>
  );
}
