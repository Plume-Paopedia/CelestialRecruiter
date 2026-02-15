'use client';

import { motion } from 'framer-motion';
import { AnimatedCounter } from '@/components/ui/AnimatedCounter';
import { HERO_PILLS, LINKS } from '@/lib/constants';
import { fadeInUp, staggerContainer } from '@/lib/animations';
import { SectionDivider } from '@/components/ui/SectionDivider';

/** Unicode icons for each hero pill, replacing emojis */
const PILL_ICONS: Record<string, string> = {
  'Auto-Scanner': '\u25CE',   // bullseye
  'Analytics':    '\u2593',   // bar chart
  'AI Recruiting': '\u2699',  // gear
  'Discord Alerts': '\u2709', // envelope
};

export function HeroSection() {
  return (
    <section className="hero-section" id="hero">
      <motion.div
        className="hero-content"
        initial="hidden"
        animate="visible"
        variants={staggerContainer}
      >
        {/* Version Badge */}
        <motion.span
          variants={fadeInUp}
          className="version-badge"
        >
          v3.5.1
        </motion.span>

        {/* Title */}
        <motion.h1
          className="hero-title"
          variants={fadeInUp}
        >
          Celestial Recruiter
        </motion.h1>

        {/* Divider between title and subtitle */}
        <motion.div variants={fadeInUp}>
          <SectionDivider />
        </motion.div>

        {/* Subtitle */}
        <motion.p
          className="hero-subtitle"
          variants={fadeInUp}
        >
          Legendary-Tier Guild Recruitment Assistant
        </motion.p>

        {/* Tagline */}
        <motion.p
          className="hero-tagline"
          variants={fadeInUp}
        >
          &ldquo;Recruit Like a Mythic Raider, Not a Noob&rdquo;
        </motion.p>

        {/* Feature Pills */}
        <motion.div
          className="feature-pills"
          variants={fadeInUp}
        >
          {HERO_PILLS.map((pill, i) => (
            <motion.div
              key={i}
              className="feature-pill"
              whileHover={{ y: -2 }}
              transition={{ duration: 0.3, ease: [0.25, 0.1, 0.25, 1] }}
            >
              <span className="pill-icon">
                {PILL_ICONS[pill.label] ?? '\u2726'}
              </span>
              {pill.label}
            </motion.div>
          ))}
        </motion.div>

        {/* CTA Buttons */}
        <motion.div
          className="cta-buttons"
          variants={fadeInUp}
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
            Support on Patreon
          </a>
        </motion.div>

        {/* Social Proof Counter */}
        <motion.div
          className="social-proof-counter"
          variants={fadeInUp}
        >
          <AnimatedCounter end={12847} suffix="+" />
          <span>recruits joined via CelestialRecruiter</span>
        </motion.div>
      </motion.div>
    </section>
  );
}
