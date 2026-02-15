'use client';

import { createContext, useContext, useState, useCallback, useMemo, type ReactNode } from 'react';
import { useData, type AddonSettings } from './DataContext';
import { serializeToLua } from '@/lib/lua-serializer';

interface PatchContextType {
  editedTemplates: Record<string, string> | null;
  editedSettings: Partial<AddonSettings> | null;
  editedBlacklist: Record<string, true> | null;

  setEditedTemplates: (t: Record<string, string>) => void;
  setEditedSettings: (s: Partial<AddonSettings>) => void;
  setEditedBlacklist: (b: Record<string, true>) => void;

  isDirty: boolean;
  dirtyCount: number;
  dirtySummary: { templates: number; settings: number; blacklist: number };

  generatePatchString: () => string | null;
  resetAll: () => void;
}

const PatchContext = createContext<PatchContextType>({
  editedTemplates: null,
  editedSettings: null,
  editedBlacklist: null,
  setEditedTemplates: () => {},
  setEditedSettings: () => {},
  setEditedBlacklist: () => {},
  isDirty: false,
  dirtyCount: 0,
  dirtySummary: { templates: 0, settings: 0, blacklist: 0 },
  generatePatchString: () => null,
  resetAll: () => {},
});

function deepEqual(a: unknown, b: unknown): boolean {
  if (a === b) return true;
  if (a == null || b == null) return false;
  if (typeof a !== typeof b) return false;
  if (typeof a !== 'object') return false;

  const aObj = a as Record<string, unknown>;
  const bObj = b as Record<string, unknown>;
  const aKeys = Object.keys(aObj);
  const bKeys = Object.keys(bObj);

  if (aKeys.length !== bKeys.length) return false;
  return aKeys.every(key => deepEqual(aObj[key], bObj[key]));
}

export function PatchProvider({ children }: { children: ReactNode }) {
  const { data } = useData();

  const [editedTemplates, setEditedTemplates] = useState<Record<string, string> | null>(null);
  const [editedSettings, setEditedSettings] = useState<Partial<AddonSettings> | null>(null);
  const [editedBlacklist, setEditedBlacklist] = useState<Record<string, true> | null>(null);

  const dirtySummary = useMemo(() => {
    const result = { templates: 0, settings: 0, blacklist: 0 };

    if (editedTemplates && !deepEqual(editedTemplates, data?.templates || {})) {
      result.templates = Object.keys(editedTemplates).length;
    }
    if (editedSettings && !deepEqual(editedSettings, data?.settings || {})) {
      result.settings = Object.keys(editedSettings).length;
    }
    if (editedBlacklist && !deepEqual(editedBlacklist, data?.blacklist || {})) {
      result.blacklist = Object.keys(editedBlacklist).length;
    }

    return result;
  }, [editedTemplates, editedSettings, editedBlacklist, data]);

  const isDirty = dirtySummary.templates > 0 || dirtySummary.settings > 0 || dirtySummary.blacklist > 0;
  const dirtyCount = (dirtySummary.templates > 0 ? 1 : 0) + (dirtySummary.settings > 0 ? 1 : 0) + (dirtySummary.blacklist > 0 ? 1 : 0);

  const generatePatchString = useCallback(() => {
    if (!isDirty) return null;

    const patch: Record<string, unknown> = {
      _patchVersion: 'web-patch-1.0',
      timestamp: Math.floor(Date.now() / 1000),
    };

    if (editedTemplates && !deepEqual(editedTemplates, data?.templates || {})) {
      patch.templates = editedTemplates;
    }
    if (editedSettings && !deepEqual(editedSettings, data?.settings || {})) {
      patch.settings = editedSettings;
    }
    if (editedBlacklist && !deepEqual(editedBlacklist, data?.blacklist || {})) {
      patch.blacklist = editedBlacklist;
    }

    return serializeToLua(patch);
  }, [isDirty, editedTemplates, editedSettings, editedBlacklist, data]);

  const resetAll = useCallback(() => {
    setEditedTemplates(null);
    setEditedSettings(null);
    setEditedBlacklist(null);
  }, []);

  return (
    <PatchContext.Provider value={{
      editedTemplates,
      editedSettings,
      editedBlacklist,
      setEditedTemplates,
      setEditedSettings,
      setEditedBlacklist,
      isDirty,
      dirtyCount,
      dirtySummary,
      generatePatchString,
      resetAll,
    }}>
      {children}
    </PatchContext.Provider>
  );
}

export function usePatch() {
  return useContext(PatchContext);
}
