import Link from 'next/link';

export default function NotFound() {
  return (
    <div
      style={{
        minHeight: '100vh',
        background: '#0d0c0a',
        paddingTop: 56,
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      <nav className="site-nav">
        <Link href="/" className="nav-brand">
          Celestial Recruiter
        </Link>
        <div className="nav-links">
          <Link href="/" className="nav-link">
            Accueil
          </Link>
        </div>
      </nav>

      <div
        style={{
          flex: 1,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '2rem 1.5rem',
        }}
      >
        <div
          style={{
            maxWidth: 500,
            width: '100%',
            background: '#1a1814',
            border: '1px solid #352c20',
            borderRadius: 6,
            boxShadow:
              'inset 0 1px 0 rgba(255,255,255,0.02), inset 0 -1px 0 rgba(0,0,0,0.3), 0 2px 12px rgba(0,0,0,0.4)',
            padding: '3rem 2.5rem',
            textAlign: 'center',
            position: 'relative',
          }}
        >
          {/* Corner decorations */}
          <div
            style={{
              position: 'absolute',
              top: -1,
              left: -1,
              width: 10,
              height: 10,
              borderTop: '1px solid #6b5635',
              borderLeft: '1px solid #6b5635',
              pointerEvents: 'none',
            }}
          />
          <div
            style={{
              position: 'absolute',
              top: -1,
              right: -1,
              width: 10,
              height: 10,
              borderTop: '1px solid #6b5635',
              borderRight: '1px solid #6b5635',
              pointerEvents: 'none',
            }}
          />

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
            ERREUR 404
          </span>

          <h1
            style={{
              fontFamily: "'Cinzel', serif",
              fontSize: 'clamp(1.5rem, 3vw, 2.25rem)',
              fontWeight: 700,
              color: '#C9AA71',
              letterSpacing: '0.03em',
              marginBottom: '1rem',
              textShadow: '0 1px 8px rgba(201, 170, 113, 0.08)',
            }}
          >
            Page introuvable
          </h1>

          <p
            style={{
              color: '#a89b80',
              fontSize: '1rem',
              lineHeight: 1.6,
              marginBottom: '2rem',
              fontFamily: "'Montserrat', sans-serif",
            }}
          >
            La page que vous cherchez n&apos;existe pas ou a ete deplacee.
          </p>

          <Link href="/" className="btn-legendary" style={{ fontSize: '0.95rem', padding: '0.85rem 2rem' }}>
            Retour a l&apos;accueil
          </Link>
        </div>
      </div>
    </div>
  );
}
