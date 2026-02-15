'use client';

import { createContext, useContext, useState, useEffect, useCallback, type ReactNode } from 'react';
import { parseLuaTable } from '@/lib/lua-parser';

// ============================================
// Types matching CelestialRecruiter addon data
// ============================================

export interface AddonContact {
  name: string;
  key?: string;
  status: string; // new | contacted | invited | joined | ignored
  source?: string;
  classFile?: string;
  classLabel?: string;
  level?: number;
  race?: string;
  zone?: string;
  guild?: string;
  crossRealm?: boolean;
  optedIn?: boolean;
  tags?: string[];
  notes?: string;
  firstSeen?: number;
  lastSeen?: number;
  lastWhisperIn?: number;
  lastWhisperOut?: number;
  lastInviteAt?: number;
}

export interface AddonStatistics {
  hourlyActivity?: Record<string, number>;
  templateStats?: Record<string, { used: number; success: number }>;
  dailyHistory?: Record<string, {
    scans: number;
    contacted: number;
    invited: number;
    joined: number;
    found: number;
  }>;
  conversionFunnel?: {
    contacted: number;
    invited: number;
    joined: number;
  };
  classStats?: Record<string, { contacted: number; joined: number }>;
  levelRangeStats?: Record<string, number>;
  sourceStats?: Record<string, number>;
}

export interface DiscordNotifySettings {
  enabled: boolean;
  summaryMode: boolean;
  autoFlush: boolean;
  flushDelay: number;
  events: Record<string, boolean>;
  webhookConfigured: boolean;
}

export interface DiscordQueueEvent {
  timestamp: number;
  eventType: string;
  icon: string;
  color: number;
  title: string;
  description: string;
  fields: Array<{ name: string; value: string; inline?: boolean }>;
}

export interface AddonSettings {
  guildName?: string;
  discord?: string;
  raidDays?: string;
  goal?: string;
  keywords?: string[];
  cooldownInvite?: number;
  cooldownWhisper?: number;
  maxActionsPerMinute?: number;
  maxInvitesPerHour?: number;
  maxWhispersPerHour?: number;
  respectAFK?: boolean;
  respectDND?: boolean;
  scanLevelMin?: number;
  scanLevelMax?: number;
  scanLevelSlice?: number;
  scanIncludeGuilded?: boolean;
  scanIncludeCrossRealm?: boolean;
}

export interface AddonData {
  version: string;
  timestamp: number;
  realm?: string;
  character?: string;
  contacts: Record<string, AddonContact>;
  queue?: string[];
  statistics?: AddonStatistics;
  templates?: Record<string, string>;
  settings?: AddonSettings;
  campaigns?: Record<string, unknown>;
  discordNotify?: DiscordNotifySettings;
  discordQueue?: DiscordQueueEvent[];
  blacklist?: Record<string, true>;
}

export interface ImportResult {
  success: boolean;
  error?: string;
  summary?: {
    contacts: number;
    templates: number;
    hasStatistics: boolean;
    hasSettings: boolean;
    realm?: string;
    character?: string;
  };
}

interface DataContextType {
  data: AddonData | null;
  isLive: boolean;
  importData: (luaString: string) => ImportResult;
  clearData: () => void;
  lastImport: string | null;
}

const STORAGE_KEY = 'cr-addon-data';
const STORAGE_TIMESTAMP_KEY = 'cr-addon-import-time';

const DataContext = createContext<DataContextType>({
  data: null,
  isLive: false,
  importData: () => ({ success: false, error: 'DataProvider not mounted' }),
  clearData: () => {},
  lastImport: null,
});

function validateAddonData(raw: Record<string, unknown>): AddonData | null {
  // Must have contacts as an object
  if (!raw.contacts || typeof raw.contacts !== 'object') return null;

  return {
    version: String(raw.version || 'unknown'),
    timestamp: Number(raw.timestamp) || 0,
    realm: raw.realm ? String(raw.realm) : undefined,
    character: raw.character ? String(raw.character) : undefined,
    contacts: raw.contacts as Record<string, AddonContact>,
    queue: Array.isArray(raw.queue) ? raw.queue as string[] : undefined,
    statistics: raw.statistics as AddonStatistics | undefined,
    templates: raw.templates as Record<string, string> | undefined,
    settings: raw.settings as AddonSettings | undefined,
    campaigns: raw.campaigns as Record<string, unknown> | undefined,
    discordNotify: raw.discordNotify as DiscordNotifySettings | undefined,
    discordQueue: Array.isArray(raw.discordQueue) ? raw.discordQueue as DiscordQueueEvent[] : undefined,
    blacklist: (raw.blacklist && typeof raw.blacklist === 'object' && !Array.isArray(raw.blacklist))
      ? raw.blacklist as Record<string, true>
      : undefined,
  };
}

export function DataProvider({ children }: { children: ReactNode }) {
  const [data, setData] = useState<AddonData | null>(null);
  const [lastImport, setLastImport] = useState<string | null>(null);

  // Load from localStorage on mount
  useEffect(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      const timestamp = localStorage.getItem(STORAGE_TIMESTAMP_KEY);
      if (stored) {
        const parsed = JSON.parse(stored);
        const validated = validateAddonData(parsed);
        if (validated) {
          setData(validated);
          setLastImport(timestamp);
        }
      }
    } catch {
      // Silently fail - will use mock data
    }
  }, []);

  const importData = useCallback((luaString: string): ImportResult => {
    const result = parseLuaTable(luaString);

    if (!result.success) {
      return { success: false, error: result.error };
    }

    const validated = validateAddonData(result.data);
    if (!validated) {
      return {
        success: false,
        error: 'Invalid data structure: missing contacts table',
      };
    }

    // Save to localStorage
    const now = new Date().toISOString();
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(validated));
      localStorage.setItem(STORAGE_TIMESTAMP_KEY, now);
    } catch {
      return { success: false, error: 'Failed to save data (storage full?)' };
    }

    setData(validated);
    setLastImport(now);

    return {
      success: true,
      summary: {
        contacts: Object.keys(validated.contacts).length,
        templates: validated.templates ? Object.keys(validated.templates).length : 0,
        hasStatistics: !!validated.statistics,
        hasSettings: !!validated.settings,
        realm: validated.realm,
        character: validated.character,
      },
    };
  }, []);

  const clearData = useCallback(() => {
    localStorage.removeItem(STORAGE_KEY);
    localStorage.removeItem(STORAGE_TIMESTAMP_KEY);
    setData(null);
    setLastImport(null);
  }, []);

  return (
    <DataContext.Provider value={{
      data,
      isLive: data !== null,
      importData,
      clearData,
      lastImport,
    }}>
      {children}
    </DataContext.Provider>
  );
}

export function useData() {
  return useContext(DataContext);
}
