'use client';

import { createContext, useContext, type ReactNode } from 'react';

interface TierContextType {
  currentTier: string;
  setTier: (tier: string) => void;
  hasAccess: (requiredTier: string) => boolean;
}

const TierContext = createContext<TierContextType>({
  currentTier: 'full',
  setTier: () => {},
  hasAccess: () => true,
});

export function TierProvider({ children }: { children: ReactNode; defaultTier?: string }) {
  return (
    <TierContext.Provider value={{ currentTier: 'full', setTier: () => {}, hasAccess: () => true }}>
      {children}
    </TierContext.Provider>
  );
}

export function useTier() {
  return useContext(TierContext);
}
