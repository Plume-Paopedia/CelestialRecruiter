import { LINKS } from '@/lib/constants';

export function Footer() {
  return (
    <footer
      style={{
        background: '#0d0c0a',
        borderTop: '1px solid #2a2318',
        padding: '3rem 1.5rem 2rem',
      }}
    >
      <div
        style={{
          maxWidth: '1140px',
          margin: '0 auto',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: '1.5rem',
        }}
      >
        <div
          style={{
            fontFamily: "'Cinzel', serif",
            fontSize: '1rem',
            fontWeight: 700,
            color: '#C9AA71',
            letterSpacing: '0.04em',
          }}
        >
          Celestial Recruiter
        </div>

        <nav
          style={{
            display: 'flex',
            justifyContent: 'center',
            gap: '1.5rem',
            flexWrap: 'wrap',
          }}
        >
          {[
            { label: 'Features', href: '#features' },
            { label: 'Dashboard', href: '/dashboard' },
            { label: 'Pricing', href: '#pricing' },
            { label: 'Changelog', href: '/changelog' },
            { label: 'FAQ', href: '#faq' },
            { label: 'Discord', href: LINKS.discord, external: true },
            { label: 'CurseForge', href: LINKS.curseforge, external: true },
            { label: 'Patreon', href: LINKS.patreon, external: true },
          ].map((link) => (
            <a
              key={link.label}
              href={link.href}
              {...(link.external
                ? { target: '_blank', rel: 'noopener noreferrer' }
                : {})}
              style={{
                color: '#6b5f4d',
                textDecoration: 'none',
                fontSize: '0.8rem',
                transition: 'color 0.2s ease',
                fontWeight: 500,
              }}
              onMouseEnter={(e) => {
                (e.target as HTMLElement).style.color = '#C9AA71';
              }}
              onMouseLeave={(e) => {
                (e.target as HTMLElement).style.color = '#6b5f4d';
              }}
            >
              {link.label}
            </a>
          ))}
        </nav>

        <div
          style={{
            display: 'flex',
            gap: '1rem',
            fontSize: '0.7rem',
          }}
        >
          <a href="/privacy" style={{ color: '#4a3f32', textDecoration: 'none' }}>
            Privacy
          </a>
          <a href="/terms" style={{ color: '#4a3f32', textDecoration: 'none' }}>
            Terms
          </a>
        </div>

        <p
          style={{
            color: '#4a3f32',
            fontSize: '0.7rem',
          }}
        >
          &copy; {new Date().getFullYear()} CelestialRecruiter by Plume. Not
          affiliated with Blizzard Entertainment.
        </p>
      </div>
    </footer>
  );
}
