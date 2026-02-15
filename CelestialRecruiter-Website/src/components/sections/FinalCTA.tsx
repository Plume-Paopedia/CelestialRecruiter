'use client';

import { motion } from 'framer-motion';
import { LINKS } from '@/lib/constants';
import { fadeInUp, staggerContainer } from '@/lib/animations';
import { SectionDivider } from '@/components/ui/SectionDivider';

export function FinalCTASection() {
  return (
    <section
      id="final-cta"
      style={{
        padding: '8rem 1.5rem',
        background: '#0d0c0a',
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      {/* Background glow */}
      <div
        style={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
          width: '600px',
          height: '600px',
          borderRadius: '50%',
          background:
            'radial-gradient(circle, rgba(139, 115, 64, 0.03) 0%, transparent 70%)',
          pointerEvents: 'none',
        }}
      />

      <motion.div
        style={{
          position: 'relative',
          zIndex: 10,
          textAlign: 'center',
          maxWidth: '650px',
          margin: '0 auto',
        }}
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true }}
        variants={staggerContainer}
      >
        <motion.div variants={fadeInUp}>
          <SectionDivider />
        </motion.div>

        <div style={{ height: '2rem' }} />

        <motion.h2
          variants={fadeInUp}
          style={{
            fontFamily: "'Cinzel', serif",
            fontSize: 'clamp(1.5rem, 3vw, 2rem)',
            fontWeight: 700,
            color: '#C9AA71',
            marginBottom: '1rem',
            letterSpacing: '0.03em',
          }}
        >
          Ready to Recruit Like a Legend?
        </motion.h2>

        <motion.p
          variants={fadeInUp}
          style={{
            color: '#a89b80',
            fontSize: '1rem',
            marginBottom: '2.5rem',
          }}
        >
          Stop wasting time on manual /who &mdash; let the addon do the work
        </motion.p>

        {/* Dual CTA */}
        <motion.div
          variants={fadeInUp}
          style={{
            display: 'flex',
            gap: '1.25rem',
            justifyContent: 'center',
            flexWrap: 'wrap',
            marginBottom: '2.5rem',
          }}
        >
          <a
            href={LINKS.curseforge}
            target="_blank"
            rel="noopener noreferrer"
            className="btn-legendary"
          >
            Download Free
          </a>

          <a
            href={LINKS.patreon}
            target="_blank"
            rel="noopener noreferrer"
            className="btn-epic"
          >
            Get Pro for 7&euro;/mo
          </a>
        </motion.div>

        {/* Trust Signals */}
        <motion.div
          variants={fadeInUp}
          style={{
            display: 'flex',
            gap: '2rem',
            justifyContent: 'center',
            flexWrap: 'wrap',
            color: '#6b5f4d',
            fontSize: '0.82rem',
          }}
        >
          <span>{'\u2713'} Free Forever Option</span>
          <span>{'\u2713'} 30-Day Money Back</span>
          <span>{'\u2713'} Cancel Anytime</span>
        </motion.div>
      </motion.div>
    </section>
  );
}
