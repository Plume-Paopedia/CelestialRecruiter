import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: "Conditions d'Utilisation - CelestialRecruiter",
  description:
    "Conditions d'utilisation de CelestialRecruiter, addon de recrutement de guilde pour World of Warcraft.",
};

export default function TermsPage() {
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
            Conditions d&rsquo;Utilisation
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
          <Section number="1" title="Utilisation de l&rsquo;addon">
            <Paragraph>
              CelestialRecruiter est un addon pour World of Warcraft distribu&eacute; via
              CurseForge.
            </Paragraph>
            <Paragraph>
              L&rsquo;addon respecte les conditions d&rsquo;utilisation de Blizzard et
              l&rsquo;API officielle d&rsquo;addons de World of Warcraft.
            </Paragraph>
            <Paragraph>
              L&rsquo;utilisateur est responsable du respect des r&egrave;gles de comportement
              de Blizzard.
            </Paragraph>
          </Section>

          {/* ── Section 2 ── */}
          <Section number="2" title="Licence et tiers">
            <ul style={listStyle}>
              <li style={listItemStyle}>
                <strong style={emphasisStyle}>Version gratuite</strong>&nbsp;: fonctionnalit&eacute;s
                de base sans limitation de dur&eacute;e.
              </li>
              <li style={listItemStyle}>
                <strong style={emphasisStyle}>Versions premium</strong> (Recruteur, &Eacute;lite,
                L&eacute;gendaire)&nbsp;: accessibles via Patreon.
              </li>
              <li style={listItemStyle}>
                Les cl&eacute;s de licence sont li&eacute;es &agrave; un personnage
                sp&eacute;cifique et ne sont <strong style={emphasisStyle}>pas
                transf&eacute;rables</strong>.
              </li>
              <li style={listItemStyle}>
                Les licences mensuelles expirent si l&rsquo;abonnement Patreon est annul&eacute;.
              </li>
            </ul>
          </Section>

          {/* ── Section 3 ── */}
          <Section number="3" title="Limitations">
            <Paragraph>
              L&rsquo;addon ne garantit pas de r&eacute;sultats de recrutement.
            </Paragraph>
            <Paragraph>
              L&rsquo;addon ne contourne aucune protection ni restriction du jeu.
            </Paragraph>
            <Paragraph>
              Nous ne sommes pas responsables des sanctions appliqu&eacute;es par Blizzard.
            </Paragraph>
          </Section>

          {/* ── Section 4 ── */}
          <Section number="4" title="Propri&eacute;t&eacute; intellectuelle">
            <Paragraph>
              CelestialRecruiter est d&eacute;velopp&eacute; par{' '}
              <strong style={emphasisStyle}>Plume</strong>.
            </Paragraph>
            <Paragraph>
              World of Warcraft et Blizzard sont des marques d&eacute;pos&eacute;es de Blizzard
              Entertainment.
            </Paragraph>
            <Paragraph>
              Cet addon n&rsquo;est pas affili&eacute; &agrave; Blizzard Entertainment.
            </Paragraph>
          </Section>

          {/* ── Section 5 ── */}
          <Section number="5" title="Modifications" last>
            <Paragraph>
              Ces conditions peuvent &ecirc;tre modifi&eacute;es &agrave; tout moment.
            </Paragraph>
            <Paragraph>
              Les utilisateurs seront inform&eacute;s des changements majeurs via Discord&nbsp;:
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
          <a href="/privacy" style={footerLinkStyle}>
            Politique de Confidentialit&eacute;
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

const emphasisStyle: React.CSSProperties = {
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
  margin: '0.25rem 0 0',
};

const listItemStyle: React.CSSProperties = {
  fontFamily: "'Montserrat', sans-serif",
  fontSize: '0.9rem',
  lineHeight: 1.75,
  color: '#a89b80',
  paddingLeft: '1.25rem',
  position: 'relative',
  marginBottom: '0.35rem',
};
