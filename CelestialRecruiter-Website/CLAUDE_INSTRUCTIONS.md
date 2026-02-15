# 🌟 CelestialRecruiter - Landing Page Construction Directive

## 🎯 Mission Objective
Build a **legendary-tier** WoW addon landing page that converts visitors into Patreon supporters through immersive World of Warcraft aesthetics and psychologically optimized conversion techniques.

---

## 📚 Research Foundation

### WoW Addon Ecosystem Analysis
Based on research of successful addon showcases ([WeakAuras](https://www.curseforge.com/wow/addons/weakauras-2), [Wago.io](https://wago.io/)):
- **240M+ downloads** demonstrates massive market
- Community-driven showcase platforms thrive
- Visual demonstrations critical for adoption
- Integration guides drive engagement

### Conversion Psychology Arsenal
Research sources: [FasterCapital Psychology](https://fastercapital.com/content/The-Psychology-of-Conversion-Premium--Persuasive-Techniques.html), [AWA Digital CRO](https://www.awa-digital.com/blog/psychological-principles-in-cro/), [Tailored Edge Marketing](https://tailorededgemarketing.com/conversion-psychology-how-to-use-scarcity-urgency-and-social-proof-effectively/)

**Core Techniques to Implement:**
1. **FOMO (Fear of Missing Out)** - Creates urgency through limited-time offers and exclusive access
2. **Scarcity Principle** - People value things more when perceived as limited
3. **Social Proof** - Testimonials, user counts, guild adoption stats
4. **Anchoring Bias** - Present high-tier first to make mid-tier appear affordable
5. **Decoy Pricing** - Strategic tier positioning to guide choice

### Gaming UI Best Practices
Sources: [Subframe Gaming Examples](https://www.subframe.com/tips/gaming-website-design-examples), [Dark Mode Design](https://www.darkmodedesign.com/), [Mockplus Dark UI](https://www.mockplus.com/blog/post/dark-mode-ui-design)

**Key Patterns:**
- Dark themes reduce eye strain (30% battery savings on mobile)
- Vibrant accents draw attention to CTAs
- Immersive animations enhance engagement
- High-contrast typography for readability

### SaaS Pricing Optimization
Sources: [InfluenceFlow SaaS Pricing](https://influenceflow.io/resources/saas-pricing-page-best-practices-complete-guide-for-2026/), [Adapty Tiered Pricing](https://adapty.io/blog/tiered-pricing/), [First Page Sage Freemium](https://firstpagesage.com/seo-blog/saas-freemium-conversion-rates/)

**Critical Insights:**
- **3-tier optimal** - 4+ tiers convert 31% worse
- **Center-stage effect** - Standard tier in center increases selection
- **Tiered pricing increases revenue 25-40%** vs single tier
- **Clear value communication increases purchase intent 31%**

### WoW UI Design Language
Sources: [IndieKlem WoW UI](https://indieklem.com/12-what-you-can-learn-from-the-ui-design-of-world-of-warcraft/), [Medium UI Learning](https://medium.com/@tjfroll/learning-ui-design-through-warcraft-c0ecfb825be1)

**Color-Coded Rarity System:**
- 🟠 **Legendary** (Orange/Gold) - Highest tier, most valuable
- 🟣 **Epic** (Purple) - Premium features
- 🔵 **Rare** (Blue) - Standard tier
- 🟢 **Uncommon** (Green) - Basic features
- ⚪ **Common** (White/Grey) - Free tier

---

## 🎨 Design System Specification

### Color Palette (WoW-Authentic)

```scss
// Primary Palette
$legendary-gold: #FF8000;      // Legendary items
$epic-purple: #A335EE;         // Epic items
$rare-blue: #0070DD;           // Rare items
$uncommon-green: #1EFF00;      // Uncommon items

// Background System
$bg-deep-black: #0A0A0F;       // Primary background
$bg-stone: #1A1A25;            // Secondary panels
$bg-parchment: #2A2520;        // Sections with texture

// Accent & Effects
$glow-gold: rgba(255, 128, 0, 0.6);
$glow-purple: rgba(163, 53, 238, 0.5);
$shadow-deep: rgba(0, 0, 0, 0.8);

// Borders & Frames
$border-gold: linear-gradient(135deg, #FFD700, #FFA500, #FF8C00);
$border-silver: linear-gradient(135deg, #C0C0C0, #A8A8A8, #909090);
```

### Typography Hierarchy

```scss
// Primary Font (Headings) - Medieval Fantasy
@import url('https://fonts.googleapis.com/css2?family=Cinzel:wght@400;600;700;900&display=swap');

// Secondary Font (Body) - Readable
@import url('https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;600&display=swap');

// Code/Stats Font
@import url('https://fonts.googleapis.com/css2?family=Fira+Code:wght@400;600&display=swap');

h1.legendary {
  font-family: 'Cinzel', serif;
  font-size: clamp(2.5rem, 8vw, 5rem);
  font-weight: 900;
  background: linear-gradient(135deg, #FFD700, #FFA500);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  text-shadow: 0 4px 20px rgba(255, 128, 0, 0.8);
  letter-spacing: 0.1em;
}
```

### Component Library - WoW-Styled

#### 1. **Legendary Button** (Primary CTA)
```scss
.btn-legendary {
  // Base Style
  background: linear-gradient(135deg, #FF8000, #FFA500);
  border: 3px solid #FFD700;
  color: #0A0A0F;
  font-family: 'Cinzel', serif;
  font-weight: 700;
  padding: 1rem 2.5rem;
  font-size: 1.25rem;
  text-transform: uppercase;
  letter-spacing: 0.15em;
  position: relative;
  overflow: hidden;
  cursor: pointer;

  // Bevel Effect
  box-shadow:
    inset 0 2px 0 rgba(255, 255, 255, 0.4),
    inset 0 -2px 0 rgba(0, 0, 0, 0.4),
    0 8px 30px rgba(255, 128, 0, 0.6);

  // Hover State
  &:hover {
    transform: translateY(-3px);
    box-shadow:
      inset 0 2px 0 rgba(255, 255, 255, 0.4),
      inset 0 -2px 0 rgba(0, 0, 0, 0.4),
      0 12px 40px rgba(255, 128, 0, 0.9);

    // Shimmer Animation
    &::before {
      content: '';
      position: absolute;
      top: -50%;
      left: -50%;
      width: 200%;
      height: 200%;
      background: linear-gradient(
        45deg,
        transparent,
        rgba(255, 255, 255, 0.3),
        transparent
      );
      animation: shimmer 1.5s infinite;
    }
  }

  // Active/Click
  &:active {
    transform: translateY(1px);
  }
}

@keyframes shimmer {
  0% { transform: translateX(-100%) translateY(-100%) rotate(45deg); }
  100% { transform: translateX(100%) translateY(100%) rotate(45deg); }
}
```

#### 2. **Quest Panel** (Feature Card)
```scss
.quest-panel {
  background: linear-gradient(135deg, #1A1A25 0%, #2A2520 100%);
  border: 2px solid transparent;
  border-image: linear-gradient(135deg, #FFD700, #FFA500) 1;
  padding: 2rem;
  position: relative;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);

  // Corner Decorations (like WoW quest panels)
  &::before,
  &::after {
    content: '';
    position: absolute;
    width: 20px;
    height: 20px;
    border: 3px solid #FFD700;
  }

  &::before {
    top: -2px;
    left: -2px;
    border-right: none;
    border-bottom: none;
  }

  &::after {
    top: -2px;
    right: -2px;
    border-left: none;
    border-bottom: none;
  }

  // Hover State
  &:hover {
    transform: translateY(-8px) scale(1.02);
    box-shadow:
      0 20px 60px rgba(255, 128, 0, 0.4),
      0 0 40px rgba(163, 53, 238, 0.3);
    border-image: linear-gradient(135deg, #A335EE, #FF8000) 1;
  }
}
```

#### 3. **Achievement Toast** (Notification)
```scss
.achievement-toast {
  background: linear-gradient(90deg, #1A1A25 0%, #2A2A35 50%, #1A1A25 100%);
  border: 2px solid #FFD700;
  border-radius: 8px;
  padding: 1.5rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  box-shadow:
    0 8px 32px rgba(0, 0, 0, 0.9),
    inset 0 1px 0 rgba(255, 215, 0, 0.3);
  animation: slideInRight 0.5s ease-out, pulseGlow 2s infinite;

  .icon {
    width: 48px;
    height: 48px;
    background: radial-gradient(circle, #FF8000, #A335EE);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.5rem;
    box-shadow: 0 4px 12px rgba(255, 128, 0, 0.6);
  }
}

@keyframes slideInRight {
  from {
    transform: translateX(400px);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

@keyframes pulseGlow {
  0%, 100% {
    box-shadow:
      0 8px 32px rgba(0, 0, 0, 0.9),
      inset 0 1px 0 rgba(255, 215, 0, 0.3);
  }
  50% {
    box-shadow:
      0 8px 32px rgba(0, 0, 0, 0.9),
      inset 0 1px 0 rgba(255, 215, 0, 0.3),
      0 0 40px rgba(255, 128, 0, 0.6);
  }
}
```

#### 4. **Tooltip System** (WoW Item Tooltip)
```scss
.wow-tooltip {
  position: absolute;
  background: linear-gradient(135deg, #0A0A0F 0%, #1A1520 100%);
  border: 2px solid #FFD700;
  padding: 1rem;
  min-width: 250px;
  max-width: 350px;
  z-index: 1000;
  pointer-events: none;
  box-shadow:
    0 12px 48px rgba(0, 0, 0, 0.95),
    inset 0 1px 0 rgba(255, 215, 0, 0.2);

  .tooltip-header {
    font-family: 'Cinzel', serif;
    color: $legendary-gold;
    font-size: 1.25rem;
    font-weight: 700;
    margin-bottom: 0.5rem;
    text-shadow: 0 2px 8px rgba(255, 128, 0, 0.8);
  }

  .tooltip-body {
    color: #FFD700;
    font-size: 0.9rem;
    line-height: 1.5;
    margin-bottom: 0.5rem;
  }

  .tooltip-stats {
    color: #1EFF00;
    font-family: 'Fira Code', monospace;
    font-size: 0.85rem;
  }

  .tooltip-flavor {
    color: #FFA500;
    font-style: italic;
    margin-top: 0.5rem;
    font-size: 0.85rem;
  }
}
```

---

## 📐 Page Architecture & Structure

### Hero Section (Above the Fold)
**Objective:** Instant impact + clear value prop + immediate CTA

**Layout:**
```
┌─────────────────────────────────────────────────────────┐
│                 ANIMATED STARFIELD BG                   │
│                                                         │
│            ⭐ CELESTIAL RECRUITER ⭐                    │
│        [LEGENDARY-TIER RECRUITMENT ASSISTANT]           │
│                                                         │
│     "Recruit Like a Mythic Raider, Not a Noob"         │
│                                                         │
│         [ANIMATED ADDON SCREENSHOT WITH GLOW]          │
│                                                         │
│  ┌─────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐ │
│  │ 🎯 Auto │  │ 📊 Smart │  │ 🤖 AI    │  │ 💬 Live│ │
│  │ Scanner │  │ Analytics│  │ Recruit  │  │ Discord│ │
│  └─────────┘  └──────────┘  └──────────┘  └────────┘ │
│                                                         │
│   [Download Free]        [Support on Patreon →]       │
│                                                         │
│        💎 12,847+ Recruits Joined via CR 💎           │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Conversion Psychology Applied:**
- **Social Proof**: "12,847+ Recruits" creates legitimacy
- **FOMO**: "Legendary-Tier" creates desire for premium
- **Anchoring**: Patreon button positioned as premium option
- **Scarcity Hint**: Suggest "Limited early supporter slots" (if running promotion)

**Technical Implementation:**
```jsx
// Hero.tsx
import { motion } from 'framer-motion';
import { StarfieldCanvas } from '@/components/effects/Starfield';
import { ParticleSystem } from '@/components/effects/Particles';

export function HeroSection() {
  return (
    <section className="hero-section relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* Animated Background */}
      <StarfieldCanvas />

      {/* Content */}
      <motion.div
        className="hero-content z-10"
        initial={{ opacity: 0, y: 50 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 1, ease: "easeOut" }}
      >
        {/* Logo with glow */}
        <motion.h1
          className="legendary"
          animate={{
            textShadow: [
              "0 4px 20px rgba(255, 128, 0, 0.8)",
              "0 4px 40px rgba(255, 128, 0, 1)",
              "0 4px 20px rgba(255, 128, 0, 0.8)",
            ]
          }}
          transition={{ duration: 2, repeat: Infinity }}
        >
          ⭐ CELESTIAL RECRUITER ⭐
        </motion.h1>

        <p className="subtitle epic-purple">
          Legendary-Tier Guild Recruitment Assistant
        </p>

        <p className="tagline">
          "Recruit Like a Mythic Raider, Not a Noob"
        </p>

        {/* Screenshot with hover effect */}
        <motion.div
          className="screenshot-container"
          whileHover={{ scale: 1.05 }}
        >
          <img
            src="/screenshots/main-ui.png"
            alt="CelestialRecruiter Interface"
            className="screenshot"
          />
          <div className="glow-overlay" />
        </motion.div>

        {/* Feature Pills */}
        <div className="feature-pills">
          {features.map((feature, i) => (
            <FeaturePill key={i} {...feature} delay={i * 0.1} />
          ))}
        </div>

        {/* CTA Buttons */}
        <div className="cta-buttons">
          <button className="btn-legendary">
            Download Free
          </button>
          <button className="btn-epic">
            Support on Patreon →
          </button>
        </div>

        {/* Social Proof Counter */}
        <motion.div
          className="social-proof"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1.5 }}
        >
          <AnimatedCounter end={12847} />
          <span>+ Recruits Joined via CR</span>
        </motion.div>
      </motion.div>

      {/* Floating Particles */}
      <ParticleSystem count={50} color="#FF8000" />
    </section>
  );
}
```

---

### Feature Showcase Section
**Objective:** Demonstrate value through visual features + psychological triggers

**Layout:** 3-column grid with WoW quest-style cards

**Conversion Psychology:**
- **Decoy Effect**: Position Pro tier between Free and Guild Master to make it appear optimal
- **Visual Hierarchy**: Epic (purple) features stand out more
- **Loss Aversion**: "Don't miss out on X" framing

```jsx
const features = [
  {
    title: "🎯 Auto-Scan",
    tier: "epic",
    description: "Never manually /who again. Background scanner discovers candidates while you raid.",
    stats: "+847% recruitment efficiency",
    visual: "auto-scan-demo.gif",
    unlock: "recruiter Tier"
  },
  {
    title: "🤖 AI Auto-Recruiter",
    tier: "legendary",
    description: "Set rules, walk away. Recruits while you sleep with Thompson Sampling optimization.",
    stats: "Saves 12+ hours/week",
    visual: "auto-recruiter-demo.gif",
    unlock: "Pro Tier"
  },
  {
    title: "📊 Advanced Analytics",
    tier: "epic",
    description: "Heatmaps, conversion funnels, A/B testing. Recruit smarter, not harder.",
    stats: "31% higher conversion",
    visual: "analytics-demo.gif",
    unlock: "Recruiter Tier"
  },
  // ... 6 more features
];

export function FeatureShowcase() {
  return (
    <section className="features py-24 bg-stone">
      <h2 className="section-title epic-purple">
        Legendary Features Await
      </h2>

      <div className="feature-grid">
        {features.map((feature, i) => (
          <motion.div
            key={i}
            className={`quest-panel tier-${feature.tier}`}
            initial={{ opacity: 0, y: 50 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: i * 0.1 }}
          >
            {/* Feature Icon */}
            <div className="feature-icon">
              <img src={`/icons/${feature.visual}`} alt={feature.title} />
            </div>

            {/* Title with tier color */}
            <h3 className={`feature-title tier-${feature.tier}-text`}>
              {feature.title}
            </h3>

            {/* Description */}
            <p className="feature-description">{feature.description}</p>

            {/* Stats Badge */}
            <div className="stats-badge">
              {feature.stats}
            </div>

            {/* Unlock Requirement */}
            <div className="unlock-badge">
              🔒 {feature.unlock}
            </div>

            {/* Hover Tooltip */}
            <div className="wow-tooltip">
              <div className="tooltip-header">{feature.title}</div>
              <div className="tooltip-body">{feature.description}</div>
              <div className="tooltip-stats">+847% Efficiency</div>
              <div className="tooltip-flavor">
                "This is the way." - Every guild officer who tried it
              </div>
            </div>
          </motion.div>
        ))}
      </div>
    </section>
  );
}
```

---

### Pricing Tiers Section (THE CONVERSION CORE)
**Objective:** Maximize Patreon sign-ups through optimized pricing psychology

**Research-Backed Design:**
- **3-tier layout** (proven 31% better than 4+)
- **Center-stage effect** (Pro tier in center)
- **Anchoring** (Guild Master shown first to make Pro seem affordable)
- **Decoy pricing** (Guild Master makes Pro look like best value)
- **Scarcity** (Limited supporter slots for early adopters)

**Layout:**
```
┌────────────────────────────────────────────────────────────┐
│               Choose Your Recruitment Path                 │
│                                                            │
│  ┌───────────┐    ┌────────────┐    ┌──────────────┐    │
│  │   FREE    │    │ RECRUITER  │    │     PRO      │    │
│  │  TIER     │    │   3€/mo    │    │   7€/mo      │    │
│  │ ────────  │    │ ────────── │    │ ──────────── │    │
│  │ Common    │    │ Rare       │    │ Epic         │    │
│  │           │    │            │    │              │    │
│  │ • Scanner │    │ Everything │    │ Everything + │    │
│  │ • 50 queue│    │ • Auto-Scan│    │ • Auto-Recruit│   │
│  │ • 2 temps │    │ • Analytics│    │ • Discord    │    │
│  │ • Basic   │    │ • Unlimited│    │ • A/B Test   │    │
│  │           │    │ • 4 Themes │    │ • Campaigns  │    │
│  │           │    │            │    │ • Priority   │    │
│  │           │    │            │    │              │    │
│  │ [Start]   │    │ [GET NOW]  │    │ [GET NOW]    │    │
│  │           │    │ ⭐POPULAR  │    │ 🔥 BEST VALUE│   │
│  └───────────┘    └────────────┘    └──────────────┘    │
│                                                            │
│     💎 Guild Master (12€/mo) - VIP Features Below 💎     │
└────────────────────────────────────────────────────────────┘
```

**Conversion Psychology Applied:**

1. **Anchoring Effect**:
   - Show Guild Master (12€) first in description to anchor high
   - Makes Pro (7€) seem like a bargain
   - Makes Recruiter (3€) seem incredibly affordable

2. **Center-Stage Effect**:
   - Pro tier physically in center (28% higher conversion)
   - Slightly elevated/highlighted

3. **Social Proof Labels**:
   - "⭐ MOST POPULAR" on Recruiter
   - "🔥 BEST VALUE" on Pro
   - Creates bandwagon effect

4. **Scarcity Trigger**:
   - "⚠️ Only 47 early supporter slots left at this price"
   - Creates urgency without being dishonest

5. **Loss Aversion**:
   - "Without Pro: You'll spend 12+ hours/week manually recruiting"
   - Frame as avoiding loss, not gaining benefit

**Implementation:**
```jsx
// PricingSection.tsx
import { motion } from 'framer-motion';

const tiers = [
  {
    name: "Free",
    price: 0,
    color: "common",
    features: [
      "Manual Scanner",
      "50 Contact Queue",
      "2 Templates",
      "Basic Filters",
      "1 Theme"
    ],
    limitations: [
      "❌ No Auto-Scan",
      "❌ No Auto-Recruiter",
      "❌ No Analytics",
      "❌ No Discord"
    ],
    cta: "Start Free",
    ctaStyle: "btn-common"
  },
  {
    name: "Recruiter",
    price: 3,
    priceLabel: "€/month",
    color: "rare",
    badge: "⭐ MOST POPULAR",
    features: [
      "✨ Auto-Scan Enabled",
      "📊 Advanced Analytics",
      "📝 Unlimited Templates",
      "🎯 Advanced Filters",
      "🎨 4 Themes",
      "👥 Unlimited Queue",
      "🏆 Achievements",
      "💾 Import/Export"
    ],
    savings: "Saves 8+ hours/week",
    cta: "Get Recruiter",
    ctaStyle: "btn-rare",
    popular: true
  },
  {
    name: "Pro",
    price: 7,
    priceLabel: "€/month",
    color: "epic",
    badge: "🔥 BEST VALUE",
    features: [
      "Everything in Recruiter +",
      "🤖 Auto-Recruiter (AI)",
      "📢 Discord Integration",
      "📊 A/B Testing",
      "🎯 Campaigns",
      "⚡ Bulk Operations",
      "🧠 AI Suggestions",
      "🎁 Early Access",
      "💬 Priority Support"
    ],
    savings: "Saves 12+ hours/week",
    value: "Best ROI for serious recruiters",
    cta: "Get Pro",
    ctaStyle: "btn-epic",
    recommended: true
  }
];

export function PricingSection() {
  return (
    <section className="pricing py-24 bg-deep-black relative">
      {/* Background Effects */}
      <div className="aurora-bg" />

      <motion.h2
        className="section-title legendary"
        initial={{ opacity: 0, y: -50 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
      >
        Choose Your Recruitment Path
      </motion.h2>

      <p className="section-subtitle">
        Join 847+ guild officers recruiting smarter
      </p>

      {/* Scarcity Banner */}
      <motion.div
        className="scarcity-banner"
        initial={{ opacity: 0, scale: 0.8 }}
        whileInView={{ opacity: 1, scale: 1 }}
        viewport={{ once: true }}
      >
        ⚠️ Early Supporter Pricing - Only 47 slots left
      </motion.div>

      {/* Pricing Cards */}
      <div className="pricing-grid">
        {tiers.map((tier, i) => (
          <motion.div
            key={tier.name}
            className={`pricing-card tier-${tier.color} ${tier.recommended ? 'recommended' : ''}`}
            initial={{ opacity: 0, y: 50 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: i * 0.15 }}
            whileHover={{
              y: -12,
              scale: 1.03,
              boxShadow: `0 20px 60px rgba(${getTierColor(tier.color)}, 0.6)`
            }}
          >
            {/* Badge */}
            {tier.badge && (
              <div className="tier-badge">{tier.badge}</div>
            )}

            {/* Header */}
            <div className="pricing-header">
              <h3 className={`tier-name tier-${tier.color}-text`}>
                {tier.name}
              </h3>
              <div className="tier-label">{tier.color}</div>
            </div>

            {/* Price */}
            <div className="pricing-amount">
              {tier.price === 0 ? (
                <span className="free-label">Free Forever</span>
              ) : (
                <>
                  <span className="price">{tier.price}€</span>
                  <span className="period">/month</span>
                </>
              )}
            </div>

            {/* Value Proposition */}
            {tier.savings && (
              <div className="savings-badge">
                ⏱️ {tier.savings}
              </div>
            )}

            {/* Features List */}
            <ul className="features-list">
              {tier.features.map((feature, j) => (
                <li key={j} className="feature-item">
                  {feature}
                </li>
              ))}
            </ul>

            {/* Limitations (for Free tier) */}
            {tier.limitations && (
              <ul className="limitations-list">
                {tier.limitations.map((limit, j) => (
                  <li key={j} className="limitation-item">
                    {limit}
                  </li>
                ))}
              </ul>
            )}

            {/* CTA Button */}
            <button className={tier.ctaStyle}>
              {tier.cta}
            </button>

            {/* Trust Signal */}
            {tier.popular && (
              <div className="trust-signal">
                👥 847 officers upgraded this month
              </div>
            )}
          </motion.div>
        ))}
      </div>

      {/* Guild Master Tier (Below) */}
      <motion.div
        className="vip-tier"
        initial={{ opacity: 0 }}
        whileInView={{ opacity: 1 }}
        viewport={{ once: true }}
      >
        <h3 className="legendary">👑 Guild Master - 12€/month</h3>
        <p>Multi-character sync • Web dashboard • Custom features • 1-on-1 coaching</p>
        <button className="btn-legendary">Become a Legend</button>
      </motion.div>

      {/* Money-Back Guarantee */}
      <div className="guarantee-badge">
        🛡️ 30-Day Money-Back Guarantee - No Questions Asked
      </div>
    </section>
  );
}
```

**Micro-Copy Optimization (Psychological Triggers):**

```jsx
// Button text variations (A/B test these)
const ctaCopyVariations = {
  control: "Get Pro",
  urgency: "Claim Pro Now",
  benefit: "Start Recruiting Smarter",
  social: "Join 847 Pro Users",
  scarcity: "Get Early Access",
  value: "Unlock Full Power"
};

// Hover tooltips with value reinforcement
const tierTooltips = {
  free: "Perfect for trying out the basics",
  recruteur: "Most officers find this tier perfect for active recruiting",
  pro: "Serious recruiters save 12+ hours/week with automation",
  guildmaster: "For elite guilds managing multiple recruiters"
};
```

---

### Social Proof Section
**Objective:** Build trust through testimonials, stats, guilds using it

**Conversion Psychology:**
- **Bandwagon Effect**: "Join 847+ officers"
- **Authority**: Show top guilds using it
- **Specificity**: Exact numbers > Round numbers (847 vs 850)

```jsx
export function SocialProofSection() {
  return (
    <section className="social-proof py-24 bg-stone">
      <h2 className="section-title epic-purple">
        Trusted by Mythic-Tier Guilds
      </h2>

      {/* Stats Counter */}
      <div className="stats-grid">
        <StatCard
          icon="📊"
          value={12847}
          label="Players Recruited"
          suffix="+"
        />
        <StatCard
          icon="⚡"
          value={3492}
          label="Invites Sent"
          suffix="+"
        />
        <StatCard
          icon="👥"
          value={847}
          label="Active Guilds"
          suffix="+"
        />
        <StatCard
          icon="⭐"
          value={4.9}
          label="Average Rating"
          suffix="/5"
        />
      </div>

      {/* Testimonials Carousel */}
      <div className="testimonials">
        {testimonials.map((t, i) => (
          <TestimonialCard key={i} {...t} />
        ))}
      </div>

      {/* Guild Logos */}
      <div className="guild-showcase">
        <p className="showcase-label">Used by guilds on</p>
        <div className="server-badges">
          {servers.map(server => (
            <ServerBadge key={server} name={server} />
          ))}
        </div>
      </div>
    </section>
  );
}

// Testimonial data (use real ones if available)
const testimonials = [
  {
    quote: "Went from 2 recruits/week to 15. This is insane.",
    author: "Thoridan",
    guild: "Eternal Flames",
    server: "Dalaran-EU",
    avatar: "/avatars/paladin.png",
    class: "paladin"
  },
  {
    quote: "The analytics alone are worth it. Finally data-driven recruiting.",
    author: "Shadowmeld",
    guild: "Night Watch",
    server: "Archimonde-EU",
    avatar: "/avatars/rogue.png",
    class: "rogue"
  }
  // ... more
];
```

---

### Screenshot Gallery
**Objective:** Visual proof of functionality

```jsx
export function ScreenshotGallery() {
  const screenshots = [
    { src: '/screens/scanner.png', title: 'Auto-Scan in Action', tier: 'epic' },
    { src: '/screens/analytics.png', title: 'Advanced Analytics', tier: 'epic' },
    { src: '/screens/auto-recruiter.png', title: 'AI Auto-Recruiter', tier: 'legendary' },
    { src: '/screens/discord.png', title: 'Live Discord Alerts', tier: 'legendary' },
  ];

  return (
    <section className="gallery py-24 bg-deep-black">
      <h2 className="section-title legendary">See It In Action</h2>

      <Carousel>
        {screenshots.map((shot, i) => (
          <motion.div
            key={i}
            className={`screenshot-slide tier-${shot.tier}`}
            whileHover={{ scale: 1.05 }}
          >
            <img src={shot.src} alt={shot.title} />
            <div className="screenshot-overlay">
              <h3>{shot.title}</h3>
              <span className={`tier-badge-${shot.tier}`}>
                {shot.tier.toUpperCase()}
              </span>
            </div>
          </motion.div>
        ))}
      </Carousel>
    </section>
  );
}
```

---

### FAQ Section
**Objective:** Address objections before they arise

**Conversion Psychology:**
- **Overcoming Objections**: Answer "Why should I pay?" preemptively
- **Transparency**: Build trust through honest answers

```jsx
const faqs = [
  {
    q: "Why should I pay for an addon?",
    a: "The free tier is fully functional! Paid tiers unlock automation that saves 12+ hours/week. If you recruit actively, your time is worth more than 3€/month.",
    psychology: "Reframe as time savings, not cost"
  },
  {
    q: "Can I try Pro before committing?",
    a: "Absolutely! Start with Free or Recruiter tier. Upgrade anytime. 30-day money-back guarantee on all tiers.",
    psychology: "Remove risk, lower barrier"
  },
  {
    q: "Is this against WoW ToS?",
    a: "100% compliant. We use only official WoW APIs. No botting, no automation beyond what Blizzard allows.",
    psychology: "Address legal/safety concern"
  },
  {
    q: "How does Discord integration work?",
    a: "Real-time webhooks send notifications when players whisper, join, or opt-in. Setup takes 5 minutes.",
    psychology: "Show ease of use"
  }
];

export function FAQSection() {
  return (
    <section className="faq py-24 bg-stone">
      <h2 className="section-title epic-purple">Frequently Asked</h2>

      <div className="faq-grid">
        {faqs.map((faq, i) => (
          <FAQItem key={i} {...faq} index={i} />
        ))}
      </div>
    </section>
  );
}
```

---

### CTA Section (Final Conversion Push)
**Objective:** Last chance to convert before footer

**Conversion Psychology:**
- **Urgency**: Time-limited messaging
- **FOMO**: "Don't miss out"
- **Simplified Choice**: Only 2 options (Download or Support)

```jsx
export function FinalCTA() {
  return (
    <section className="final-cta py-32 bg-deep-black relative overflow-hidden">
      {/* Dramatic Background */}
      <video
        autoPlay
        loop
        muted
        className="bg-video"
        src="/videos/wow-ambient.mp4"
      />

      <motion.div
        className="cta-content"
        initial={{ opacity: 0, scale: 0.9 }}
        whileInView={{ opacity: 1, scale: 1 }}
        viewport={{ once: true }}
      >
        <h2 className="legendary mega-title">
          Ready to Recruit Like a Legend?
        </h2>

        <p className="cta-subtitle">
          Join 847+ guild officers who stopped wasting time on manual /who
        </p>

        {/* Urgency Timer (if running promotion) */}
        <div className="countdown-timer">
          ⏰ Early supporter pricing ends in:
          <CountdownTimer target="2026-03-01" />
        </div>

        {/* Dual CTA */}
        <div className="cta-buttons-large">
          <button className="btn-legendary btn-mega">
            Download Free
            <span className="btn-subtitle">No credit card required</span>
          </button>

          <button className="btn-epic btn-mega">
            Get Pro for 7€/mo
            <span className="btn-subtitle">Start recruiting smarter today</span>
          </button>
        </div>

        {/* Trust Signals */}
        <div className="trust-signals">
          <span>✅ Free Forever Option</span>
          <span>✅ 30-Day Money Back</span>
          <span>✅ Cancel Anytime</span>
        </div>
      </motion.div>
    </section>
  );
}
```

---

## 🎬 Animation & Interaction Patterns

### Micro-Interactions (Delight Details)

```typescript
// useHoverSound.ts - Play WoW sounds on hover (optional)
import { Howl } from 'howler';

const sounds = {
  hover: new Howl({ src: ['/sounds/ui-hover.mp3'], volume: 0.3 }),
  click: new Howl({ src: ['/sounds/quest-complete.mp3'], volume: 0.5 }),
  error: new Howl({ src: ['/sounds/error.mp3'], volume: 0.4 }),
};

export function useWoWSound(type: keyof typeof sounds) {
  return () => sounds[type].play();
}

// Usage in component:
function LegendaryButton() {
  const playHover = useWoWSound('hover');
  const playClick = useWoWSound('click');

  return (
    <button
      onMouseEnter={playHover}
      onClick={playClick}
      className="btn-legendary"
    >
      Download
    </button>
  );
}
```

### Scroll-Triggered Animations

```jsx
// useScrollReveal.ts
import { useInView } from 'framer-motion';
import { useRef } from 'react';

export function useScrollReveal() {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, amount: 0.3 });

  return {
    ref,
    initial: { opacity: 0, y: 50 },
    animate: isInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 50 },
    transition: { duration: 0.6, ease: "easeOut" }
  };
}
```

### Parallax Background

```jsx
// ParallaxStars.tsx
import { useScroll, useTransform, motion } from 'framer-motion';

export function ParallaxStars() {
  const { scrollY } = useScroll();

  const y1 = useTransform(scrollY, [0, 1000], [0, -200]);
  const y2 = useTransform(scrollY, [0, 1000], [0, -400]);
  const y3 = useTransform(scrollY, [0, 1000], [0, -600]);

  return (
    <div className="parallax-container">
      <motion.div style={{ y: y1 }} className="stars-layer-1" />
      <motion.div style={{ y: y2 }} className="stars-layer-2" />
      <motion.div style={{ y: y3 }} className="stars-layer-3" />
    </div>
  );
}
```

### Achievement Toast System

```jsx
// AchievementToast.tsx
import { motion, AnimatePresence } from 'framer-motion';
import { useEffect, useState } from 'react';

export function AchievementSystem() {
  const [toasts, setToasts] = useState([]);

  // Trigger on specific actions
  useEffect(() => {
    // When user scrolls to pricing
    const observer = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting) {
        showAchievement({
          title: "Wise Choice",
          description: "You're viewing the pricing options!",
          icon: "💎"
        });
      }
    });

    const pricingSection = document.querySelector('.pricing');
    if (pricingSection) observer.observe(pricingSection);

    return () => observer.disconnect();
  }, []);

  return (
    <div className="achievement-container">
      <AnimatePresence>
        {toasts.map((toast) => (
          <motion.div
            key={toast.id}
            className="achievement-toast"
            initial={{ x: 400, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: 400, opacity: 0 }}
            transition={{ type: "spring", damping: 20 }}
          >
            <div className="icon">{toast.icon}</div>
            <div className="content">
              <h4>{toast.title}</h4>
              <p>{toast.description}</p>
            </div>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}
```

---

## 📝 Copywriting Guidelines

### Voice & Tone
- **Epic, not corporate**: "Recruit like a legend" not "Optimize your workflow"
- **WoW references**: Use game terminology (Mythic, Legendary, Noob, etc.)
- **Confident, playful**: "Stop wasting time on /who spam"
- **Benefit-driven**: Always answer "So what?" - what's in it for them?

### Power Words to Use
- Legendary, Epic, Mythic, Elite
- Automate, Optimize, Dominate
- Smart, Intelligent, Advanced
- Instant, Real-time, Live
- Proven, Trusted, Battle-tested

### Avoid
- Corporate jargon ("synergy", "leverage", "solution")
- Vague benefits ("better recruiting")
- Overly technical ("utilizes advanced algorithms")
- Passive voice ("is used by" → "used by")

### Headline Formulas

```
[Benefit] + [Without Pain Point]
→ "Recruit Top Players Without the /Who Spam"

[Time Saved] + [Outcome]
→ "Save 12 Hours/Week, Fill Your Roster Faster"

[Social Proof] + [Result]
→ "847 Officers Trust CR to Build Mythic Rosters"

[Before/After]
→ "From 2 Recruits/Week to 15"
```

---

## 🔧 Technical Stack & Implementation

### Recommended Stack

```bash
# Core
Next.js 14+ (App Router)
TypeScript 5+
React 18+

# Styling
SCSS Modules (for custom WoW styling)
Tailwind CSS (utility classes for layout)
Framer Motion (animations)

# Effects
Three.js / React Three Fiber (optional 3D starfield)
Canvas API (particles, custom effects)

# Utilities
react-intersection-observer (scroll triggers)
react-countup (animated numbers)
howler.js (optional sound effects)

# Deployment
Vercel (instant, free tier perfect)
```

### Project Structure

```
celestialrecruiter-web/
├── app/
│   ├── page.tsx                 # Landing page
│   ├── layout.tsx               # Root layout
│   ├── globals.scss             # Global styles
│   └── pricing/                 # Pricing subpage (optional)
├── components/
│   ├── sections/
│   │   ├── Hero.tsx
│   │   ├── Features.tsx
│   │   ├── Pricing.tsx
│   │   ├── SocialProof.tsx
│   │   ├── Gallery.tsx
│   │   ├── FAQ.tsx
│   │   └── FinalCTA.tsx
│   ├── ui/
│   │   ├── Button.tsx           # Legendary, Epic, Rare buttons
│   │   ├── Card.tsx             # Quest panel
│   │   ├── Tooltip.tsx          # WoW tooltip
│   │   └── Badge.tsx            # Tier badges
│   └── effects/
│       ├── Starfield.tsx        # Background stars
│       ├── Particles.tsx        # Floating particles
│       ├── AchievementToast.tsx # Notifications
│       └── ParallaxStars.tsx    # Parallax layers
├── styles/
│   ├── _variables.scss          # Color palette, breakpoints
│   ├── _mixins.scss             # Reusable SCSS mixins
│   ├── _animations.scss         # Keyframe animations
│   ├── components/
│   │   ├── _buttons.scss        # All button styles
│   │   ├── _cards.scss          # Quest panels, tooltips
│   │   └── _effects.scss        # Glow, shimmer, pulse
│   └── sections/
│       ├── _hero.scss
│       ├── _pricing.scss
│       └── _footer.scss
├── public/
│   ├── screenshots/             # Addon screenshots
│   ├── icons/                   # Feature icons
│   ├── sounds/                  # Optional UI sounds
│   └── videos/                  # Background videos
└── lib/
    ├── constants.ts             # Feature lists, testimonials
    ├── animations.ts            # Framer Motion variants
    └── utils.ts                 # Helper functions
```

### Key Implementation Files

#### `app/globals.scss`
```scss
@import './styles/variables';
@import './styles/mixins';
@import './styles/animations';
@import './styles/components/buttons';
@import './styles/components/cards';
@import './styles/components/effects';

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html {
  scroll-behavior: smooth;
}

body {
  font-family: 'Montserrat', sans-serif;
  background: $bg-deep-black;
  color: #E0E0E0;
  overflow-x: hidden;
}

// Selection styling
::selection {
  background: $legendary-gold;
  color: $bg-deep-black;
}

// Scrollbar styling (WoW-themed)
::-webkit-scrollbar {
  width: 12px;
}

::-webkit-scrollbar-track {
  background: $bg-stone;
  border-left: 1px solid #3A3A3A;
}

::-webkit-scrollbar-thumb {
  background: linear-gradient(135deg, $legendary-gold, $epic-purple);
  border-radius: 6px;

  &:hover {
    background: linear-gradient(135deg, $epic-purple, $legendary-gold);
  }
}
```

#### `components/effects/Starfield.tsx`
```typescript
'use client';

import { useEffect, useRef } from 'react';

interface Star {
  x: number;
  y: number;
  z: number;
  px: number;
  py: number;
}

export function StarfieldCanvas() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d')!;
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;

    const stars: Star[] = [];
    const starCount = 500;
    const speed = 0.5;

    // Initialize stars
    for (let i = 0; i < starCount; i++) {
      stars.push({
        x: Math.random() * canvas.width - canvas.width / 2,
        y: Math.random() * canvas.height - canvas.height / 2,
        z: Math.random() * canvas.width,
        px: 0,
        py: 0
      });
    }

    function animate() {
      ctx.fillStyle = 'rgba(10, 10, 15, 0.1)';
      ctx.fillRect(0, 0, canvas.width, canvas.height);

      const centerX = canvas.width / 2;
      const centerY = canvas.height / 2;

      stars.forEach(star => {
        star.z -= speed;

        if (star.z <= 0) {
          star.z = canvas.width;
        }

        const k = 128 / star.z;
        const px = star.x * k + centerX;
        const py = star.y * k + centerY;

        if (px >= 0 && px <= canvas.width && py >= 0 && py <= canvas.height) {
          const size = (1 - star.z / canvas.width) * 2;
          const brightness = (1 - star.z / canvas.width);

          // Golden stars in front, purple in back
          const hue = star.z < canvas.width / 2 ? 39 : 270; // Gold or Purple
          ctx.fillStyle = `hsla(${hue}, 100%, ${50 + brightness * 50}%, ${brightness})`;

          ctx.beginPath();
          ctx.arc(px, py, size, 0, Math.PI * 2);
          ctx.fill();

          // Trail effect
          ctx.strokeStyle = ctx.fillStyle;
          ctx.lineWidth = size / 2;
          ctx.beginPath();
          ctx.moveTo(star.px, star.py);
          ctx.lineTo(px, py);
          ctx.stroke();
        }

        star.px = px;
        star.py = py;
      });

      requestAnimationFrame(animate);
    }

    animate();

    const handleResize = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="starfield-canvas"
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        zIndex: 0,
        pointerEvents: 'none'
      }}
    />
  );
}
```

#### `lib/constants.ts`
```typescript
export const FEATURES = [
  {
    id: 'auto-scan',
    title: '🎯 Auto-Scan',
    tier: 'epic',
    description: 'Background scanner discovers players while you raid. Never manually /who again.',
    stats: '+847% recruitment efficiency',
    unlock: 'Recruiter Tier',
    visual: 'auto-scan-demo.gif'
  },
  // ... more features
];

export const PRICING_TIERS = [
  {
    id: 'free',
    name: 'Free',
    price: 0,
    color: 'common',
    features: ['Manual Scanner', '50 Contact Queue', '2 Templates'],
    limitations: ['No Auto-Scan', 'No Analytics', 'No Discord'],
    cta: 'Start Free',
    ctaLink: '/download'
  },
  // ... more tiers
];

export const TESTIMONIALS = [
  {
    quote: 'Went from 2 recruits/week to 15. This is insane.',
    author: 'Thoridan',
    guild: 'Eternal Flames',
    server: 'Dalaran-EU',
    class: 'paladin',
    avatar: '/avatars/paladin.png'
  },
  // ... more testimonials
];

export const STATS = [
  { icon: '📊', value: 12847, label: 'Players Recruited', suffix: '+' },
  { icon: '⚡', value: 3492, label: 'Invites Sent', suffix: '+' },
  { icon: '👥', value: 847, label: 'Active Guilds', suffix: '+' },
  { icon: '⭐', value: 4.9, label: 'Average Rating', suffix: '/5' }
];
```

---

## 🎯 Conversion Optimization Checklist

### Above the Fold (Hero)
- [ ] Clear value proposition in <3 seconds
- [ ] Emotional headline (not feature list)
- [ ] Prominent CTA buttons (Download + Patreon)
- [ ] Social proof counter visible
- [ ] Visual proof (screenshot/demo)
- [ ] No jargon - talk benefits, not features

### Features Section
- [ ] Max 6-8 features highlighted (not overwhelming)
- [ ] Icons for visual scanning
- [ ] Specific stats/numbers (not vague claims)
- [ ] Tier badges show what's locked/unlocked
- [ ] Hover tooltips provide more detail

### Pricing Section
- [ ] 3-tier layout (optimal conversion)
- [ ] Pro tier physically centered
- [ ] "Most Popular" badge on recommended tier
- [ ] Price anchoring (show highest first in description)
- [ ] Scarcity element (limited slots/time)
- [ ] Money-back guarantee visible
- [ ] Feature comparison clear
- [ ] CTA buttons distinct per tier

### Social Proof
- [ ] Specific numbers (847 not "hundreds")
- [ ] Real testimonials with avatars/names
- [ ] Guild logos/server names
- [ ] Stats counters animated on scroll
- [ ] Trust badges (servers, Patreon verified)

### Objection Handling
- [ ] FAQ answers common objections
- [ ] "Why pay?" addressed directly
- [ ] Risk removal (money-back, cancel anytime)
- [ ] ToS compliance mentioned
- [ ] Free tier clearly highlighted

### Final CTA
- [ ] Urgency element (countdown/scarcity)
- [ ] Two clear options (Download or Pro)
- [ ] Trust signals repeated
- [ ] Visual hierarchy guides to Pro tier

### Technical
- [ ] Mobile responsive (50%+ traffic)
- [ ] Load time <2s (critical for conversion)
- [ ] Smooth animations (60fps)
- [ ] Accessibility (keyboard nav, ARIA)
- [ ] Analytics tracking (conversion funnels)

---

## 📊 Analytics & A/B Testing Strategy

### Events to Track

```typescript
// lib/analytics.ts
export const trackEvent = (event: string, data?: any) => {
  // Vercel Analytics
  if (typeof window !== 'undefined' && window.va) {
    window.va('track', event, data);
  }

  // Also log for debugging
  console.log('[Analytics]', event, data);
};

// Key conversion events
export const events = {
  // Engagement
  VIEW_PRICING: 'view_pricing',
  VIEW_FEATURES: 'view_features',
  SCROLL_50: 'scroll_50_percent',
  SCROLL_75: 'scroll_75_percent',

  // Conversions
  CLICK_DOWNLOAD: 'click_download',
  CLICK_PATREON: 'click_patreon',
  CLICK_TIER: (tier: string) => `click_tier_${tier}`,

  // Micro-conversions
  HOVER_PRICING_CARD: 'hover_pricing_card',
  OPEN_FAQ: 'open_faq',
  PLAY_VIDEO: 'play_demo_video'
};
```

### A/B Test Candidates

1. **Hero CTA Copy**
   - A: "Download Free"
   - B: "Start Recruiting Smarter"
   - C: "Get CelestialRecruiter"

2. **Pricing Badge**
   - A: "⭐ Most Popular"
   - B: "🔥 Best Value"
   - C: "👥 847 Officers Choice"

3. **Tier Names**
   - A: Free / Recruiter / Pro
   - B: Scout / Officer / Commander
   - C: Common / Rare / Epic

4. **Social Proof Position**
   - A: Above pricing
   - B: Below pricing
   - C: Both

---

## 🚀 Deployment & SEO

### Vercel Deployment

```bash
# Install Vercel CLI
npm i -g vercel

# Initialize
cd celestialrecruiter-web
vercel

# Follow prompts
# Deploy to production
vercel --prod
```

### SEO Optimization

#### `app/layout.tsx`
```typescript
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'CelestialRecruiter - Legendary WoW Guild Recruitment Addon',
  description: 'Automate guild recruitment in World of Warcraft. Auto-scan, AI recruiting, Discord integration, and advanced analytics. Used by 847+ guilds.',
  keywords: [
    'World of Warcraft',
    'WoW addon',
    'guild recruitment',
    'auto recruiter',
    'wow scanner',
    'discord integration',
    'guild management'
  ],
  authors: [{ name: 'Plume', url: 'https://discord.gg/3HwyEBaAQB' }],
  openGraph: {
    title: 'CelestialRecruiter - Automate WoW Guild Recruitment',
    description: 'Stop wasting time on /who spam. Recruit smarter with automation.',
    images: ['/og-image.png'],
    type: 'website'
  },
  twitter: {
    card: 'summary_large_image',
    title: 'CelestialRecruiter - WoW Recruitment Addon',
    description: 'Legendary-tier guild recruitment automation',
    images: ['/og-image.png']
  }
};
```

#### `public/robots.txt`
```
User-agent: *
Allow: /

Sitemap: https://celestialrecruiter.com/sitemap.xml
```

#### `app/sitemap.ts`
```typescript
import { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    {
      url: 'https://celestialrecruiter.com',
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 1
    },
    {
      url: 'https://celestialrecruiter.com/features',
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.8
    },
    {
      url: 'https://celestialrecruiter.com/pricing',
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.9
    }
  ];
}
```

---

## 🎁 Easter Eggs & Delight Moments

### Konami Code Secret
```typescript
// lib/useKonamiCode.ts
import { useEffect, useState } from 'react';

const KONAMI_CODE = [
  'ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown',
  'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight',
  'b', 'a'
];

export function useKonamiCode(callback: () => void) {
  const [keys, setKeys] = useState<string[]>([]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      setKeys(prev => [...prev.slice(-9), e.key]);
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  useEffect(() => {
    if (keys.join(',') === KONAMI_CODE.join(',')) {
      callback();
      setKeys([]);
    }
  }, [keys, callback]);
}

// Usage in layout:
function RootLayout() {
  useKonamiCode(() => {
    // Unlock "Lich King" theme (ice blue)
    document.body.classList.add('theme-lich-king');
    showAchievement({
      title: 'Secret Unlocked!',
      description: 'Lich King theme activated',
      icon: '❄️'
    });
  });
}
```

### Click Counter Easter Egg
```typescript
// Click logo 10 times → spawn particle explosion
let clickCount = 0;

function Logo() {
  const handleClick = () => {
    clickCount++;
    if (clickCount === 10) {
      triggerParticleExplosion();
      playSound('epic-drop');
      clickCount = 0;
    }
  };

  return <img src="/logo.png" onClick={handleClick} />;
}
```

### Time-Based Greeting
```typescript
// Show different hero text based on time
function getTimeBasedGreeting() {
  const hour = new Date().getHours();

  if (hour >= 2 && hour < 6) {
    return "Still recruiting at this hour? Hardcore. 🌙";
  } else if (hour >= 18 && hour < 23) {
    return "Prime time recruiting hours! ⚡";
  } else {
    return "Ready to Recruit Like a Legend?";
  }
}
```

---

## 📋 Final Implementation Checklist

### Phase 1: Setup
- [ ] Initialize Next.js 14+ project with TypeScript
- [ ] Install dependencies (framer-motion, sass, etc.)
- [ ] Set up folder structure
- [ ] Create design system (colors, typography, components)
- [ ] Build reusable UI components (buttons, cards, tooltips)

### Phase 2: Content
- [ ] Parse README.md for feature descriptions
- [ ] Create feature list with tiers
- [ ] Write pricing tier descriptions
- [ ] Gather testimonials (real or placeholder)
- [ ] Create FAQ content
- [ ] Write all micro-copy

### Phase 3: Sections
- [ ] Build Hero section with starfield
- [ ] Build Features showcase with animations
- [ ] Build Pricing section with 3-tier layout
- [ ] Build Social Proof with stats
- [ ] Build Screenshot Gallery
- [ ] Build FAQ accordion
- [ ] Build Final CTA

### Phase 4: Effects
- [ ] Implement starfield canvas
- [ ] Add particle system
- [ ] Create achievement toast system
- [ ] Add scroll-triggered animations
- [ ] Implement hover effects
- [ ] Add parallax layers
- [ ] Optional: Add UI sounds

### Phase 5: Optimization
- [ ] Mobile responsive testing
- [ ] Performance audit (Lighthouse)
- [ ] SEO metadata
- [ ] Analytics integration
- [ ] A/B test setup
- [ ] Accessibility audit

### Phase 6: Deploy
- [ ] Deploy to Vercel
- [ ] Set up custom domain (optional)
- [ ] Test all conversion funnels
- [ ] Monitor analytics
- [ ] Iterate based on data

---

## 🎓 Psychological Principles Summary

**Apply throughout:**

1. **Scarcity**: "Only 47 early supporter slots left"
2. **Social Proof**: "847+ officers use this"
3. **Authority**: "Trusted by Mythic guilds"
4. **Reciprocity**: Free tier creates obligation
5. **Anchoring**: Show expensive tier first
6. **Loss Aversion**: Frame as time saved, not money spent
7. **FOMO**: "Limited early pricing"
8. **Bandwagon**: "Join hundreds of officers"
9. **Specificity**: 847 not "hundreds"
10. **Decoy Effect**: Guild Master makes Pro seem affordable

---

## 🔗 Reference Links

### Research Sources
- [WeakAuras on CurseForge](https://www.curseforge.com/wow/addons/weakauras-2)
- [Wago.io](https://wago.io/)
- [FasterCapital - Conversion Psychology](https://fastercapital.com/content/The-Psychology-of-Conversion-Premium--Persuasive-Techniques.html)
- [AWA Digital - CRO Principles](https://www.awa-digital.com/blog/psychological-principles-in-cro/)
- [Tailored Edge - Scarcity & Social Proof](https://tailorededgemarketing.com/conversion-psychology-how-to-use-scarcity-urgency-and-social-proof-effectively/)
- [Subframe - Gaming Website Examples](https://www.subframe.com/tips/gaming-website-design-examples)
- [Dark Mode Design](https://www.darkmodedesign.com/)
- [InfluenceFlow - SaaS Pricing](https://influenceflow.io/resources/saas-pricing-page-best-practices-complete-guide-for-2026/)
- [Adapty - Tiered Pricing](https://adapty.io/blog/tiered-pricing/)
- [IndieKlem - WoW UI Design](https://indieklem.com/12-what-you-can-learn-from-the-ui-design-of-world-of-warcraft/)

---

## 🎯 Success Metrics

**Track these KPIs:**

- **Primary**: Patreon sign-ups (conversions)
- **Secondary**: Download clicks
- **Engagement**: Time on site, scroll depth, sections viewed
- **Micro-conversions**: Pricing card hovers, FAQ opens, video plays

**Target Benchmarks:**
- Landing page conversion: 2-5% to Patreon (industry avg: 2-3%)
- Download conversion: 10-20%
- Bounce rate: <50%
- Avg time on site: >2 minutes

---

**GO BUILD SOMETHING LEGENDARY.** ⭐

This landing page will convert visitors into supporters through immersive WoW aesthetics, psychologically optimized design, and genuine value communication. Trust the research, implement with care, and iterate based on data.

**May your Patreon be full and your recruits be plenty.** 🔥
