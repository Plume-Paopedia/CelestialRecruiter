'use client';

import { motion } from 'framer-motion';
import { LINKS } from '@/lib/constants';
import { fadeInUp } from '@/lib/animations';

export function PricingSection() {
  return (
    <section
      className="pricing-section"
      id="pricing"
      style={{
        padding: '7rem 1.5rem',
        background: '#0d0c0a',
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
        <span className="section-label">Soutenir le projet</span>
        <h2>Support CelestialRecruiter</h2>
        <p>Toutes les fonctionnalit&eacute;s sont gratuites et le resteront</p>
      </motion.div>

      <motion.div
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true, amount: 0.1 }}
        variants={fadeInUp}
        style={{
          maxWidth: '580px',
          margin: '3rem auto 0',
          textAlign: 'center',
          background: '#1a1814',
          border: '1px solid #352c20',
          borderRadius: '6px',
          padding: '2.5rem 2rem',
        }}
      >
        <h3
          style={{
            fontFamily: "'Cinzel', serif",
            fontSize: '1.3rem',
            fontWeight: 700,
            color: '#C9AA71',
            marginBottom: '1rem',
          }}
        >
          Soutenir le d&eacute;veloppement
        </h3>

        <p
          style={{
            color: '#a89b80',
            fontSize: '0.9rem',
            lineHeight: 1.7,
            marginBottom: '1.5rem',
          }}
        >
          CelestialRecruiter est un projet passion, d&eacute;velopp&eacute; et maintenu sur mon temps libre.
          Si l&apos;addon vous est utile, vous pouvez soutenir son d&eacute;veloppement via Patreon.
        </p>

        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: '0.75rem',
            marginBottom: '1.5rem',
          }}
        >
          <div
            style={{
              display: 'flex',
              alignItems: 'baseline',
              gap: '0.3rem',
            }}
          >
            <span
              style={{
                fontFamily: "'Cinzel', serif",
                fontSize: '2.25rem',
                fontWeight: 700,
                color: '#C9AA71',
              }}
            >
              3&euro;
            </span>
            <span style={{ color: '#4a3f32', fontSize: '0.85rem' }}>/mois</span>
          </div>
          <span style={{ color: '#6b5f4d', fontSize: '0.8rem' }}>
            ou montant libre
          </span>
        </div>

        <p
          style={{
            color: '#6b5f4d',
            fontSize: '0.82rem',
            lineHeight: 1.6,
            marginBottom: '2rem',
            padding: '0 1rem',
          }}
        >
          Aucun avantage particulier &mdash; juste un coup de pouce pour continuer &agrave; am&eacute;liorer l&apos;addon.
          Merci &agrave; ceux qui soutiennent le projet !
        </p>

        <a
          href={LINKS.patreon}
          target="_blank"
          rel="noopener noreferrer"
          className="btn-rare"
          style={{
            display: 'inline-block',
            width: 'auto',
            padding: '0.75rem 2rem',
            textAlign: 'center',
          }}
        >
          Soutenir sur Patreon
        </a>
      </motion.div>
    </section>
  );
}
