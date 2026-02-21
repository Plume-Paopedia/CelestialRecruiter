'use client';

import { useState } from 'react';
import { TierProvider } from '@/components/dashboard/TierContext';
import { DataProvider } from '@/components/dashboard/DataContext';
import { PatchProvider } from '@/components/dashboard/PatchContext';
import { DashboardThemeProvider, useTheme } from '@/components/dashboard/ThemeContext';
import { Sidebar } from '@/components/dashboard/Sidebar';
import { TopBar } from '@/components/dashboard/TopBar';
import { OverviewPanel } from '@/components/dashboard/OverviewPanel';
import { ScannerPanel } from '@/components/dashboard/ScannerPanel';
import { QueuePanel } from '@/components/dashboard/QueuePanel';
import { TemplatesPanel } from '@/components/dashboard/TemplatesPanel';
import { AnalyticsPanel } from '@/components/dashboard/AnalyticsPanel';
import { CampaignsPanel } from '@/components/dashboard/CampaignsPanel';
import { DiscordPanel } from '@/components/dashboard/DiscordPanel';
import { SettingsPanel } from '@/components/dashboard/SettingsPanel';
import { BlacklistPanel } from '@/components/dashboard/BlacklistPanel';
import { DASHBOARD_MODULES } from '@/lib/constants';

const PANELS: Record<string, React.ComponentType> = {
  overview: OverviewPanel,
  scanner: ScannerPanel,
  queue: QueuePanel,
  templates: TemplatesPanel,
  blacklist: BlacklistPanel,
  analytics: AnalyticsPanel,
  campaigns: CampaignsPanel,
  discord: DiscordPanel,
  settings: SettingsPanel,
};

function DashboardContent() {
  const [activeModule, setActiveModule] = useState('overview');
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const { colors } = useTheme();

  const currentModule = DASHBOARD_MODULES.find(m => m.id === activeModule);
  const ActivePanel = PANELS[activeModule] || OverviewPanel;

  const themeVars = {
    '--cr-bg': colors.bg,
    '--cr-panel': colors.panel,
    '--cr-border': colors.border,
    '--cr-accent': colors.accent,
    '--cr-gold': colors.gold,
    '--cr-text': colors.text,
    '--cr-dim': colors.dim,
    '--cr-muted': colors.muted,
  } as React.CSSProperties;

  return (
    <div className="dashboard-layout" style={themeVars}>
      <Sidebar
        activeModule={activeModule}
        onModuleChange={(id) => {
          setActiveModule(id);
          setSidebarOpen(false);
        }}
      />

      <div className="dashboard-main">
        <TopBar
          title={currentModule?.label || 'Overview'}
          onMenuToggle={() => setSidebarOpen(!sidebarOpen)}
        />

        <div className="dashboard-content">
          <ActivePanel />
        </div>
      </div>
    </div>
  );
}

export default function DashboardPage() {
  return (
    <TierProvider defaultTier="pro">
      <DashboardThemeProvider>
        <DataProvider>
          <PatchProvider>
            <DashboardContent />
          </PatchProvider>
        </DataProvider>
      </DashboardThemeProvider>
    </TierProvider>
  );
}
