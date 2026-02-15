'use client';

import { motion } from 'framer-motion';
import { useState } from 'react';
import { fadeInUp, staggerContainer } from '@/lib/animations';
import { DASHBOARD_MODULES, MOCK_SCANNER_DATA, MOCK_ANALYTICS, CLASS_COLORS } from '@/lib/constants';

type TierName = 'free' | 'recruteur' | 'pro';

const TIER_LEVELS: Record<string, number> = { free: 0, recruteur: 1, pro: 2 };

function hasAccess(current: TierName, required: string) {
  return (TIER_LEVELS[current] ?? 0) >= (TIER_LEVELS[required] ?? 0);
}

function PreviewSidebar({ tier }: { tier: TierName }) {
  return (
    <div className="preview-sidebar">
      {DASHBOARD_MODULES.map((mod) => {
        const locked = !hasAccess(tier, mod.minTier);
        const active = mod.id === 'overview';
        return (
          <div
            key={mod.id}
            className={`sidebar-item ${active ? 'active' : ''} ${locked ? 'locked' : ''}`}
          >
            <span className="item-icon">{mod.icon}</span>
            <span>{mod.label}</span>
            {locked && <span className="lock-icon">{'\u{1F512}'}</span>}
          </div>
        );
      })}
    </div>
  );
}

function PreviewContent({ tier }: { tier: TierName }) {
  const maxBars = Math.max(...MOCK_ANALYTICS.weeklyData.map(d => d.recruits));

  return (
    <div className="preview-main">
      {/* Quick Stats Row */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(4, 1fr)',
        gap: '0.5rem',
        marginBottom: '1rem',
      }}>
        {[
          { label: 'Recruits', value: '7' },
          { label: 'Queue', value: '23' },
          { label: 'Response', value: '34%' },
          { label: 'Campaigns', value: tier === 'pro' ? '2' : '--' },
        ].map((s) => (
          <div key={s.label} style={{
            background: '#1a1814',
            border: '1px solid #352c20',
            borderRadius: '4px',
            padding: '0.5rem',
            textAlign: 'center',
          }}>
            <div style={{ fontFamily: "'Cinzel', serif", fontSize: '1rem', fontWeight: 700, color: '#C9AA71' }}>
              {s.value}
            </div>
            <div style={{ fontSize: '0.6rem', color: '#6b5f4d' }}>{s.label}</div>
          </div>
        ))}
      </div>

      {/* Two-column content */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: '1fr 1fr',
        gap: '0.75rem',
      }}>
        {/* Scanner preview */}
        <div style={{
          background: '#1a1814',
          border: '1px solid #352c20',
          borderRadius: '4px',
          padding: '0.6rem',
        }}>
          <div style={{
            fontSize: '0.7rem', fontWeight: 600, color: '#C9AA71',
            fontFamily: "'Cinzel', serif", marginBottom: '0.4rem',
          }}>
            {hasAccess(tier, 'recruteur') ? '\u25CE Auto-Scanner' : '\u25CE Manual Scanner'}
          </div>
          {MOCK_SCANNER_DATA.slice(0, 4).map((p, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: '0.35rem',
              padding: '0.2rem 0', borderBottom: '1px solid #2a2318',
              fontSize: '0.6rem', color: '#d4c5a9',
            }}>
              <span style={{
                width: '6px', height: '6px', borderRadius: '50%',
                background: CLASS_COLORS[p.className.toLowerCase()] || '#C9AA71',
                flexShrink: 0,
              }} />
              <span style={{ flex: 1 }}>{p.name}</span>
              <span style={{ color: '#6b5f4d' }}>{p.level}</span>
            </div>
          ))}
        </div>

        {/* Analytics preview or locked */}
        <div style={{
          background: '#1a1814',
          border: '1px solid #352c20',
          borderRadius: '4px',
          padding: '0.6rem',
          position: 'relative',
        }}>
          <div style={{
            fontSize: '0.7rem', fontWeight: 600, color: '#C9AA71',
            fontFamily: "'Cinzel', serif", marginBottom: '0.4rem',
          }}>
            {'\u2261'} Weekly Recruits
          </div>

          {/* Mini bar chart */}
          <div style={{
            display: 'flex', alignItems: 'flex-end', gap: '3px', height: '50px',
          }}>
            {MOCK_ANALYTICS.weeklyData.map((d, i) => (
              <div key={i} style={{
                flex: 1,
                height: `${(d.recruits / maxBars) * 100}%`,
                background: hasAccess(tier, 'recruteur')
                  ? 'linear-gradient(180deg, rgba(201, 170, 113, 0.6), rgba(139, 115, 64, 0.3))'
                  : '#2a2318',
                borderRadius: '2px 2px 0 0',
                minHeight: '4px',
              }} />
            ))}
          </div>
          <div style={{
            display: 'flex', gap: '3px', marginTop: '2px',
          }}>
            {MOCK_ANALYTICS.weeklyData.map((d, i) => (
              <div key={i} style={{
                flex: 1, textAlign: 'center',
                fontSize: '0.5rem', color: '#4a3f32',
              }}>
                {d.day}
              </div>
            ))}
          </div>

          {!hasAccess(tier, 'recruteur') && (
            <div style={{
              position: 'absolute', inset: 0,
              background: 'rgba(13, 12, 10, 0.8)',
              backdropFilter: 'blur(2px)',
              display: 'flex', flexDirection: 'column',
              alignItems: 'center', justifyContent: 'center',
              borderRadius: '4px', fontSize: '0.65rem', color: '#6b5f4d',
            }}>
              <span style={{ fontSize: '1rem', marginBottom: '0.25rem' }}>{'\u{1F512}'}</span>
              Recruteur
            </div>
          )}
        </div>
      </div>

      {/* Discord preview (pro only) */}
      {tier === 'pro' && (
        <div style={{
          background: '#1a1814',
          border: '1px solid #352c20',
          borderRadius: '4px',
          padding: '0.5rem 0.6rem',
          marginTop: '0.75rem',
          display: 'flex', alignItems: 'center', gap: '0.5rem',
        }}>
          <div style={{
            width: '20px', height: '20px', borderRadius: '50%',
            background: '#5865F2', display: 'flex', alignItems: 'center',
            justifyContent: 'center', fontSize: '0.55rem', color: 'white', fontWeight: 700,
          }}>
            CR
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: '0.6rem', color: '#5865F2', fontWeight: 600 }}>CelestialRecruiter</div>
            <div style={{ fontSize: '0.55rem', color: '#a89b80' }}>New player Kaelethas (Paladin 80) whispered!</div>
          </div>
        </div>
      )}
    </div>
  );
}

export function DashboardPreviewSection() {
  const [tier, setTier] = useState<TierName>('pro');

  return (
    <section
      id="dashboard-preview"
      className="dashboard-preview-section"
      style={{
        padding: '7rem 1.5rem',
        background: '#0d0c0a',
      }}
    >
      <motion.div
        className="section-header"
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.8, ease: [0.25, 0.1, 0.25, 1] }}
      >
        <span className="section-label">Dashboard</span>
        <h2>Your Command Center</h2>
        <p>A complete dashboard to manage your recruitment</p>
      </motion.div>

      {/* Tier Selector */}
      <motion.div
        className="tier-selector"
        initial={{ opacity: 0 }}
        whileInView={{ opacity: 1 }}
        viewport={{ once: true }}
        transition={{ delay: 0.2, duration: 0.6 }}
      >
        {(['free', 'recruteur', 'pro'] as const).map((t) => (
          <button
            key={t}
            className={`tier-btn tier-${t} ${tier === t ? 'active' : ''}`}
            onClick={() => setTier(t)}
          >
            {t.charAt(0).toUpperCase() + t.slice(1)}
          </button>
        ))}
      </motion.div>

      {/* Dashboard Frame */}
      <motion.div
        className="dashboard-frame"
        initial={{ opacity: 0, y: 30 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ delay: 0.3, duration: 0.8, ease: [0.25, 0.1, 0.25, 1] }}
      >
        <div className="frame-chrome">
          <span className="dot red" />
          <span className="dot yellow" />
          <span className="dot green" />
          <span className="frame-title">CelestialRecruiter Dashboard</span>
        </div>

        <div className="frame-content">
          <PreviewSidebar tier={tier} />
          <PreviewContent tier={tier} />
        </div>
      </motion.div>

      {/* CTA */}
      <motion.div
        initial={{ opacity: 0 }}
        whileInView={{ opacity: 1 }}
        viewport={{ once: true }}
        transition={{ delay: 0.5, duration: 0.6 }}
        style={{ textAlign: 'center', marginTop: '2rem' }}
      >
        <a
          href="/dashboard"
          style={{
            color: '#C9AA71',
            textDecoration: 'none',
            fontSize: '0.88rem',
            fontFamily: "'Cinzel', serif",
            fontWeight: 600,
            transition: 'opacity 0.2s ease',
            borderBottom: '1px solid rgba(201, 170, 113, 0.3)',
            paddingBottom: '2px',
          }}
        >
          Explore Full Dashboard {'\u2192'}
        </a>
      </motion.div>
    </section>
  );
}
