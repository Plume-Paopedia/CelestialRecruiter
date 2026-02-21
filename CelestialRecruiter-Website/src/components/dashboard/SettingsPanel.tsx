'use client';

import { useEffect, useCallback } from 'react';
import { useData, type AddonSettings } from '@/components/dashboard/DataContext';
import { usePatch } from '@/components/dashboard/PatchContext';
import { useTheme, THEME_PALETTES, THEME_IDS } from '@/components/dashboard/ThemeContext';

const THEME_SWATCHES = [
  { id: 'dark',   name: 'Sombre',       gradient: 'linear-gradient(135deg, #0d0f1c, #141829, #00adff)' },
  { id: 'light',  name: 'Clair',         gradient: 'linear-gradient(135deg, #f0f1f5, #fafafc, #338cd9)' },
  { id: 'purple', name: 'R\u00eave Violet', gradient: 'linear-gradient(135deg, #140d1e, #1a1029, #bf59ff)' },
  { id: 'green',  name: 'For\u00eat',    gradient: 'linear-gradient(135deg, #0d1a14, #121e1a, #4de680)' },
  { id: 'blue',   name: 'Oc\u00e9an',    gradient: 'linear-gradient(135deg, #0a1424, #0e192e, #26b3f2)' },
  { id: 'amber',  name: 'Ambre',         gradient: 'linear-gradient(135deg, #1a140d, #241c12, #ffb333)' },
];

const NOTIFICATION_TOGGLES = [
  { label: 'Whisper alerts', defaultOn: true },
  { label: 'Queue updates', defaultOn: true },
  { label: 'Campaign reports', defaultOn: false },
];

function SettingsInput({ label, value, onChange, type = 'text', min, max, suffix }: {
  label: string;
  value: string | number;
  onChange: (v: string | number) => void;
  type?: 'text' | 'number';
  min?: number;
  max?: number;
  suffix?: string;
}) {
  return (
    <div className="settings-edit-row">
      <span className="settings-edit-label">{label}</span>
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
        <input
          type={type}
          className="settings-input"
          value={value}
          onChange={(e) => onChange(type === 'number' ? Number(e.target.value) : e.target.value)}
          min={min}
          max={max}
          style={{ width: type === 'number' ? '5rem' : undefined }}
        />
        {suffix && <span style={{ fontSize: '0.72rem', color: '#6b5f4d' }}>{suffix}</span>}
      </div>
    </div>
  );
}

function SettingsToggle({ label, value, onChange }: {
  label: string;
  value: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <div className="settings-edit-row">
      <span className="settings-edit-label">{label}</span>
      <div
        className={`settings-toggle ${value ? 'on' : ''}`}
        onClick={() => onChange(!value)}
      >
        <div className="settings-toggle-knob" />
      </div>
    </div>
  );
}

export function SettingsPanel() {
  const { data, isLive } = useData();
  const { editedSettings, setEditedSettings, dirtySummary } = usePatch();
  const { currentTheme, setTheme } = useTheme();

  const settings: AddonSettings = isLive
    ? (editedSettings || data?.settings || {})
    : {};

  // Initialize edited state from data when live
  useEffect(() => {
    if (isLive && data?.settings && !editedSettings) {
      setEditedSettings({ ...data.settings });
    }
  }, [isLive, data?.settings, editedSettings, setEditedSettings]);

  const isDirty = dirtySummary.settings > 0;

  const updateSetting = useCallback(<K extends keyof AddonSettings>(key: K, value: AddonSettings[K]) => {
    setEditedSettings({ ...settings, [key]: value });
  }, [settings, setEditedSettings]);

  return (
    <div>
      {/* Theme selector */}
      <div className="panel-card">
        <div className="panel-title">
          <span className="panel-icon">{'\u{1F3A8}'}</span>
          Theme
        </div>
        <div className="settings-group">
          <div className="settings-label">Select Theme</div>
          <div className="theme-grid">
            {THEME_SWATCHES.map((swatch) => (
              <div
                key={swatch.id}
                className={`theme-swatch${currentTheme === swatch.id ? ' active' : ''}`}
                style={{ background: swatch.gradient }}
                title={swatch.name}
                onClick={() => setTheme(swatch.id)}
              />
            ))}
          </div>
          <div style={{ fontSize: '0.7rem', color: '#6b5f4d', marginTop: '0.5rem' }}>
            Cliquer pour pr\u00e9visualiser. Les th\u00e8mes s&apos;appliquent aussi dans l&apos;addon avec /cr.
          </div>
        </div>
      </div>

      {/* Notifications */}
      <div className="panel-card">
        <div className="panel-title">
          <span className="panel-icon">{'\u{1F514}'}</span>
          Notifications
        </div>
        <div className="settings-group">
          {NOTIFICATION_TOGGLES.map((toggle) => (
            <div key={toggle.label} className="toggle-row">
              <span>{toggle.label}</span>
              <div className={`toggle-switch${toggle.defaultOn ? ' on' : ''}`} />
            </div>
          ))}
        </div>
      </div>

      {/* Addon Settings (editable when live) */}
      {isLive && (
        <div className="panel-card">
          <div className="panel-title">
            <span className="panel-icon">{'\u2699'}</span>
            Addon Settings
            <span style={{ marginLeft: '0.5rem', fontSize: '0.65rem', color: '#4ade80', fontWeight: 400 }}>(live)</span>
            {isDirty && <span className="dirty-dot" />}
          </div>

          {/* Guild Info */}
          <div className="settings-section-label">Guild Info</div>
          <SettingsInput label="Guild Name" value={settings.guildName || ''} onChange={(v) => updateSetting('guildName', String(v))} />
          <SettingsInput label="Discord" value={settings.discord || ''} onChange={(v) => updateSetting('discord', String(v))} />
          <SettingsInput label="Raid Days" value={settings.raidDays || ''} onChange={(v) => updateSetting('raidDays', String(v))} />
          <SettingsInput label="Goal" value={settings.goal || ''} onChange={(v) => updateSetting('goal', String(v))} />

          {/* Cooldowns */}
          <div className="settings-section-label">Cooldowns</div>
          <SettingsInput label="Invite Cooldown" value={settings.cooldownInvite ?? 300} onChange={(v) => updateSetting('cooldownInvite', Number(v))} type="number" min={0} suffix="sec" />
          <SettingsInput label="Whisper Cooldown" value={settings.cooldownWhisper ?? 180} onChange={(v) => updateSetting('cooldownWhisper', Number(v))} type="number" min={0} suffix="sec" />

          {/* Rate Limits */}
          <div className="settings-section-label">Rate Limits</div>
          <SettingsInput label="Max Actions/min" value={settings.maxActionsPerMinute ?? 8} onChange={(v) => updateSetting('maxActionsPerMinute', Number(v))} type="number" min={1} />
          <SettingsInput label="Max Invites/h" value={settings.maxInvitesPerHour ?? 10} onChange={(v) => updateSetting('maxInvitesPerHour', Number(v))} type="number" min={1} />
          <SettingsInput label="Max Whispers/h" value={settings.maxWhispersPerHour ?? 20} onChange={(v) => updateSetting('maxWhispersPerHour', Number(v))} type="number" min={1} />

          {/* Behavior */}
          <div className="settings-section-label">Behavior</div>
          <SettingsToggle label="Respect AFK" value={settings.respectAFK ?? true} onChange={(v) => updateSetting('respectAFK', v)} />
          <SettingsToggle label="Respect DND" value={settings.respectDND ?? true} onChange={(v) => updateSetting('respectDND', v)} />

          {/* Scanner */}
          <div className="settings-section-label">Scanner</div>
          <SettingsInput label="Level Min" value={settings.scanLevelMin ?? 10} onChange={(v) => updateSetting('scanLevelMin', Number(v))} type="number" min={1} max={80} />
          <SettingsInput label="Level Max" value={settings.scanLevelMax ?? 80} onChange={(v) => updateSetting('scanLevelMax', Number(v))} type="number" min={1} max={80} />
          <SettingsInput label="Level Slice" value={settings.scanLevelSlice ?? 5} onChange={(v) => updateSetting('scanLevelSlice', Number(v))} type="number" min={1} max={80} />
          <SettingsToggle label="Include Guilded" value={settings.scanIncludeGuilded ?? false} onChange={(v) => updateSetting('scanIncludeGuilded', v)} />
          <SettingsToggle label="Include Cross-Realm" value={settings.scanIncludeCrossRealm ?? true} onChange={(v) => updateSetting('scanIncludeCrossRealm', v)} />
        </div>
      )}

      {/* Data management */}
      <div className="panel-card">
        <div className="panel-title">
          <span className="panel-icon">{'\u{1F4BE}'}</span>
          Data Management
        </div>
        <div className="settings-group">
          <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
            <button
              style={{
                padding: '0.55rem 1.25rem', fontSize: '0.82rem', fontWeight: 600,
                color: '#C9AA71',
                background: 'rgba(201, 170, 113, 0.1)',
                border: '1px solid #6b5635',
                borderRadius: 3, cursor: 'default',
              }}
            >
              Export Data
            </button>
            <a
              href="/dashboard/import"
              style={{
                padding: '0.55rem 1.25rem', fontSize: '0.82rem', fontWeight: 600,
                color: '#C9AA71', background: 'rgba(201, 170, 113, 0.1)',
                border: '1px solid #6b5635', borderRadius: 3,
                textDecoration: 'none', display: 'inline-block',
              }}
            >
              Import from Addon
            </a>
          </div>
        </div>
      </div>

      {/* About */}
      <div className="panel-card">
        <div className="panel-title">
          <span className="panel-icon">{'\u2139'}</span>
          About
        </div>
        <div style={{ fontSize: '0.78rem', color: '#a89b80', lineHeight: 1.6 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.35rem 0', borderBottom: '1px solid #2a2318' }}>
            <span style={{ color: '#6b5f4d' }}>Version</span>
            <span>{data?.version || '\u2014'}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.35rem 0', borderBottom: '1px solid #2a2318' }}>
            <span style={{ color: '#6b5f4d' }}>Addon</span>
            <span>CelestialRecruiter</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.35rem 0', borderBottom: '1px solid #2a2318' }}>
            <span style={{ color: '#6b5f4d' }}>Data</span>
            <span style={{ color: isLive ? '#4ade80' : '#6b5f4d' }}>{isLive ? 'Live' : 'No data imported'}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.35rem 0' }}>
            <span style={{ color: '#6b5f4d' }}>License</span>
            <span>Free (all features included)</span>
          </div>
        </div>
      </div>
    </div>
  );
}
