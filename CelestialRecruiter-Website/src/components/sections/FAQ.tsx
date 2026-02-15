'use client';

import { motion, AnimatePresence } from 'framer-motion';
import { useState } from 'react';
import { FAQS } from '@/lib/constants';
import { fadeInUp, staggerContainer } from '@/lib/animations';

function FAQItem({ q, a }: { q: string; a: string }) {
  const [open, setOpen] = useState(false);

  return (
    <motion.div
      variants={fadeInUp}
      style={{
        background: '#1a1814',
        border: open ? '1px solid #6b5635' : '1px solid #352c20',
        borderRadius: '6px',
        overflow: 'hidden',
        cursor: 'pointer',
        transition: 'border-color 0.3s ease',
      }}
      onClick={() => setOpen(!open)}
    >
      <div
        style={{
          padding: '1.15rem 1.5rem',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          gap: '1rem',
        }}
      >
        <h3
          style={{
            fontFamily: "'Cinzel', serif",
            fontSize: '0.92rem',
            fontWeight: 600,
            color: open ? '#C9AA71' : '#d4c5a9',
            transition: 'color 0.3s ease',
          }}
        >
          {q}
        </h3>
        <span
          style={{
            color: '#8B7340',
            fontSize: '1.1rem',
            transform: open ? 'rotate(45deg)' : 'rotate(0deg)',
            transition: 'transform 0.3s ease',
            flexShrink: 0,
            lineHeight: 1,
          }}
        >
          +
        </span>
      </div>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.3, ease: [0.25, 0.1, 0.25, 1] }}
            style={{ overflow: 'hidden' }}
          >
            <div
              style={{
                padding: '0 1.5rem 1.25rem',
                color: '#a89b80',
                fontSize: '0.88rem',
                lineHeight: 1.7,
                borderTop: '1px solid #2a2318',
                paddingTop: '1rem',
              }}
            >
              {a}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}

export function FAQSection() {
  return (
    <section
      id="faq"
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
        <span className="section-label">FAQ</span>
        <h2>Frequently Asked</h2>
        <p>Got questions? We&apos;ve got answers.</p>
      </motion.div>

      <motion.div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: '0.6rem',
          maxWidth: '720px',
          margin: '0 auto',
        }}
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true, amount: 0.1 }}
        variants={staggerContainer}
      >
        {FAQS.map((faq, i) => (
          <FAQItem key={i} q={faq.q} a={faq.a} />
        ))}
      </motion.div>
    </section>
  );
}
