'use client';

import { Suspense, useState, useEffect } from 'react';
import { useSearchParams } from 'next/navigation';
import { motion } from 'framer-motion';
import { StarfieldCanvas } from '@/components/effects/Starfield';
import { fadeInUp, staggerContainer } from '@/lib/animations';

const TIER_COLORS: Record<string, string> = {
  REC: '#0070dd',
  PRO: '#a335ee',
  LIFE: '#ff8000',
};

const TIER_CSS: Record<string, string> = {
  REC: 'tier-rare',
  PRO: 'tier-epic',
  LIFE: 'tier-legendary',
};

interface PatronInfo {
  patron_name: string;
  tier_code: string;
  tier_label: string;
  email: string;
}

interface ClaimResult {
  key: string;
  tier_code: string;
  tier_label: string;
  player: string;
  expiry: string;
  email_sent: boolean;
}

type PageState = 'loading' | 'invalid' | 'form' | 'claiming' | 'success';

function ActivateContent() {
  const searchParams = useSearchParams();
  const token = searchParams.get('token') || '';

  const [state, setState] = useState<PageState>('loading');
  const [error, setError] = useState('');
  const [patronInfo, setPatronInfo] = useState<PatronInfo | null>(null);
  const [player, setPlayer] = useState('');
  const [result, setResult] = useState<ClaimResult | null>(null);
  const [copied, setCopied] = useState(false);
  const [copiedCmd, setCopiedCmd] = useState(false);

  useEffect(() => {
    if (!token) {
      setError("Aucun token d'activation. Utilise le lien de ton email.");
      setState('invalid');
      return;
    }

    fetch('/api/activate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token, action: 'verify' }),
    })
      .then((res) => res.json())
      .then((data) => {
        if (data.valid) {
          setPatronInfo(data);
          setState('form');
        } else {
          setError(data.error || 'Token invalide ou expiré.');
          setState('invalid');
        }
      })
      .catch(() => {
        setError('Impossible de vérifier le token. Réessaie plus tard.');
        setState('invalid');
      });
  }, [token]);

  const handleClaim = async () => {
    if (!player.trim() || !player.includes('-')) return;

    setState('claiming');
    try {
      const res = await fetch('/api/activate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token, player: player.trim(), action: 'claim' }),
      });
      const data = await res.json();

      if (data.key) {
        setResult(data);
        setState('success');
      } else {
        setError(data.error || 'Impossible de générer la clef.');
        setState('invalid');
      }
    } catch {
      setError('Erreur réseau. Réessaie.');
      setState('form');
    }
  };

  const handleCopy = async (text: string, type: 'key' | 'cmd') => {
    await navigator.clipboard.writeText(text);
    if (type === 'key') {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } else {
      setCopiedCmd(true);
      setTimeout(() => setCopiedCmd(false), 2000);
    }
  };

  const isValidPlayer = player.trim().length >= 3 && player.includes('-');

  return (
    <div className="activate-page">
      <StarfieldCanvas />

      <nav className="site-nav">
        <a href="/" className="nav-brand">Celestial Recruiter</a>
        <div className="nav-links">
          <a href="/" className="nav-link">Accueil</a>
        </div>
      </nav>

      <div className="activate-container">
        {/* LOADING */}
        {state === 'loading' && (
          <motion.div className="activate-loading" initial="hidden" animate="visible" variants={fadeInUp}>
            <div className="activate-spinner" />
            <p>Vérification de ton lien d&apos;activation...</p>
          </motion.div>
        )}

        {/* INVALID */}
        {state === 'invalid' && (
          <motion.div className="activate-error-panel" initial="hidden" animate="visible" variants={staggerContainer}>
            <motion.div className="activate-error-icon" variants={fadeInUp}>&#x2716;</motion.div>
            <motion.h1 variants={fadeInUp}>Activation impossible</motion.h1>
            <motion.p variants={fadeInUp}>{error}</motion.p>
            <motion.div variants={fadeInUp} className="activate-error-help">
              <p>Cela peut arriver si :</p>
              <ul>
                <li>Le lien a expiré (limite de 7 jours)</li>
                <li>Le lien a déjà été utilisé</li>
                <li>Le lien est incomplet ou modifié</li>
              </ul>
              <p>
                Besoin d&apos;aide ?{' '}
                <a href="https://discord.gg/3HwyEBaAQB" target="_blank" rel="noopener noreferrer">
                  Rejoins le Discord
                </a>
              </p>
            </motion.div>
          </motion.div>
        )}

        {/* FORM */}
        {(state === 'form' || state === 'claiming') && patronInfo && (
          <motion.div initial="hidden" animate="visible" variants={staggerContainer}>
            <motion.div className="activate-header" variants={fadeInUp}>
              <span className="activate-section-label">Activation de Licence</span>
              <h1>Active ta licence</h1>
              <p>Entre le nom de ton personnage WoW pour générer ta clef personnelle</p>
            </motion.div>

            <motion.div
              className={`activate-patron-card ${TIER_CSS[patronInfo.tier_code] || ''}`}
              variants={fadeInUp}
            >
              <div className="activate-patron-greeting">
                Bienvenue, <strong>{patronInfo.patron_name}</strong>
              </div>
              <div className="activate-patron-tier">
                <span
                  className="activate-tier-badge"
                  style={{ color: TIER_COLORS[patronInfo.tier_code] }}
                >
                  {patronInfo.tier_label}
                </span>
              </div>
            </motion.div>

            <motion.div className="activate-form-section" variants={fadeInUp}>
              <label className="activate-label">Personnage (Nom-Royaume)</label>
              <div className="activate-input-hint">
                Entre ton nom de personnage exactement comme en jeu, suivi d&apos;un tiret et du nom du royaume.
              </div>
              <input
                type="text"
                className="activate-input"
                value={player}
                onChange={(e) => setPlayer(e.target.value)}
                placeholder="Plume-Hyjal"
                disabled={state === 'claiming'}
                autoFocus
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && isValidPlayer) handleClaim();
                }}
              />
              {player && !isValidPlayer && (
                <div className="activate-input-error">
                  Format attendu : Nom-Royaume (ex: Plume-Hyjal)
                </div>
              )}
            </motion.div>

            <motion.div className="activate-notice" variants={fadeInUp}>
              <strong>Important :</strong> Ta clef sera liée définitivement à ce personnage.
              Vérifie bien l&apos;orthographe avant de valider. Ce lien ne peut être utilisé qu&apos;une seule fois.
            </motion.div>

            <motion.div className="activate-actions" variants={fadeInUp}>
              <button
                className="btn-legendary activate-submit-btn"
                onClick={handleClaim}
                disabled={!isValidPlayer || state === 'claiming'}
              >
                {state === 'claiming' ? 'Génération en cours...' : 'Générer ma clef de licence'}
              </button>
            </motion.div>
          </motion.div>
        )}

        {/* SUCCESS */}
        {state === 'success' && result && (
          <motion.div initial="hidden" animate="visible" variants={staggerContainer}>
            <motion.div className="activate-success-header" variants={fadeInUp}>
              <div className="activate-success-icon">&#x2714;</div>
              <h1>Licence activée !</h1>
              <p>Ta clef {result.tier_label} est prête</p>
            </motion.div>

            <motion.div
              className={`activate-key-panel ${TIER_CSS[result.tier_code] || ''}`}
              variants={fadeInUp}
            >
              <div className="activate-key-label">Ta clef de licence</div>
              <div className="activate-key-value">{result.key}</div>
              <button
                className={`activate-copy-btn ${copied ? 'copied' : ''}`}
                onClick={() => handleCopy(result.key, 'key')}
              >
                {copied ? 'Copié !' : 'Copier la clef'}
              </button>
            </motion.div>

            <motion.div className="activate-instructions" variants={fadeInUp}>
              <div className="activate-instructions-title">Comment activer dans WoW</div>
              <div className="activate-steps">
                <div className="step">
                  <div className="step-number">1</div>
                  <div className="step-content">
                    <div className="step-title">Connecte-toi à WoW</div>
                    <div className="step-desc">
                      Assure-toi d&apos;être sur <strong>{result.player}</strong>
                    </div>
                  </div>
                </div>
                <div className="step">
                  <div className="step-number">2</div>
                  <div className="step-content">
                    <div className="step-title">Ouvre le chat et tape</div>
                    <div className="step-desc">
                      <code>/cr activate {result.key}</code>
                      <button
                        className={`activate-copy-inline ${copiedCmd ? 'copied' : ''}`}
                        onClick={() => handleCopy(`/cr activate ${result.key}`, 'cmd')}
                        title="Copier la commande"
                      >
                        {copiedCmd ? '&#x2714;' : '&#x2398;'}
                      </button>
                    </div>
                  </div>
                </div>
                <div className="step">
                  <div className="step-number">3</div>
                  <div className="step-content">
                    <div className="step-title">C&apos;est fait !</div>
                    <div className="step-desc">Toutes tes fonctionnalités premium sont débloquées</div>
                  </div>
                </div>
              </div>
            </motion.div>

            <motion.div className="activate-details" variants={fadeInUp}>
              <div className="activate-detail-row">
                <span>Personnage</span>
                <span className="activate-detail-value">{result.player}</span>
              </div>
              <div className="activate-detail-row">
                <span>Tier</span>
                <span
                  className="activate-detail-value"
                  style={{ color: TIER_COLORS[result.tier_code] }}
                >
                  {result.tier_label}
                </span>
              </div>
              <div className="activate-detail-row">
                <span>Expiration</span>
                <span className="activate-detail-value">{result.expiry}</span>
              </div>
              {result.email_sent && (
                <div className="activate-detail-row">
                  <span>Email de backup</span>
                  <span className="activate-detail-value">Envoyé sur ton email Patreon</span>
                </div>
              )}
            </motion.div>

            <motion.div className="activate-footer" variants={fadeInUp}>
              Besoin d&apos;aide ?{' '}
              <a href="https://discord.gg/3HwyEBaAQB" target="_blank" rel="noopener noreferrer">
                Rejoins le Discord
              </a>
            </motion.div>
          </motion.div>
        )}
      </div>
    </div>
  );
}

export default function ActivatePage() {
  return (
    <Suspense
      fallback={
        <div className="activate-page">
          <div className="activate-loading">
            <p>Chargement...</p>
          </div>
        </div>
      }
    >
      <ActivateContent />
    </Suspense>
  );
}
