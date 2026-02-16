// ============================================
// Features
// ============================================
export const FEATURES = [
  {
    id: 'auto-scan',
    title: 'Auto-Scan',
    icon: '🎯',
    tier: 'epic' as const,
    description: 'Background scanner discovers players while you raid. Never manually /who again.',
    stats: 'Hands-free scanning',
    unlock: 'Recruteur Tier',
  },
  {
    id: 'auto-recruiter',
    title: 'AI Auto-Recruiter',
    icon: '🤖',
    tier: 'legendary' as const,
    description: 'Set rules, walk away. Recruits while you sleep with smart prioritization by class and level.',
    stats: 'Fully automated',
    unlock: 'Pro Tier',
  },
  {
    id: 'analytics',
    title: 'Advanced Analytics',
    icon: '📊',
    tier: 'epic' as const,
    description: 'Hourly analytics, conversion funnels, template performance tracking. Recruit smarter, not harder.',
    stats: 'Data-driven recruiting',
    unlock: 'Recruteur Tier',
  },
  {
    id: 'discord',
    title: 'Discord Integration',
    icon: '💬',
    tier: 'legendary' as const,
    description: 'Real-time webhooks send alerts to Discord when players whisper or join. Setup in 5 min.',
    stats: 'Instant notifications',
    unlock: 'Pro Tier',
  },
  {
    id: 'templates',
    title: 'Smart Templates',
    icon: '📝',
    tier: 'rare' as const,
    description: 'Dynamic templates with {name}, {class}, {level}, {guild}, {discord} and more. Personalize every message.',
    stats: 'Personalized outreach',
    unlock: 'Recruteur Tier',
  },
  {
    id: 'campaigns',
    title: 'Recruitment Campaigns',
    icon: '⚡',
    tier: 'legendary' as const,
    description: 'Schedule automated campaigns targeting specific classes, levels, and time windows.',
    stats: 'Set it and forget it',
    unlock: 'Pro Tier',
  },
];

// ============================================
// Hero Feature Pills
// ============================================
export const HERO_PILLS = [
  { label: 'Auto-Scanner' },
  { label: 'Analytics' },
  { label: 'AI Recruiting' },
  { label: 'Discord Alerts' },
];

// ============================================
// Pricing Tiers
// ============================================
export const PRICING_TIERS = [
  {
    id: 'free',
    name: 'Free',
    price: 0,
    color: 'common' as const,
    features: [
      'Manual Scanner',
      'Contact Queue',
      '3 Built-in Templates',
      'Basic Filters',
      '2 Themes',
    ],
    limitations: [
      '✗ No Auto-Scan',
      '✗ No Auto-Recruiter',
      '✗ No Analytics',
      '✗ No Discord',
    ],
    cta: 'Start Free',
    ctaStyle: 'btn-common',
    ctaLink: 'https://www.curseforge.com/wow/addons/celestialrecruiter',
  },
  {
    id: 'recruteur',
    name: 'Recruteur',
    price: 3,
    color: 'rare' as const,
    badge: 'MOST POPULAR',
    features: [
      '✓ Auto-Scan Enabled',
      '✓ Advanced Analytics',
      '✓ 3 Custom Templates',
      '✓ Advanced Filters',
      '✓ All 6 Themes',
      '✓ 500 Contacts / 100 Queue',
      '✓ Discord (5 events)',
      '✓ All Achievements',
      '✓ Import/Export',
    ],
    savings: 'Automate your recruitment',
    cta: 'Get Recruteur',
    ctaStyle: 'btn-rare',
    ctaLink: 'https://www.patreon.com/cw/Plume_',
    popular: true,
  },
  {
    id: 'pro',
    name: 'Pro',
    price: 7,
    color: 'epic' as const,
    badge: 'BEST VALUE',
    features: [
      'Everything in Recruteur +',
      '✓ Auto-Recruiter (AI)',
      '✓ Full Discord (30+ events)',
      '✓ A/B Testing',
      '✓ Campaigns (3 active)',
      '✓ Bulk Whisper/Invite',
      '✓ Unlimited Everything',
      '✓ Custom Theme Creator',
      '✓ Priority Support',
    ],
    savings: 'Full automation suite',
    value: 'Everything included for serious recruiters',
    cta: 'Get Pro',
    ctaStyle: 'btn-epic',
    ctaLink: 'https://www.patreon.com/cw/Plume_',
    recommended: true,
  },
];

// ============================================
// Testimonials
// ============================================
export const TESTIMONIALS = [
  {
    quote: 'Auto-Scan runs in the background while you raid. No more manually typing /who every 5 minutes.',
    author: 'Auto-Scanner',
    guild: 'Background scanning',
    server: 'All servers',
    wowClass: 'paladin',
  },
  {
    quote: 'Track conversion funnels, hourly activity, and template performance. See what works and double down.',
    author: 'Analytics',
    guild: 'Data-driven recruiting',
    server: 'All servers',
    wowClass: 'rogue',
  },
  {
    quote: 'Set your rules once: target classes, level ranges, time windows. The auto-recruiter handles the rest.',
    author: 'Auto-Recruiter',
    guild: 'Hands-free recruiting',
    server: 'All servers',
    wowClass: 'priest',
  },
  {
    quote: 'Get notified on Discord when someone whispers, joins, or leaves. 30+ event types with color-coded embeds.',
    author: 'Discord Webhooks',
    guild: 'Real-time alerts',
    server: 'All servers',
    wowClass: 'warrior',
  },
];

// ============================================
// Stats
// ============================================
export const STATS = [
  { icon: '📊', value: 42, label: 'Features Built', suffix: '+' },
  { icon: '⚡', value: 30, label: 'Discord Event Types', suffix: '+' },
  { icon: '👥', value: 13, label: 'Achievements', suffix: '' },
  { icon: '⭐', value: 6, label: 'Theme Presets', suffix: '' },
];

// ============================================
// FAQ
// ============================================
export const FAQS = [
  {
    q: 'Why should I pay for an addon?',
    a: 'The free tier is fully functional! Paid tiers support continued development and give you access to automation features like Auto-Scan, Auto-Recruiter, and Discord integration.',
  },
  {
    q: 'Can I try Pro before committing?',
    a: 'Absolutely! Start with Free or Recruteur tier. Upgrade anytime. 30-day money-back guarantee on all tiers.',
  },
  {
    q: 'Is this against WoW ToS?',
    a: '100% compliant. We use only official WoW APIs. No botting, no automation beyond what Blizzard allows. The addon simply makes your existing recruitment workflow more efficient.',
  },
  {
    q: 'How does Discord integration work?',
    a: 'Real-time webhooks send notifications to your Discord server when players whisper, join, or opt-in. Paste your webhook URL in the addon settings and toggle the events you want.',
  },
  {
    q: 'What happens if I cancel my subscription?',
    a: 'You keep the free tier features forever. Your data, templates, and history are preserved. You can re-subscribe anytime to unlock premium features again.',
  },
  {
    q: 'Does it work on all servers and regions?',
    a: 'Yes! CelestialRecruiter works on all retail WoW servers across EU and US regions.',
  },
];

// ============================================
// WoW Class Colors (for testimonial styling)
// ============================================
export const CLASS_COLORS: Record<string, string> = {
  warrior: '#C79C6E',
  paladin: '#F58CBA',
  hunter: '#ABD473',
  rogue: '#FFF569',
  priest: '#FFFFFF',
  shaman: '#0070DE',
  mage: '#69CCF0',
  warlock: '#9482C9',
  monk: '#00FF96',
  druid: '#FF7D0A',
  'demon-hunter': '#A330C9',
  'death-knight': '#C41F3B',
  evoker: '#33937F',
};

// ============================================
// External Links
// ============================================
export const LINKS = {
  patreon: 'https://www.patreon.com/cw/Plume_',
  discord: 'https://discord.gg/3HwyEBaAQB',
  curseforge: 'https://www.curseforge.com/wow/addons/celestialrecruiter',
  github: 'https://github.com/Plume-Paopedia/CelestialRecruiter',
};

// ============================================
// Dashboard Modules
// ============================================
export const DASHBOARD_MODULES = [
  { id: 'overview', label: 'Overview', icon: '\u2302', minTier: 'free' as const },
  { id: 'scanner', label: 'Scanner', icon: '\u2295', minTier: 'free' as const },
  { id: 'queue', label: 'Queue', icon: '\u2630', minTier: 'free' as const },
  { id: 'templates', label: 'Templates', icon: '\u2637', minTier: 'free' as const },
  { id: 'blacklist', label: 'Blacklist', icon: '\u26D4', minTier: 'recruteur' as const },
  { id: 'analytics', label: 'Analytics', icon: '\u2584', minTier: 'recruteur' as const },
  { id: 'campaigns', label: 'Campaigns', icon: '\u26A1', minTier: 'pro' as const },
  { id: 'discord', label: 'Discord', icon: '\u2709', minTier: 'pro' as const },
  { id: 'settings', label: 'Settings', icon: '\u2699', minTier: 'free' as const },
];

// ============================================
// Tier Levels (for numeric comparison)
// ============================================
export const TIER_LEVELS: Record<string, number> = {
  free: 0,
  recruteur: 1,
  pro: 2,
  lifetime: 2,
};

// ============================================
// Mock Scanner Data
// ============================================
export const MOCK_SCANNER_DATA = [
  { name: 'Kael\u00E9thas', className: 'Mage', level: 80, zone: 'Dornogal', guild: 'Les Immortels', status: 'online' as const },
  { name: 'Lunombre', className: 'Rogue', level: 78, zone: 'Isle de Dorn', guild: '', status: 'online' as const },
  { name: 'Thundara', className: 'Shaman', level: 80, zone: 'Cit\u00E9 des Fils', guild: 'Ordre du Phoenix', status: 'idle' as const },
  { name: 'Valorien', className: 'Paladin', level: 76, zone: 'Hallowfall', guild: '', status: 'online' as const },
  { name: 'Zephyrine', className: 'Evoker', level: 80, zone: 'Azj-Kahet', guild: 'Lames Noires', status: 'online' as const },
  { name: 'Grommash', className: 'Warrior', level: 74, zone: 'Ringing Deeps', guild: '', status: 'idle' as const },
  { name: 'Sylvanael', className: 'Druid', level: 80, zone: 'Dornogal', guild: 'Gardiens de Cenarius', status: 'online' as const },
  { name: 'Morthys', className: 'Death Knight', level: 79, zone: 'Hallowfall', guild: '', status: 'online' as const },
];

// ============================================
// Mock Queue Data
// ============================================
export const MOCK_QUEUE_DATA = [
  { name: 'Lunombre', className: 'Rogue', level: 78, status: 'pending' as const, addedAt: '2m ago' },
  { name: 'Valorien', className: 'Paladin', level: 76, status: 'invited' as const, addedAt: '15m ago' },
  { name: 'Grommash', className: 'Warrior', level: 74, status: 'pending' as const, addedAt: '28m ago' },
  { name: 'Morthys', className: 'Death Knight', level: 79, status: 'invited' as const, addedAt: '1h ago' },
  { name: 'Aelindra', className: 'Priest', level: 80, status: 'accepted' as const, addedAt: '2h ago' },
  { name: 'Fenrys', className: 'Hunter', level: 77, status: 'declined' as const, addedAt: '3h ago' },
  { name: 'Brakkar', className: 'Monk', level: 75, status: 'accepted' as const, addedAt: '4h ago' },
  { name: 'Duskara', className: 'Warlock', level: 80, status: 'pending' as const, addedAt: '5h ago' },
];

// ============================================
// Mock Activity Feed
// ============================================
export const MOCK_ACTIVITY_DATA = [
  { icon: '\u2714', text: 'Aelindra (Priest 80) accepted guild invite', time: '2h ago' },
  { icon: '\u2709', text: 'Whisper sent to Valorien - Recrutement Tank', time: '15m ago' },
  { icon: '\u2295', text: 'Scanner found 12 new players in Dornogal', time: '8m ago' },
  { icon: '\u2716', text: 'Fenrys (Hunter 77) declined - already in a guild', time: '3h ago' },
  { icon: '\u26A1', text: 'Campaign "Healer Rush" sent 8 invites', time: '6h ago' },
  { icon: '\u2714', text: 'Brakkar (Monk 75) accepted guild invite', time: '4h ago' },
];

// ============================================
// Mock Campaigns Data
// ============================================
export const MOCK_CAMPAIGNS_DATA = [
  {
    name: 'Healer Rush',
    status: 'active' as const,
    template: 'Heal Recruit FR',
    targets: 'Priests, Shamans, Druids 75-80 on Hyjal-EU',
    sent: 47,
    responses: 18,
    conversion: '38%',
  },
  {
    name: 'Tank Search S2',
    status: 'paused' as const,
    template: 'Tank Recruit FR',
    targets: 'Warriors, Paladins, Death Knights 78-80 on Hyjal-EU',
    sent: 31,
    responses: 9,
    conversion: '29%',
  },
  {
    name: 'DPS Fill Mythic',
    status: 'completed' as const,
    template: 'DPS Mythic FR',
    targets: 'All DPS classes 80 on Hyjal-EU, Archimonde-EU',
    sent: 64,
    responses: 22,
    conversion: '34%',
  },
];

// ============================================
// Mock Discord Messages
// ============================================
export const MOCK_DISCORD_MESSAGES = [
  {
    author: 'CelestialRecruiter',
    text: 'Nouveau joueur d\u00E9tect\u00E9 : Valorien (Paladin 76) - sans guilde',
    embed: 'Zone: Hallowfall | Status: Online | Invit\u00E9 via template "Tank Recruit FR"',
    time: '15m ago',
  },
  {
    author: 'CelestialRecruiter',
    text: 'Aelindra (Priest 80) a accept\u00E9 l\'invitation de guilde !',
    embed: undefined,
    time: '2h ago',
  },
  {
    author: 'CelestialRecruiter',
    text: 'Campagne "Healer Rush" termin\u00E9e - 8 invitations envoy\u00E9es',
    embed: 'R\u00E9sultats : 3 accept\u00E9s, 2 en attente, 1 refus\u00E9, 2 hors-ligne',
    time: '6h ago',
  },
  {
    author: 'CelestialRecruiter',
    text: 'Whisper re\u00E7u de Morthys : "C\'est quoi votre roster pour le mythique ?"',
    embed: undefined,
    time: '1h ago',
  },
];

// ============================================
// Mock Analytics
// ============================================
export const MOCK_ANALYTICS = {
  weeklyData: [
    { day: 'Lun', recruits: 4 },
    { day: 'Mar', recruits: 7 },
    { day: 'Mer', recruits: 3 },
    { day: 'Jeu', recruits: 9 },
    { day: 'Ven', recruits: 12 },
    { day: 'Sam', recruits: 15 },
    { day: 'Dim', recruits: 11 },
  ],
  classDistribution: [
    { className: 'Warrior', count: 18, color: '#C79C6E' },
    { className: 'Paladin', count: 14, color: '#F58CBA' },
    { className: 'Priest', count: 21, color: '#FFFFFF' },
    { className: 'Mage', count: 16, color: '#69CCF0' },
    { className: 'Druid', count: 12, color: '#FF7D0A' },
  ],
  conversionFunnel: [
    { stage: 'Scann\u00E9s', count: 342 },
    { stage: 'Contact\u00E9s', count: 128 },
    { stage: 'R\u00E9ponses', count: 47 },
    { stage: 'Recrut\u00E9s', count: 31 },
  ],
};
