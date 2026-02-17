'use client';

import { useTier } from '@/components/dashboard/TierContext';
import { useData } from '@/components/dashboard/DataContext';
import { LockedOverlay } from '@/components/dashboard/LockedOverlay';
import { useMemo, useState } from 'react';

interface CampaignDisplay {
  name: string;
  status: 'active' | 'paused' | 'completed';
  template: string;
  targets: string;
  sent: number;
  responses: number;
  conversion: string;
}

const WOW_CLASSES = [
  'Warrior', 'Paladin', 'Hunter', 'Rogue', 'Priest',
  'Shaman', 'Mage', 'Warlock', 'Monk', 'Druid',
  'Demon Hunter', 'Death Knight', 'Evoker',
];

const inputStyle: React.CSSProperties = {
  background: '#211d18',
  border: '1px solid #352c20',
  borderRadius: '3px',
  padding: '0.45rem 0.65rem',
  fontSize: '0.8rem',
  color: '#d4c5a9',
  outline: 'none',
  width: '100%',
  fontFamily: 'inherit',
};

export function CampaignsPanel() {
  const { hasAccess } = useTier();
  const { data } = useData();
  const isLocked = !hasAccess('pro');
  const [showForm, setShowForm] = useState(false);
  const [formName, setFormName] = useState('');
  const [formTemplate, setFormTemplate] = useState('default');
  const [formLevelMin, setFormLevelMin] = useState('10');
  const [formLevelMax, setFormLevelMax] = useState('80');
  const [formClasses, setFormClasses] = useState<string[]>([]);
  const [localCampaigns, setLocalCampaigns] = useState<CampaignDisplay[]>([]);

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

  const allCampaigns = useMemo(() => [...campaigns, ...localCampaigns], [campaigns, localCampaigns]);

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

        {allCampaigns.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '2rem', color: '#6b5f4d', fontSize: '0.82rem' }}>
            No campaigns yet. Create one below or import your addon data.
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
            {allCampaigns.map((campaign) => (
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

        {/* New Campaign */}
        <div style={{ marginTop: '1rem', borderTop: '1px solid #2a2318', paddingTop: '1rem' }}>
          {!showForm ? (
            <button
              onClick={() => setShowForm(true)}
              aria-label="Create new campaign"
              style={{
                width: '100%',
                padding: '0.6rem',
                background: 'linear-gradient(180deg, rgba(201, 170, 113, 0.08), rgba(139, 115, 64, 0.04))',
                border: '1px dashed #352c20',
                borderRadius: '4px',
                color: '#8B7340',
                fontSize: '0.82rem',
                fontWeight: 600,
                cursor: 'pointer',
                fontFamily: 'inherit',
              }}
            >
              + New Campaign
            </button>
          ) : (
            <div
              style={{
                background: '#211d18',
                border: '1px solid #352c20',
                borderRadius: '4px',
                padding: '1rem',
              }}
            >
              <div style={{ fontSize: '0.85rem', fontWeight: 700, color: '#C9AA71', marginBottom: '0.75rem', fontFamily: "'Cinzel', serif" }}>
                New Campaign
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
                <div>
                  <label style={{ fontSize: '0.72rem', color: '#6b5f4d', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.25rem' }}>
                    Name
                  </label>
                  <input
                    type="text"
                    value={formName}
                    onChange={(e) => setFormName(e.target.value)}
                    placeholder="Weekend Recruitment"
                    style={inputStyle}
                  />
                </div>

                <div>
                  <label style={{ fontSize: '0.72rem', color: '#6b5f4d', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.25rem' }}>
                    Template
                  </label>
                  <select
                    value={formTemplate}
                    onChange={(e) => setFormTemplate(e.target.value)}
                    style={{ ...inputStyle, cursor: 'pointer' }}
                  >
                    <option value="default">Default</option>
                    {data?.templates && Object.keys(data.templates).filter(k => k !== 'default').map(k => (
                      <option key={k} value={k}>{k}</option>
                    ))}
                  </select>
                </div>

                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <div style={{ flex: 1 }}>
                    <label style={{ fontSize: '0.72rem', color: '#6b5f4d', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.25rem' }}>
                      Level Min
                    </label>
                    <input
                      type="number"
                      min="1"
                      max="80"
                      value={formLevelMin}
                      onChange={(e) => setFormLevelMin(e.target.value)}
                      style={inputStyle}
                    />
                  </div>
                  <div style={{ flex: 1 }}>
                    <label style={{ fontSize: '0.72rem', color: '#6b5f4d', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.25rem' }}>
                      Level Max
                    </label>
                    <input
                      type="number"
                      min="1"
                      max="80"
                      value={formLevelMax}
                      onChange={(e) => setFormLevelMax(e.target.value)}
                      style={inputStyle}
                    />
                  </div>
                </div>

                <div>
                  <label style={{ fontSize: '0.72rem', color: '#6b5f4d', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.35rem' }}>
                    Target Classes
                  </label>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.3rem' }}>
                    {WOW_CLASSES.map(cls => {
                      const active = formClasses.includes(cls);
                      return (
                        <button
                          key={cls}
                          onClick={() => setFormClasses(prev => active ? prev.filter(c => c !== cls) : [...prev, cls])}
                          aria-pressed={active}
                          style={{
                            padding: '0.2rem 0.5rem',
                            fontSize: '0.7rem',
                            borderRadius: '3px',
                            border: `1px solid ${active ? '#6b5635' : '#352c20'}`,
                            background: active ? 'rgba(201, 170, 113, 0.12)' : 'transparent',
                            color: active ? '#C9AA71' : '#6b5f4d',
                            cursor: 'pointer',
                            fontFamily: 'inherit',
                          }}
                        >
                          {cls}
                        </button>
                      );
                    })}
                  </div>
                  <div style={{ fontSize: '0.68rem', color: '#4a3f32', marginTop: '0.25rem' }}>
                    {formClasses.length === 0 ? 'All classes (none selected)' : `${formClasses.length} selected`}
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '0.5rem', marginTop: '1rem', justifyContent: 'flex-end' }}>
                <button
                  onClick={() => { setShowForm(false); setFormName(''); setFormClasses([]); }}
                  style={{
                    padding: '0.4rem 0.8rem',
                    fontSize: '0.78rem',
                    background: 'transparent',
                    border: '1px solid #352c20',
                    borderRadius: '3px',
                    color: '#6b5f4d',
                    cursor: 'pointer',
                    fontFamily: 'inherit',
                  }}
                >
                  Cancel
                </button>
                <button
                  onClick={() => {
                    if (!formName.trim()) return;
                    const newCampaign: CampaignDisplay = {
                      name: formName.trim(),
                      status: 'paused',
                      template: formTemplate,
                      targets: `${formClasses.length > 0 ? formClasses.join(', ') : 'All'} ${formLevelMin}-${formLevelMax}`,
                      sent: 0,
                      responses: 0,
                      conversion: '0%',
                    };
                    setLocalCampaigns(prev => [...prev, newCampaign]);
                    setShowForm(false);
                    setFormName('');
                    setFormTemplate('default');
                    setFormLevelMin('10');
                    setFormLevelMax('80');
                    setFormClasses([]);
                  }}
                  disabled={!formName.trim()}
                  style={{
                    padding: '0.4rem 0.8rem',
                    fontSize: '0.78rem',
                    background: formName.trim() ? 'linear-gradient(180deg, rgba(201, 170, 113, 0.2), rgba(139, 115, 64, 0.12))' : 'transparent',
                    border: `1px solid ${formName.trim() ? '#6b5635' : '#352c20'}`,
                    borderRadius: '3px',
                    color: formName.trim() ? '#C9AA71' : '#4a3f32',
                    cursor: formName.trim() ? 'pointer' : 'default',
                    fontWeight: 600,
                    fontFamily: 'inherit',
                  }}
                >
                  Create
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
