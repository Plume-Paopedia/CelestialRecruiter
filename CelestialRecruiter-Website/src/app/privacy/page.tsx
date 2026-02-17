import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Politique de Confidentialit\u00e9 - CelestialRecruiter',
  description:
    'Politique de confidentialit\u00e9 de CelestialRecruiter, addon de recrutement de guilde pour World of Warcraft.',
};

export default function PrivacyPage() {
  return (
    <div
      style={{
        minHeight: '100vh',
        background: '#0d0c0a',
        paddingTop: 56,
      }}
    >
      {/* ── Nav ── */}
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

      {/* ── Content ── */}
      <main
        style={{
          maxWidth: 700,
          margin: '0 auto',
          padding: '3rem 1.5rem 4rem',
        }}
      >
        {/* Stone panel */}
        <div
          style={{
            background: '#1a1814',
            border: '1px solid #352c20',
            borderRadius: 8,
            padding: '2.5rem 2rem',
          }}
        >
          {/* Page title */}
          <h1
            style={{
              fontFamily: "'Cinzel', serif",
              fontSize: '1.75rem',
              fontWeight: 700,
              color: '#C9AA71',
              letterSpacing: '0.03em',
              textAlign: 'center',
              marginBottom: '0.5rem',
            }}
          >
            Politique de Confidentialit&eacute;
          </h1>
          <p
            style={{
              textAlign: 'center',
              fontFamily: "'Montserrat', sans-serif",
              fontSize: '0.8rem',
              color: '#6b5f4d',
              marginBottom: '2.5rem',
            }}
          >
            Derni&egrave;re mise &agrave; jour : F&eacute;vrier 2026
          </p>

          {/* ── Section 1 ── */}
          <Section number="1" title="Donn&eacute;es collect&eacute;es par l&rsquo;addon">
            <Paragraph>
              Toutes les donn&eacute;es de l&rsquo;addon (contacts, messages, statistiques) sont
              stock&eacute;es <strong style={{ color: '#C9AA71' }}>localement</strong> dans les
              SavedVariables de World of Warcraft sur votre ordinateur.
            </Paragraph>
            <Paragraph>
              Aucune donn&eacute;e de jeu n&rsquo;est envoy&eacute;e &agrave; des serveurs externes
              par l&rsquo;addon lui-m&ecirc;me.
            </Paragraph>
          </Section>

          {/* ── Section 2 ── */}
          <Section number="2" title="Int&eacute;gration Discord (optionnelle)">
            <Paragraph>
              Si vous configurez un webhook Discord, des notifications sont envoy&eacute;es
              &agrave; <strong style={{ color: '#C9AA71' }}>votre</strong> serveur Discord via le
              script companion (<code style={codeStyle}>Tools/discord_webhook.py</code>).
            </Paragraph>
            <Paragraph>
              Ces notifications contiennent uniquement les &eacute;v&eacute;nements que vous
              choisissez (recrues, statistiques).
            </Paragraph>
          </Section>

          {/* ── Section 3 ── */}
          <Section number="3" title="Syst&egrave;me de licence">
            <Paragraph>
              Pour activer une licence premium, nous collectons :
            </Paragraph>
            <ul style={listStyle}>
              <li style={listItemStyle}>
                Votre nom de personnage World of Warcraft
              </li>
              <li style={listItemStyle}>
                Votre adresse e-mail Patreon
              </li>
            </ul>
            <Paragraph>
              L&rsquo;e-mail est utilis&eacute; uniquement pour l&rsquo;envoi de votre
              cl&eacute; de licence. Aucun paiement n&rsquo;est trait&eacute; par nous&nbsp;&mdash;
              tout passe par Patreon.
            </Paragraph>
          </Section>

          {/* ── Section 4 ── */}
          <Section number="4" title="Cookies et tracking">
            <Paragraph>
              Ce site <strong style={{ color: '#C9AA71' }}>n&rsquo;utilise pas</strong> de cookies
              de suivi.
            </Paragraph>
            <Paragraph>
              Pas de Google Analytics, pas de trackers tiers.
            </Paragraph>
            <Paragraph>
              Le site est d&eacute;ploy&eacute; sur Vercel et est soumis &agrave; leur politique
              d&rsquo;infrastructure.
            </Paragraph>
          </Section>

          {/* ── Section 5 ── */}
          <Section number="5" title="Contact" last>
            <Paragraph>
              Pour toute question relative &agrave; vos donn&eacute;es, contactez-nous sur
              Discord&nbsp;:
            </Paragraph>
            <p style={{ margin: '0.75rem 0 0' }}>
              <a
                href="https://discord.gg/3HwyEBaAQB"
                target="_blank"
                rel="noopener noreferrer"
                style={linkStyle}
              >
                discord.gg/3HwyEBaAQB
              </a>
            </p>
          </Section>
        </div>

        {/* ── Footer links ── */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'center',
            gap: '2rem',
            marginTop: '2rem',
            flexWrap: 'wrap',
          }}
        >
          <a href="/" style={footerLinkStyle}>
            &larr; Accueil
          </a>
          <a href="/terms" style={footerLinkStyle}>
            Conditions d&rsquo;Utilisation
          </a>
          <a
            href="https://discord.gg/3HwyEBaAQB"
            target="_blank"
            rel="noopener noreferrer"
            style={footerLinkStyle}
          >
            Support Discord
          </a>
        </div>
      </main>
    </div>
  );
}

/* ── Reusable sub-components ── */

function Section({
  number,
  title,
  children,
  last = false,
}: {
  number: string;
  title: string;
  children: React.ReactNode;
  last?: boolean;
}) {
  return (
    <section
      style={{
        marginBottom: last ? 0 : '2rem',
        paddingBottom: last ? 0 : '2rem',
        borderBottom: last ? 'none' : '1px solid #352c20',
      }}
    >
      <h2
        style={{
          fontFamily: "'Cinzel', serif",
          fontSize: '1.1rem',
          fontWeight: 600,
          color: '#C9AA71',
          letterSpacing: '0.02em',
          marginBottom: '0.75rem',
        }}
      >
        {number}. {title}
      </h2>
      {children}
    </section>
  );
}

function Paragraph({ children }: { children: React.ReactNode }) {
  return (
    <p
      style={{
        fontFamily: "'Montserrat', sans-serif",
        fontSize: '0.9rem',
        lineHeight: 1.75,
        color: '#a89b80',
        marginBottom: '0.5rem',
      }}
    >
      {children}
    </p>
  );
}

/* ── Shared inline-style objects ── */

const codeStyle: React.CSSProperties = {
  fontFamily: "'Fira Code', monospace",
  fontSize: '0.82rem',
  background: '#12110f',
  padding: '0.15em 0.45em',
  borderRadius: 4,
  color: '#C9AA71',
};

const linkStyle: React.CSSProperties = {
  color: '#C9AA71',
  textDecoration: 'none',
  fontFamily: "'Montserrat', sans-serif",
  fontSize: '0.9rem',
  fontWeight: 600,
  borderBottom: '1px solid #352c20',
  paddingBottom: 2,
  transition: 'border-color 0.2s ease',
};

const footerLinkStyle: React.CSSProperties = {
  color: '#6b5f4d',
  textDecoration: 'none',
  fontFamily: "'Montserrat', sans-serif",
  fontSize: '0.82rem',
  fontWeight: 500,
  transition: 'color 0.2s ease',
};

const listStyle: React.CSSProperties = {
  listStyle: 'none',
  padding: 0,
  margin: '0.5rem 0 0.75rem',
};

const listItemStyle: React.CSSProperties = {
  fontFamily: "'Montserrat', sans-serif",
  fontSize: '0.9rem',
  lineHeight: 1.75,
  color: '#a89b80',
  paddingLeft: '1.25rem',
  position: 'relative',
};
