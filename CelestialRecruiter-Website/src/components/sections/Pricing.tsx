'use client';

import { motion } from 'framer-motion';
import { PRICING_TIERS, LINKS } from '@/lib/constants';
import { fadeInUp, staggerContainer } from '@/lib/animations';

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
        <span className="section-label">Pricing</span>
        <h2>Choose Your Path</h2>
        <p>Support the project and unlock your full potential</p>
      </motion.div>

      {/* Scarcity Banner */}
      <motion.div
        initial={{ opacity: 0 }}
        whileInView={{ opacity: 1 }}
        viewport={{ once: true }}
        transition={{ duration: 0.8, delay: 0.15 }}
        style={{
          textAlign: 'center',
          marginBottom: '3rem',
          padding: '0.55rem 1.25rem',
          border: '1px solid #352c20',
          borderRadius: '3px',
          color: '#8B7340',
          fontSize: '0.8rem',
          fontWeight: 600,
          maxWidth: '360px',
          margin: '0 auto 3rem',
          letterSpacing: '0.03em',
        }}
      >
        Early Supporter Pricing &mdash; Thank you for supporting development
      </motion.div>

      {/* Pricing Grid */}
      <motion.div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
          gap: '1.25rem',
          maxWidth: '960px',
          margin: '0 auto',
          alignItems: 'start',
        }}
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true, amount: 0.1 }}
        variants={staggerContainer}
      >
        {PRICING_TIERS.map((tier) => (
          <motion.div
            key={tier.id}
            variants={fadeInUp}
            whileHover={{ y: -3 }}
            transition={{ duration: 0.3, ease: [0.25, 0.1, 0.25, 1] }}
            style={{
              background: '#1a1814',
              border: tier.recommended
                ? '1px solid rgba(163, 53, 238, 0.3)'
                : '1px solid #352c20',
              borderRadius: '6px',
              padding: '2rem 1.5rem',
              display: 'flex',
              flexDirection: 'column',
              position: 'relative',
              ...(tier.recommended
                ? {
                    boxShadow: '0 0 20px rgba(163, 53, 238, 0.06)',
                  }
                : {}),
            }}
          >
            {/* Badge */}
            {tier.badge && (
              <div
                style={{
                  position: 'absolute',
                  top: '-0.6rem',
                  left: '50%',
                  transform: 'translateX(-50%)',
                  background: tier.recommended ? '#a335ee' : '#8B7340',
                  color: '#0d0c0a',
                  padding: '0.2rem 0.7rem',
                  borderRadius: '3px',
                  fontSize: '0.65rem',
                  fontWeight: 700,
                  letterSpacing: '0.08em',
                  fontFamily: "'Cinzel', serif",
                  whiteSpace: 'nowrap',
                }}
              >
                {tier.badge}
              </div>
            )}

            {/* Header */}
            <h3
              style={{
                fontFamily: "'Cinzel', serif",
                fontSize: '1.2rem',
                fontWeight: 700,
                color: tier.recommended ? 'rgba(163, 53, 238, 0.85)' : '#C9AA71',
                marginBottom: '1rem',
                textAlign: 'center',
              }}
            >
              {tier.name}
            </h3>

            {/* Price */}
            <div style={{ textAlign: 'center', marginBottom: '1rem' }}>
              {tier.price === 0 ? (
                <span
                  style={{
                    fontFamily: "'Cinzel', serif",
                    fontSize: '1.6rem',
                    fontWeight: 700,
                    color: '#d4c5a9',
                  }}
                >
                  Free Forever
                </span>
              ) : (
                <>
                  <span
                    style={{
                      fontFamily: "'Cinzel', serif",
                      fontSize: '2.25rem',
                      fontWeight: 700,
                      color: '#C9AA71',
                    }}
                  >
                    {tier.price}&euro;
                  </span>
                  <span
                    style={{
                      color: '#4a3f32',
                      fontSize: '0.85rem',
                      marginLeft: '0.2rem',
                    }}
                  >
                    /month
                  </span>
                </>
              )}
            </div>

            {/* Savings */}
            {tier.savings && (
              <div
                style={{
                  textAlign: 'center',
                  color: '#8B7340',
                  fontSize: '0.78rem',
                  fontWeight: 600,
                  marginBottom: '1.25rem',
                  padding: '0.3rem 0.75rem',
                  border: '1px solid rgba(139, 115, 64, 0.15)',
                  borderRadius: '3px',
                  background: 'rgba(139, 115, 64, 0.04)',
                }}
              >
                {tier.savings}
              </div>
            )}

            {/* Features */}
            <ul
              style={{
                listStyle: 'none',
                padding: 0,
                margin: '0 0 1.25rem 0',
                flex: 1,
              }}
            >
              {tier.features.map((feature, j) => (
                <li
                  key={j}
                  style={{
                    color: '#d4c5a9',
                    fontSize: '0.83rem',
                    padding: '0.35rem 0',
                    lineHeight: 1.5,
                    borderBottom: '1px solid #2a2318',
                  }}
                >
                  {feature}
                </li>
              ))}
            </ul>

            {/* Limitations */}
            {tier.limitations && (
              <ul
                style={{
                  listStyle: 'none',
                  padding: 0,
                  margin: '0 0 1.5rem 0',
                }}
              >
                {tier.limitations.map((limit, j) => (
                  <li
                    key={j}
                    style={{
                      color: '#4a3f32',
                      fontSize: '0.78rem',
                      padding: '0.2rem 0',
                    }}
                  >
                    {limit}
                  </li>
                ))}
              </ul>
            )}

            {/* CTA */}
            <a
              href={tier.ctaLink}
              target="_blank"
              rel="noopener noreferrer"
              className={tier.ctaStyle}
              style={{ width: '100%', marginTop: 'auto', textAlign: 'center' }}
            >
              {tier.cta}
            </a>

            {/* Trust Signal */}
            {tier.popular && (
              <div
                style={{
                  textAlign: 'center',
                  color: '#4a3f32',
                  fontSize: '0.72rem',
                  marginTop: '0.75rem',
                }}
              >
                Most popular tier for active recruiters
              </div>
            )}
          </motion.div>
        ))}
      </motion.div>

      {/* Le Légendaire — Lifetime Tier */}
      <motion.div
        initial={{ opacity: 0 }}
        whileInView={{ opacity: 1 }}
        viewport={{ once: true }}
        transition={{ delay: 0.3, duration: 0.8 }}
        style={{
          textAlign: 'center',
          marginTop: '3.5rem',
          padding: '2rem',
          border: '1px solid rgba(163, 53, 238, 0.25)',
          borderRadius: '6px',
          maxWidth: '580px',
          margin: '3.5rem auto 0',
          background: 'linear-gradient(135deg, #1a1814 0%, #1f1a24 100%)',
          boxShadow: '0 0 30px rgba(163, 53, 238, 0.06)',
        }}
      >
        <div
          style={{
            display: 'inline-block',
            background: 'rgba(163, 53, 238, 0.12)',
            color: '#a335ee',
            padding: '0.2rem 0.7rem',
            borderRadius: '3px',
            fontSize: '0.65rem',
            fontWeight: 700,
            letterSpacing: '0.08em',
            fontFamily: "'Cinzel', serif",
            marginBottom: '0.75rem',
          }}
        >
          ONE-TIME PAYMENT
        </div>
        <h3
          style={{
            fontFamily: "'Cinzel', serif",
            fontSize: '1.15rem',
            fontWeight: 700,
            color: '#a335ee',
            marginBottom: '0.5rem',
          }}
        >
          Le L&eacute;gendaire &mdash; 20&euro;
        </h3>
        <p
          style={{
            color: '#a89b80',
            fontSize: '0.88rem',
            marginBottom: '1.25rem',
            lineHeight: 1.6,
          }}
        >
          All Pro features, forever. One payment, lifetime access.
          <br />
          <span style={{ color: '#4a3f32', fontSize: '0.8rem' }}>
            No subscription &bull; No expiration &bull; Priority support
          </span>
        </p>
        <a
          href={LINKS.patreon}
          target="_blank"
          rel="noopener noreferrer"
          className="btn-legendary"
        >
          Become a Legend
        </a>
      </motion.div>

      {/* Guarantee */}
      <motion.p
        initial={{ opacity: 0 }}
        whileInView={{ opacity: 1 }}
        viewport={{ once: true }}
        transition={{ delay: 0.4, duration: 0.8 }}
        style={{
          textAlign: 'center',
          color: '#4a3f32',
          fontSize: '0.82rem',
          marginTop: '2rem',
        }}
      >
        30-Day Money-Back Guarantee &mdash; No Questions Asked
      </motion.p>
    </section>
  );
}
