'use client';

import { useTier } from '@/components/dashboard/TierContext';
import { useData } from '@/components/dashboard/DataContext';
import { LockedOverlay } from '@/components/dashboard/LockedOverlay';
import { useMemo } from 'react';

interface CampaignDisplay {
  name: string;
  status: 'active' | 'paused' | 'completed';
  template: string;
  targets: string;
  sent: number;
  responses: number;
  conversion: string;
}

export function CampaignsPanel() {
  const { hasAccess } = useTier();
  const { data } = useData();
  const isLocked = !hasAccess('pro');

  const campaigns = useMemo((): CampaignDisplay[] => {
    if (!data?.campaigns) return [];
    return Object.values(data.campaigns).map((raw: unknown) => {
      const c = raw as Record<string, unknown>;
      const stats = (c.stats || {}) as Record<string, number>;
      const sent = stats.sent || 0;
      const responses = stats.responses || 0;
      const joined = stats.joined || 0;
      const conv = sent > 0 ? Math.round((joined / sent) * 100) : 0;
      const targets = c.targets as Record<string, unknown> | undefined;
      const classes = Array.isArray(targets?.classes) ? (targets.classes as string[]).join(', ') : 'All';
      return {
        name: String(c.name || 'Unnamed'),
        status: (c.status as 'active' | 'paused' | 'completed') || 'paused',
        template: String(c.template || 'default'),
        targets: `${classes} ${targets?.levelMin || '?'}-${targets?.levelMax || '?'}`,
        sent,
        responses,
        conversion: `${conv}%`,
      };
    });
  }, [data]);

  return (
    <div style={{ position: 'relative' }}>
      {isLocked && (
        <LockedOverlay
          requiredTier="pro"
          featureName="Campaigns"
          description="Create automated recruitment campaigns targeting specific classes, levels, and time windows."
        />
      )}

      <div className="panel-card">
        <div className="panel-title">
          <span className="panel-icon">{'\u26A1'}</span>
          Recruitment Campaigns
        </div>

        {campaigns.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '2rem', color: '#6b5f4d', fontSize: '0.82rem' }}>
            No campaigns. Import your addon data to see active campaigns.
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
            {campaigns.map((campaign) => (
              <div
                key={campaign.name}
                className="panel-card"
                style={{ margin: 0, background: '#211d18' }}
              >
                {/* Header */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.6rem' }}>
                  <span style={{ fontSize: '0.9rem', fontWeight: 700, color: '#d4c5a9', fontFamily: "'Cinzel', serif" }}>
                    {campaign.name}
                  </span>
                  <span className={`status-badge ${campaign.status}`}>
                    {campaign.status}
                  </span>
                </div>

                {/* Details */}
                <div style={{ fontSize: '0.78rem', color: '#a89b80', marginBottom: '0.6rem', lineHeight: 1.5 }}>
                  <div style={{ marginBottom: '0.25rem' }}>
                    <span style={{ color: '#6b5f4d' }}>Targets: </span>
                    {campaign.targets}
                  </div>
                  <div>
                    <span style={{ color: '#6b5f4d' }}>Template: </span>
                    {campaign.template}
                  </div>
                </div>

                {/* Metrics */}
                <div style={{ display: 'flex', gap: '1.5rem', paddingTop: '0.5rem', borderTop: '1px solid #2a2318' }}>
                  <div style={{ textAlign: 'center' }}>
                    <div style={{ fontSize: '1.1rem', fontWeight: 700, color: '#C9AA71' }}>{campaign.sent}</div>
                    <div style={{ fontSize: '0.65rem', color: '#6b5f4d', textTransform: 'uppercase', letterSpacing: '0.06em' }}>Sent</div>
                  </div>
                  <div style={{ textAlign: 'center' }}>
                    <div style={{ fontSize: '1.1rem', fontWeight: 700, color: '#C9AA71' }}>{campaign.responses}</div>
                    <div style={{ fontSize: '0.65rem', color: '#6b5f4d', textTransform: 'uppercase', letterSpacing: '0.06em' }}>Responses</div>
                  </div>
                  <div style={{ textAlign: 'center' }}>
                    <div style={{ fontSize: '1.1rem', fontWeight: 700, color: '#4ade80' }}>{campaign.conversion}</div>
                    <div style={{ fontSize: '0.65rem', color: '#6b5f4d', textTransform: 'uppercase', letterSpacing: '0.06em' }}>Conversion</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
