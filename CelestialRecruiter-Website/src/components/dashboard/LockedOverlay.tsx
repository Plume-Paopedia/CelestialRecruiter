'use client';

import { LINKS } from '@/lib/constants';

interface LockedOverlayProps {
  requiredTier: string;
  featureName: string;
  description?: string;
}

const TIER_DISPLAY: Record<string, { label: string; color: string }> = {
  recruteur: { label: 'Recruteur', color: '#0070dd' },
  pro: { label: 'Pro', color: '#a335ee' },
};

export function LockedOverlay({ requiredTier, featureName, description }: LockedOverlayProps) {
  const tier = TIER_DISPLAY[requiredTier] || TIER_DISPLAY.pro;

  return (
    <div className="locked-overlay">
      <div className="lock-icon-large">{'\u{1F512}'}</div>
      <div className="lock-title">
        Unlock {featureName}
      </div>
      <div className="lock-desc">
        {description || `Available with the ${tier.label} tier and above.`}
      </div>
      <a
        href={LINKS.patreon}
        target="_blank"
        rel="noopener noreferrer"
        className={requiredTier === 'pro' ? 'btn-epic' : 'btn-rare'}
        style={{ padding: '0.6rem 1.5rem', fontSize: '0.85rem' }}
      >
        Get {tier.label}
      </a>
    </div>
  );
}
