import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Changelog - CelestialRecruiter',
  description:
    'Historique des versions et mises a jour de CelestialRecruiter, addon de recrutement de guilde pour World of Warcraft.',
};

type ChangeEntry = {
  type: 'feat' | 'fix' | 'chore' | 'perf';
  text: string;
};

type Release = {
  version: string;
  date: string;
  entries: ChangeEntry[];
};

const TYPE_STYLES: Record<string, { label: string; bg: string; color: string }> = {
  feat: { label: 'NEW', bg: 'rgba(74, 222, 128, 0.12)', color: '#4ade80' },
  fix: { label: 'FIX', bg: 'rgba(248, 113, 113, 0.12)', color: '#f87171' },
  chore: { label: 'CHORE', bg: 'rgba(139, 115, 64, 0.12)', color: '#8B7340' },
  perf: { label: 'PERF', bg: 'rgba(96, 165, 250, 0.12)', color: '#60a5fa' },
};

const RELEASES: Release[] = [
  {
    version: '3.6.0',
    date: '2026-02-17',
    entries: [
      { type: 'feat', text: 'Activation de licence via le site web (page /activate)' },
      { type: 'feat', text: 'Clefs de licence liees au personnage (anti-partage)' },
      { type: 'feat', text: 'Token HMAC-SHA256 pour activation securisee' },
      { type: 'feat', text: 'Pages legales (Privacy, Terms) et Changelog' },
      { type: 'feat', text: 'Pages 404/500 avec design medieval' },
      { type: 'feat', text: 'Reprise du Mode Nuit apres deconnexion' },
      { type: 'fix', text: 'AIConversation: correction du nettoyage des reponses en attente' },
      { type: 'fix', text: 'Discord.lua: clarification du stub webhook (envoi via Python companion)' },
      { type: 'fix', text: 'Rate limiter: correction du compteur apres epuisement des retries' },
      { type: 'chore', text: 'Validation des noms de personnage (regex Name-Realm)' },
      { type: 'chore', text: 'Validation de la config au demarrage des outils Python' },
      { type: 'chore', text: 'Documentation du status enum des contacts dans DB.lua' },
      { type: 'chore', text: 'Sitemap complet et liens footer mis a jour' },
    ],
  },
  {
    version: '3.5.0',
    date: '2026-02-10',
    entries: [
      { type: 'feat', text: 'Messages AI generes pour tous les contacts en file' },
      { type: 'fix', text: 'AI data ecrite dans un fichier addon regulier (pas SavedVariables)' },
      { type: 'feat', text: 'Bouton "Msg AI" dans l\'interface' },
    ],
  },
  {
    version: '3.4.0',
    date: '2026-01-28',
    entries: [
      { type: 'feat', text: 'Mode Nuit (Sleep Recruiter) avec integration AI' },
      { type: 'feat', text: 'Discord webhook companion (Python) avec Raider.io' },
      { type: 'feat', text: 'Dashboard web interactif (Next.js)' },
      { type: 'feat', text: 'Systeme de licence Patreon avec 3 tiers' },
      { type: 'feat', text: 'Notifications toast avec animations' },
      { type: 'feat', text: 'Systeme de particules pour evenements' },
      { type: 'feat', text: 'A/B testing des templates' },
      { type: 'feat', text: 'Leaderboard et achievements' },
      { type: 'perf', text: 'Extraction ciblee de la queue Discord (evite le parsing complet)' },
    ],
  },
  {
    version: '3.3.0',
    date: '2025-12-15',
    entries: [
      { type: 'feat', text: 'Campagnes de recrutement programmees' },
      { type: 'feat', text: 'Operations en masse (tags, statuts)' },
      { type: 'feat', text: 'Suggestions intelligentes' },
      { type: 'feat', text: 'Score de reputation des contacts (0-100)' },
      { type: 'fix', text: 'Migration correcte des contacts entre profils AceDB' },
    ],
  },
  {
    version: '3.2.0',
    date: '2025-11-01',
    entries: [
      { type: 'feat', text: 'Auto-recruteur (whisper + invite automatiques)' },
      { type: 'feat', text: 'Filtres avances avec presets sauvegardables' },
      { type: 'feat', text: 'Import/Export des donnees' },
      { type: 'feat', text: '6 themes visuels' },
    ],
  },
  {
    version: '3.1.0',
    date: '2025-09-20',
    entries: [
      { type: 'feat', text: 'Statistiques avancees avec graphiques' },
      { type: 'feat', text: 'Templates personnalises avec variables' },
      { type: 'feat', text: 'Systeme de tags pour organiser les contacts' },
      { type: 'feat', text: 'Historique des messages par contact' },
    ],
  },
  {
    version: '3.0.0',
    date: '2025-07-15',
    entries: [
      { type: 'feat', text: 'Refonte complete de l\'interface' },
      { type: 'feat', text: 'Scanner /who avec file d\'attente intelligente' },
      { type: 'feat', text: 'Anti-spam avec cooldowns configurables' },
      { type: 'feat', text: 'Bouton minimap' },
    ],
  },
];

export default function ChangelogPage() {
  return (
    <div
      style={{
        minHeight: '100vh',
        background: '#0d0c0a',
        paddingTop: 56,
      }}
    >
      <nav className="site-nav">
        <a href="/" className="nav-brand">
          Celestial Recruiter
        </a>
        <div className="nav-links">
          <a href="/" className="nav-link">
            Accueil
          </a>
        </div>
      </nav>

      <main
        style={{
          maxWidth: 700,
          margin: '0 auto',
          padding: '3rem 1.5rem 4rem',
        }}
      >
        <div style={{ textAlign: 'center', marginBottom: '3rem' }}>
          <span
            style={{
              fontFamily: "'Montserrat', sans-serif",
              fontSize: '0.72rem',
              fontWeight: 600,
              letterSpacing: '0.15em',
              textTransform: 'uppercase',
              color: '#8B7340',
              display: 'block',
              marginBottom: '0.75rem',
            }}
          >
            Historique
          </span>
          <h1
            style={{
              fontFamily: "'Cinzel', serif",
              fontSize: 'clamp(1.5rem, 3vw, 2.25rem)',
              fontWeight: 700,
              color: '#C9AA71',
              letterSpacing: '0.03em',
              marginBottom: '0.5rem',
            }}
          >
            Changelog
          </h1>
          <p
            style={{
              color: '#a89b80',
              fontSize: '0.95rem',
              fontFamily: "'Montserrat', sans-serif",
            }}
          >
            Toutes les mises &agrave; jour de CelestialRecruiter
          </p>
        </div>

        {/* Timeline */}
        <div style={{ position: 'relative' }}>
          {/* Vertical line */}
          <div
            style={{
              position: 'absolute',
              left: 16,
              top: 0,
              bottom: 0,
              width: 1,
              background: '#352c20',
            }}
          />

          {RELEASES.map((release, i) => (
            <div
              key={release.version}
              style={{
                position: 'relative',
                paddingLeft: 44,
                marginBottom: i < RELEASES.length - 1 ? '2.5rem' : 0,
              }}
            >
              {/* Dot */}
              <div
                style={{
                  position: 'absolute',
                  left: 10,
                  top: 6,
                  width: 13,
                  height: 13,
                  borderRadius: '50%',
                  background: i === 0 ? '#C9AA71' : '#352c20',
                  border: `2px solid ${i === 0 ? '#C9AA71' : '#6b5635'}`,
                }}
              />

              {/* Version badge */}
              <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.75rem', marginBottom: '0.75rem' }}>
                <span
                  style={{
                    fontFamily: "'Fira Code', monospace",
                    fontSize: '1.05rem',
                    fontWeight: 600,
                    color: i === 0 ? '#C9AA71' : '#a89b80',
                  }}
                >
                  v{release.version}
                </span>
                <span
                  style={{
                    fontFamily: "'Montserrat', sans-serif",
                    fontSize: '0.75rem',
                    color: '#6b5f4d',
                  }}
                >
                  {release.date}
                </span>
              </div>

              {/* Stone panel with entries */}
              <div
                style={{
                  background: '#1a1814',
                  border: '1px solid #352c20',
                  borderRadius: 6,
                  padding: '1rem 1.25rem',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '0.5rem',
                }}
              >
                {release.entries.map((entry, j) => {
                  const style = TYPE_STYLES[entry.type];
                  return (
                    <div
                      key={j}
                      style={{
                        display: 'flex',
                        alignItems: 'flex-start',
                        gap: '0.6rem',
                        fontSize: '0.85rem',
                        lineHeight: 1.5,
                      }}
                    >
                      <span
                        style={{
                          fontFamily: "'Fira Code', monospace",
                          fontSize: '0.65rem',
                          fontWeight: 600,
                          color: style.color,
                          background: style.bg,
                          padding: '1px 6px',
                          borderRadius: 3,
                          flexShrink: 0,
                          marginTop: 2,
                        }}
                      >
                        {style.label}
                      </span>
                      <span style={{ color: '#d4c5a9', fontFamily: "'Montserrat', sans-serif" }}>
                        {entry.text}
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>

        {/* Footer */}
        <div
          style={{
            textAlign: 'center',
            marginTop: '3rem',
            fontSize: '0.78rem',
            color: '#6b5f4d',
          }}
        >
          <a
            href="/"
            style={{ color: '#C9AA71', textDecoration: 'none', borderBottom: '1px solid rgba(201,170,113,0.3)' }}
          >
            Retour &agrave; l&apos;accueil
          </a>
        </div>
      </main>
    </div>
  );
}
