'use client';

import { motion } from 'framer-motion';
import { STATS, TESTIMONIALS, CLASS_COLORS } from '@/lib/constants';
import { AnimatedCounter } from '@/components/ui/AnimatedCounter';
import { fadeInUp, staggerContainer } from '@/lib/animations';
import { SectionDivider } from '@/components/ui/SectionDivider';

export function SocialProofSection() {
  return (
    <section
      id="social-proof"
      className="social-proof-section"
      style={{
        padding: '7rem 1.5rem',
        background: '#1a1814',
        position: 'relative',
      }}
    >
      <motion.div
        className="section-header"
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.8, ease: [0.25, 0.1, 0.25, 1] }}
      >
        <span className="section-label">By the Numbers</span>
        <h2>Built for Serious Recruiters</h2>
        <p>A feature-packed addon designed for guild officers</p>
      </motion.div>

      {/* Stats Grid */}
      <motion.div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: '1rem',
          maxWidth: '900px',
          margin: '0 auto 3rem',
        }}
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true }}
        variants={staggerContainer}
      >
        {STATS.map((stat, i) => (
          <motion.div
            key={i}
            variants={fadeInUp}
            style={{
              textAlign: 'center',
              padding: '1.75rem 1rem',
              background: '#171411',
              border: '1px solid #352c20',
              borderRadius: '6px',
            }}
          >
            <div
              style={{
                fontFamily: "'Cinzel', serif",
                fontSize: '1.75rem',
                fontWeight: 700,
                color: '#C9AA71',
                marginBottom: '0.25rem',
              }}
            >
              <AnimatedCounter
                end={stat.value}
                suffix={stat.suffix}
              />
            </div>
            <div
              style={{
                color: '#6b5f4d',
                fontSize: '0.78rem',
                fontWeight: 500,
                letterSpacing: '0.03em',
              }}
            >
              {stat.label}
            </div>
          </motion.div>
        ))}
      </motion.div>

      <SectionDivider />
      <div style={{ height: '2.5rem' }} />

      {/* Testimonials */}
      <motion.div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
          gap: '1rem',
          maxWidth: '1140px',
          margin: '0 auto',
        }}
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true }}
        variants={staggerContainer}
      >
        {TESTIMONIALS.map((t, i) => (
          <motion.div
            key={i}
            variants={fadeInUp}
            whileHover={{ y: -2 }}
            transition={{ duration: 0.3, ease: [0.25, 0.1, 0.25, 1] }}
            style={{
              background: '#171411',
              border: '1px solid #352c20',
              borderRadius: '6px',
              padding: '1.5rem',
              display: 'flex',
              flexDirection: 'column',
            }}
          >
            {/* Quote mark */}
            <div
              style={{
                fontFamily: "'Cinzel', serif",
                fontSize: '2rem',
                color: '#352c20',
                lineHeight: 1,
                marginBottom: '0.5rem',
              }}
            >
              {'\u201C'}
            </div>

            {/* Quote */}
            <p
              style={{
                color: '#d4c5a9',
                fontSize: '0.92rem',
                lineHeight: 1.65,
                fontStyle: 'italic',
                marginBottom: '1.25rem',
                flex: 1,
              }}
            >
              {t.quote}
            </p>

            {/* Author */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.75rem',
                paddingTop: '0.75rem',
                borderTop: '1px solid #2a2318',
              }}
            >
              <div
                style={{
                  width: '30px',
                  height: '30px',
                  borderRadius: '50%',
                  background: CLASS_COLORS[t.wowClass] || '#C9AA71',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: '0.75rem',
                  fontWeight: 700,
                  color: '#0d0c0a',
                  fontFamily: "'Cinzel', serif",
                  opacity: 0.85,
                }}
              >
                {t.author[0]}
              </div>
              <div>
                <div
                  style={{
                    color: CLASS_COLORS[t.wowClass] || '#C9AA71',
                    fontWeight: 600,
                    fontSize: '0.85rem',
                  }}
                >
                  {t.author}
                </div>
                <div style={{ color: '#4a3f32', fontSize: '0.75rem' }}>
                  &lt;{t.guild}&gt; &bull; {t.server}
                </div>
              </div>
            </div>
          </motion.div>
        ))}
      </motion.div>
    </section>
  );
}
