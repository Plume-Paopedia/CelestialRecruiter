'use client';

import { useState } from 'react';
import { useTier } from './TierContext';
import { useData } from './DataContext';
import { usePatch } from './PatchContext';
import { ExportPatchModal } from './ExportPatchModal';

interface TopBarProps {
  title: string;
  onMenuToggle?: () => void;
}

export function TopBar({ title, onMenuToggle }: TopBarProps) {
  const { currentTier, setTier } = useTier();
  const { isLive, data } = useData();
  const { isDirty, dirtyCount } = usePatch();
  const [showExportModal, setShowExportModal] = useState(false);

  return (
    <>
      <div className="dashboard-topbar">
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          {onMenuToggle && (
            <button className="mobile-menu-btn" onClick={onMenuToggle}>
              {'\u2630'}
            </button>
          )}
          <span className="topbar-title">{title}</span>
          <span className={`data-badge ${isLive ? 'live' : 'demo'}`}>
            <span className={`data-badge-dot ${isLive ? 'live' : 'demo'}`} />
            {isLive ? `Live \u2014 ${data?.character || 'Unknown'}` : 'Demo Data'}
          </span>
        </div>

        <div className="topbar-actions">
          {isLive && (
            <button
              className={`export-changes-btn ${isDirty ? 'active' : ''}`}
              onClick={() => setShowExportModal(true)}
              disabled={!isDirty}
              title={isDirty ? `${dirtyCount} section(s) modified` : 'No changes to export'}
            >
              Export Changes
              {isDirty && <span className="export-changes-count">{dirtyCount}</span>}
            </button>
          )}

          <div className="tier-selector" style={{ marginBottom: 0 }}>
            {(['free', 'recruteur', 'pro'] as const).map((tier) => (
              <button
                key={tier}
                className={`tier-btn tier-${tier} ${currentTier === tier ? 'active' : ''}`}
                onClick={() => setTier(tier)}
                style={{ padding: '0.35rem 0.85rem', fontSize: '0.72rem' }}
              >
                {tier.charAt(0).toUpperCase() + tier.slice(1)}
              </button>
            ))}
          </div>

          <a href="/" className="back-link">
            {'\u2190'} Back
          </a>
        </div>
      </div>

      {showExportModal && (
        <ExportPatchModal onClose={() => setShowExportModal(false)} />
      )}
    </>
  );
}
