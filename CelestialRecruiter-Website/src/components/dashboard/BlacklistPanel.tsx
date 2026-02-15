'use client';

import { useState, useEffect, useMemo, useCallback } from 'react';
import { useTier } from '@/components/dashboard/TierContext';
import { useData } from '@/components/dashboard/DataContext';
import { usePatch } from '@/components/dashboard/PatchContext';
import { LockedOverlay } from '@/components/dashboard/LockedOverlay';

export function BlacklistPanel() {
  const { hasAccess } = useTier();
  const { data, isLive } = useData();
  const { editedBlacklist, setEditedBlacklist, dirtySummary } = usePatch();
  const isLocked = !hasAccess('recruteur');

  const [search, setSearch] = useState('');
  const [newName, setNewName] = useState('');
  const [newRealm, setNewRealm] = useState('');

  const blacklist = useMemo(() => {
    return editedBlacklist || data?.blacklist || {};
  }, [editedBlacklist, data?.blacklist]);

  // Initialize edited state from data when live
  useEffect(() => {
    if (isLive && data?.blacklist && !editedBlacklist) {
      setEditedBlacklist({ ...data.blacklist });
    }
  }, [isLive, data?.blacklist, editedBlacklist, setEditedBlacklist]);

  const isDirty = dirtySummary.blacklist > 0;
  const entries = Object.keys(blacklist);

  const filteredEntries = useMemo(() => {
    if (!search.trim()) return entries;
    const q = search.toLowerCase();
    return entries.filter(e => e.toLowerCase().includes(q));
  }, [entries, search]);

  const addEntry = useCallback(() => {
    const name = newName.trim();
    const realm = newRealm.trim();
    if (!name || !realm) return;
    const key = `${name}-${realm}`;
    if (blacklist[key]) return;
    setEditedBlacklist({ ...blacklist, [key]: true });
    setNewName('');
    setNewRealm('');
  }, [newName, newRealm, blacklist, setEditedBlacklist]);

  const removeEntry = useCallback((key: string) => {
    const updated = { ...blacklist };
    delete updated[key];
    setEditedBlacklist(updated as Record<string, true>);
  }, [blacklist, setEditedBlacklist]);

  return (
    <div style={{ position: 'relative' }}>
      {isLocked && (
        <LockedOverlay
          requiredTier="recruteur"
          featureName="Blacklist Manager"
          description="Manage your blacklist from the web dashboard."
        />
      )}

      <div className="panel-card">
        <div className="panel-title">
          <span className="panel-icon">{'\u26D4'}</span>
          Blacklist
          {isLive && (
            <span style={{ marginLeft: '0.5rem', fontSize: '0.65rem', color: '#4ade80', fontWeight: 400 }}>
              ({entries.length} players)
            </span>
          )}
          {isDirty && <span className="dirty-dot" />}
        </div>

        {/* Add form (live only) */}
        {isLive && (
          <div className="blacklist-add-form">
            <input
              type="text"
              className="settings-input"
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              placeholder="Player name"
              style={{ flex: 1 }}
              onKeyDown={(e) => e.key === 'Enter' && addEntry()}
            />
            <input
              type="text"
              className="settings-input"
              value={newRealm}
              onChange={(e) => setNewRealm(e.target.value)}
              placeholder="Realm"
              style={{ flex: 1 }}
              onKeyDown={(e) => e.key === 'Enter' && addEntry()}
            />
            <button
              className="template-add-btn"
              onClick={addEntry}
              disabled={!newName.trim() || !newRealm.trim()}
            >
              Add
            </button>
          </div>
        )}

        {/* Search */}
        {entries.length > 5 && (
          <div style={{ marginBottom: '0.75rem' }}>
            <input
              type="text"
              className="settings-input"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search blacklist..."
              style={{ width: '100%' }}
            />
          </div>
        )}

        {/* List */}
        <div className="blacklist-table">
          {filteredEntries.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '1.5rem', color: '#6b5f4d', fontSize: '0.78rem' }}>
              {entries.length === 0 ? 'No blacklisted players' : 'No results'}
            </div>
          ) : (
            filteredEntries.map((key) => {
              const parts = key.split('-');
              const name = parts[0] || key;
              const realm = parts.slice(1).join('-') || '';

              return (
                <div key={key} className="blacklist-row">
                  <div className="blacklist-player">
                    <span className="blacklist-name">{name}</span>
                    {realm && <span className="blacklist-realm">-{realm}</span>}
                  </div>
                  {isLive && (
                    <button
                      className="template-delete-btn"
                      onClick={() => removeEntry(key)}
                      title="Remove from blacklist"
                    >
                      {'\u2716'}
                    </button>
                  )}
                </div>
              );
            })
          )}
        </div>

        {/* Count */}
        {entries.length > 0 && (
          <div style={{ marginTop: '0.5rem', fontSize: '0.7rem', color: '#6b5f4d', textAlign: 'right' }}>
            {filteredEntries.length}/{entries.length} shown
          </div>
        )}
      </div>
    </div>
  );
}
