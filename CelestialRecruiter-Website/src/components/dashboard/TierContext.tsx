'use client';

import { createContext, useContext, useState, type ReactNode } from 'react';
import { TIER_LEVELS } from '@/lib/constants';

type TierName = 'free' | 'recruteur' | 'pro' | 'lifetime';

interface TierContextType {
  currentTier: TierName;
  setTier: (tier: TierName) => void;
  hasAccess: (requiredTier: string) => boolean;
}

const TierContext = createContext<TierContextType>({
  currentTier: 'pro',
  setTier: () => {},
  hasAccess: () => true,
});

export function TierProvider({ children, defaultTier = 'pro' }: { children: ReactNode; defaultTier?: TierName }) {
  const [currentTier, setCurrentTier] = useState<TierName>(defaultTier);

  const hasAccess = (requiredTier: string) => {
    return (TIER_LEVELS[currentTier] ?? 0) >= (TIER_LEVELS[requiredTier] ?? 0);
  };

  return (
    <TierContext.Provider value={{ currentTier, setTier: setCurrentTier, hasAccess }}>
      {children}
    </TierContext.Provider>
  );
}

export function useTier() {
  return useContext(TierContext);
}
