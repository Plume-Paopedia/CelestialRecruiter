'use client';

import { motion } from 'framer-motion';
import { FEATURES } from '@/lib/constants';
import { fadeInUp, staggerContainer } from '@/lib/animations';

/** Unicode icons replacing emojis for a cleaner medieval aesthetic */
const FEATURE_ICONS: Record<string, string> = {
  'auto-scan':      '\u25CE', // bullseye
  'auto-recruiter': '\u2699', // gear
  'analytics':      '\u2261', // triple bar (chart)
  'discord':        '\u2709', // envelope / chat
  'templates':      '\u2630', // trigram / document
  'campaigns':      '\u26A1', // lightning
};

/** Tier display names and colors */
const TIER_META: Record<string, { label: string; colorVar: string }> = {
  legendary: { label: 'PRO',       colorVar: 'var(--tier-legendary, #ff8000)' },
  epic:      { label: 'RECRUTEUR', colorVar: 'var(--tier-epic, #a335ee)' },
  rare:      { label: 'RECRUTEUR', colorVar: 'var(--tier-rare, #0070dd)' },
};

export function FeaturesSection() {
  return (
    <section className="features-section" id="features">
      {/* Section Header */}
      <motion.div
        className="section-header"
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.8, ease: [0.25, 0.1, 0.25, 1] }}
      >
        <span className="section-label">What You Get</span>
        <h2>Legendary Features</h2>
        <p>Everything you need to build a mythic-tier roster</p>
      </motion.div>

      {/* Feature Cards Grid */}
      <motion.div
        className="features-grid"
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true, amount: 0.1 }}
        variants={staggerContainer}
      >
        {FEATURES.map((feature) => {
          const tier = TIER_META[feature.tier];
          const icon = FEATURE_ICONS[feature.id] ?? '\u2726';

          return (
            <motion.div
              key={feature.id}
              className={`quest-panel tier-${feature.tier} feature-card`}
              variants={fadeInUp}
              whileHover={{ y: -3 }}
              transition={{ duration: 0.3, ease: [0.25, 0.1, 0.25, 1] }}
            >
              {/* Tier Badge */}
              {tier && (
                <span
                  className="feature-tier-badge"
                  style={{
                    borderColor: tier.colorVar,
                    color: tier.colorVar,
                  }}
                >
                  {tier.label}
                </span>
              )}

              {/* Icon Container */}
              <div
                className={`feature-icon-container tier-border-${feature.tier}`}
              >
                <span className="feature-icon-char">{icon}</span>
              </div>

              {/* Title */}
              <h3 className="feature-card-title">{feature.title}</h3>

              {/* Description */}
              <p className="feature-card-desc">{feature.description}</p>

              {/* Stats */}
              <div className="feature-card-stats">{feature.stats}</div>

              {/* Unlock Footer */}
              <div className="feature-card-unlock">{feature.unlock}</div>
            </motion.div>
          );
        })}
      </motion.div>
    </section>
  );
}
