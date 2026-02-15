'use client';

import { useTier } from '@/components/dashboard/TierContext';
import { useData } from '@/components/dashboard/DataContext';
import { useMemo } from 'react';

export function OverviewPanel() {
  const { currentTier } = useTier();
  const { data, isLive } = useData();

  const contacts = useMemo(() => data ? Object.values(data.contacts) : [], [data]);

  const stats = useMemo(() => {
    const joined = contacts.filter(c => c.status === 'joined').length;
    const contacted = contacts.filter(c => c.status === 'contacted' || c.status === 'invited' || c.status === 'joined').length;
    const queueSize = data?.queue ? data.queue.length : contacts.filter(c => c.status === 'new' || c.status === 'contacted').length;
    const rate = contacted > 0 ? Math.round((joined / contacted) * 100) : 0;

    return [
      { label: 'Total Recruits', value: String(joined) },
      { label: 'Queue Size', value: String(queueSize) },
      { label: 'Conversion', value: `${rate}%` },
      { label: 'Total Contacts', value: String(contacts.length) },
    ];
  }, [data, contacts]);

  // Build recent activity from real contacts
  const activity = useMemo(() => {
    if (!data) return [];
    const events: Array<{ icon: string; text: string; time: string; ts: number }> = [];
    for (const c of contacts) {
      if (c.status === 'joined' && c.lastInviteAt) {
        events.push({ icon: '\u2714', text: `${c.name} (${c.classLabel || '?'} ${c.level || '?'}) a rejoint la guilde`, time: '', ts: c.lastInviteAt });
      }
      if (c.lastWhisperOut && c.lastWhisperOut > 0 && c.status !== 'joined') {
        events.push({ icon: '\u2709', text: `Whisper envoy\u00e9 \u00e0 ${c.name}`, time: '', ts: c.lastWhisperOut });
      }
      if (c.lastInviteAt && c.lastInviteAt > 0 && c.status === 'invited') {
        events.push({ icon: '\u2795', text: `Invitation envoy\u00e9e \u00e0 ${c.name}`, time: '', ts: c.lastInviteAt });
      }
    }
    events.sort((a, b) => b.ts - a.ts);
    const now = Math.floor(Date.now() / 1000);
    return events.slice(0, 8).map(e => {
      const diff = now - e.ts;
      let time = '';
      if (diff < 60) time = 'just now';
      else if (diff < 3600) time = `${Math.floor(diff / 60)}m ago`;
      else if (diff < 86400) time = `${Math.floor(diff / 3600)}h ago`;
      else time = `${Math.floor(diff / 86400)}d ago`;
      return { ...e, time };
    });
  }, [data, contacts]);

  const guildName = data?.settings?.guildName || '\u2014';
  const serverName = data?.realm || '\u2014';

  return (
    <div>
      <div className="stats-grid">
        {stats.map((stat) => (
          <div key={stat.label} className="stat-card">
            <div className="stat-value">{stat.value}</div>
            <div className="stat-label">{stat.label}</div>
          </div>
        ))}
      </div>

      <div className="panel-card">
        <div className="panel-title">
          <span className="panel-icon">{'\u26A1'}</span>
          Recent Activity
        </div>
        <div className="activity-feed">
          {activity.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '1.5rem', color: '#6b5f4d', fontSize: '0.78rem' }}>
              No activity yet. Import your addon data to see recent events.
            </div>
          ) : (
            activity.map((item, i) => (
              <div key={i} className="activity-item">
                <div className="activity-icon">{item.icon}</div>
                <div className="activity-text">
                  {item.text}
                  <span className="activity-time">{item.time}</span>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      <div className="panel-card" style={{ marginTop: '1rem' }}>
        <div className="panel-title">
          <span className="panel-icon">{'\u2139'}</span>
          Quick Info
        </div>
        <div style={{ fontSize: '0.82rem', color: '#a89b80', lineHeight: 1.6 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.4rem 0', borderBottom: '1px solid #2a2318' }}>
            <span>Current Tier</span>
            <span style={{ color: '#C9AA71', fontWeight: 600, textTransform: 'capitalize' }}>{currentTier}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.4rem 0', borderBottom: '1px solid #2a2318' }}>
            <span>Guild</span>
            <span style={{ color: '#d4c5a9' }}>{guildName}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.4rem 0', borderBottom: '1px solid #2a2318' }}>
            <span>Server</span>
            <span style={{ color: '#d4c5a9' }}>{serverName}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.4rem 0' }}>
            <span>Data Source</span>
            <span style={{ color: isLive ? '#4ade80' : '#6b5f4d' }}>
              {isLive ? `Live \u2014 ${data?.character || ''}` : 'No data imported'}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
