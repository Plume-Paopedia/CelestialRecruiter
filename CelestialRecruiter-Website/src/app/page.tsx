'use client';

import { StarfieldCanvas } from '@/components/effects/Starfield';
import { ParticleSystem } from '@/components/effects/Particles';
import { AchievementToastContainer } from '@/components/effects/AchievementToast';
import { HeroSection } from '@/components/sections/Hero';
import { FeaturesSection } from '@/components/sections/Features';
import { DashboardPreviewSection } from '@/components/sections/DashboardPreview';
import { PricingSection } from '@/components/sections/Pricing';
import { SocialProofSection } from '@/components/sections/SocialProof';
import { FAQSection } from '@/components/sections/FAQ';
import { FinalCTASection } from '@/components/sections/FinalCTA';
import { Footer } from '@/components/sections/Footer';

export default function HomePage() {
  return (
    <>
      <StarfieldCanvas />
      <ParticleSystem count={12} />
      <AchievementToastContainer />

      <nav className="site-nav">
        <a href="#hero" className="nav-brand">
          Celestial Recruiter
        </a>
        <div className="nav-links">
          {[
            { label: 'Features', href: '#features' },
            { label: 'Dashboard', href: '#dashboard-preview' },
            { label: 'Pricing', href: '#pricing' },
            { label: 'FAQ', href: '#faq' },
          ].map((link) => (
            <a key={link.label} href={link.href} className="nav-link">
              {link.label}
            </a>
          ))}
        </div>
      </nav>

      <main style={{ position: 'relative', zIndex: 10 }}>
        <HeroSection />
        <FeaturesSection />
        <DashboardPreviewSection />
        <SocialProofSection />
        <PricingSection />
        <FAQSection />
        <FinalCTASection />
      </main>

      <Footer />
    </>
  );
}
