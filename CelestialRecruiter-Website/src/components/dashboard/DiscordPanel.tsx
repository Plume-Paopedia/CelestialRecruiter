'use client';

import { useTier } from '@/components/dashboard/TierContext';
import { useData } from '@/components/dashboard/DataContext';
import { LockedOverlay } from '@/components/dashboard/LockedOverlay';

// Event categories matching addon's GetEventTypes()
const EVENT_CATEGORIES = [
  {
    label: 'Guilde',
    events: [
      { id: 'guild_join', label: 'Nouveau membre' },
      { id: 'guild_leave', label: 'Membre quitte' },
      { id: 'guild_promote', label: 'Promotion' },
      { id: 'guild_demote', label: 'Retrogradation' },
    ],
  },
  {
    label: 'Recrutement',
    events: [
      { id: 'whisper_received', label: 'Whisper recu' },
      { id: 'player_whispered', label: 'Message envoye' },
      { id: 'player_invited', label: 'Invitation envoyee' },
      { id: 'player_joined', label: 'Joueur rejoint' },
      { id: 'queue_added', label: 'Ajoute a la file' },
      { id: 'queue_removed', label: 'Retire de la file' },
      { id: 'player_blacklisted', label: 'Joueur blackliste' },
    ],
  },
  {
    label: 'Scanner & Auto-Recruteur',
    events: [
      { id: 'scanner_started', label: 'Scanner demarre' },
      { id: 'scanner_stopped', label: 'Scanner arrete' },
      { id: 'scanner_complete', label: 'Scan termine' },
      { id: 'autorecruiter_complete', label: 'Auto-recruteur termine' },
    ],
  },
  {
    label: 'Resumes & Alertes',
    events: [
      { id: 'daily_summary', label: 'Resume quotidien' },
      { id: 'session_summary', label: 'Resume de session' },
      { id: 'limit_reached', label: 'Limite atteinte' },
    ],
  },
];

function formatTimestamp(ts: number): string {
  const now = Date.now() / 1000;
  const diff = now - ts;
  if (diff < 60) return 'just now';
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return `${Math.floor(diff / 86400)}d ago`;
}

export function DiscordPanel() {
  const { hasAccess } = useTier();
  const { data, isLive } = useData();
  const isLocked = !hasAccess('pro');

  const discordNotify = isLive ? data?.discordNotify : null;
  const discordQueue = isLive ? data?.discordQueue : null;

  return (
    <div style={{ position: 'relative' }}>
      {isLocked && (
        <LockedOverlay
          requiredTier="pro"
          featureName="Discord Integration"
          description="Send real-time recruitment notifications to your Discord server via webhooks."
        />
      )}

      {/* Webhook config */}
      <div className="panel-card">
        <div className="panel-title">
          <span className="panel-icon">{'\u2699'}</span>
          Webhook Configuration
          {isLive && discordNotify && (
            <span style={{ marginLeft: '0.5rem', fontSize: '0.65rem', color: '#4ade80', fontWeight: 400 }}>(live)</span>
          )}
        </div>
        {discordNotify ? (
          <div className="discord-config-grid">
            <div className="discord-config-row">
              <span className="discord-config-label">Webhook</span>
              <span className="discord-config-value">
                <span
                  style={{
                    width: 8,
                    height: 8,
                    borderRadius: '50%',
                    background: discordNotify.webhookConfigured ? '#4ade80' : '#6b5f4d',
                    display: 'inline-block',
                    marginRight: '0.4rem',
                  }}
                />
                {discordNotify.webhookConfigured ? 'Configured' : 'Not configured'}
              </span>
            </div>
            <div className="discord-config-row">
              <span className="discord-config-label">Notifications</span>
              <span className="discord-config-value" style={{ color: discordNotify.enabled ? '#4ade80' : '#e74c3c' }}>
                {discordNotify.enabled ? 'Enabled' : 'Disabled'}
              </span>
            </div>
            <div className="discord-config-row">
              <span className="discord-config-label">Summary Mode</span>
              <span className="discord-config-value" style={{ color: discordNotify.summaryMode ? '#C9AA71' : '#a89b80' }}>
                {discordNotify.summaryMode ? 'On' : 'Off'}
              </span>
            </div>
            <div className="discord-config-row">
              <span className="discord-config-label">Auto-Flush</span>
              <span className="discord-config-value">
                {discordNotify.autoFlush ? 'On' : 'Off'}
              </span>
            </div>
            <div className="discord-config-row">
              <span className="discord-config-label">Flush Delay</span>
              <span className="discord-config-value">{discordNotify.flushDelay}s</span>
            </div>
          </div>
        ) : (
          <div style={{ textAlign: 'center', padding: '1.5rem', color: '#6b5f4d', fontSize: '0.82rem' }}>
            No Discord configuration. Import your addon data to see webhook settings.
          </div>
        )}
      </div>

      {/* Event Toggles (live data only) */}
      {isLive && discordNotify && (
        <div className="panel-card">
          <div className="panel-title">
            <span className="panel-icon">{'\u{1F514}'}</span>
            Event Toggles
            <span style={{ marginLeft: '0.5rem', fontSize: '0.65rem', color: '#6b5f4d', fontWeight: 400 }}>(read-only)</span>
          </div>
          <div className="discord-toggle-grid">
            {EVENT_CATEGORIES.map((cat) => (
              <div key={cat.label} className="discord-toggle-category">
                <div className="discord-toggle-category-label">{cat.label}</div>
                {cat.events.map((ev) => {
                  const isOn = discordNotify.events?.[ev.id] ?? false;
                  return (
                    <div key={ev.id} className="discord-event-item">
                      <span
                        className="discord-event-dot"
                        style={{ background: isOn ? '#4ade80' : '#3a3228' }}
                      />
                      <span style={{ color: isOn ? '#d4c5a9' : '#4a3f32' }}>{ev.label}</span>
                    </div>
                  );
                })}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Message feed / Queue */}
      <div className="panel-card">
        <div className="panel-title">
          <span className="panel-icon">{'\u2709'}</span>
          {isLive && discordQueue ? 'Event Queue' : 'Recent Messages'}
          {isLive && discordQueue && (
            <span style={{ marginLeft: '0.5rem', fontSize: '0.65rem', color: '#a89b80', fontWeight: 400 }}>
              ({discordQueue.length} pending)
            </span>
          )}
        </div>
        <div
          style={{
            background: '#2f3136',
            borderRadius: 6,
            padding: '0.75rem',
          }}
        >
          {discordQueue && discordQueue.length > 0 ? (
            <div className="discord-queue-feed">
              {[...discordQueue].reverse().slice(0, 20).map((event, i) => (
                <div key={`${event.timestamp}-${i}`} className="discord-message">
                  <div className="discord-avatar" style={{ fontSize: '1rem' }}>{event.icon || 'CR'}</div>
                  <div className="discord-body">
                    <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem' }}>
                      <span className="discord-author">{event.title}</span>
                      <span style={{ fontSize: '0.65rem', color: '#6b5f4d' }}>
                        {formatTimestamp(event.timestamp)}
                      </span>
                    </div>
                    <div className="discord-text">{event.description}</div>
                    {event.fields && event.fields.length > 0 && (
                      <div className="discord-embed">
                        {event.fields.slice(0, 4).map((f, fi) => (
                          <span key={fi} style={{ marginRight: '1rem' }}>
                            <span style={{ color: '#6b5f4d' }}>{f.name}:</span> {f.value}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div style={{ textAlign: 'center', padding: '1.5rem', color: '#6b5f4d', fontSize: '0.78rem' }}>
              No events. Import your addon data to see Discord notifications.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
