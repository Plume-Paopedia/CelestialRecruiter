import type { Metadata } from 'next';
import './globals.scss';

export const metadata: Metadata = {
  metadataBase: new URL('https://celestialrecruiter.com'),
  title: 'CelestialRecruiter - Legendary WoW Guild Recruitment Addon',
  description:
    'Automate guild recruitment in World of Warcraft. Auto-scan, Discord integration, and advanced analytics.',
  keywords: [
    'World of Warcraft',
    'WoW addon',
    'guild recruitment',
    'auto recruiter',
    'wow scanner',
    'discord integration',
    'guild management',
  ],
  authors: [{ name: 'Plume', url: 'https://discord.gg/3HwyEBaAQB' }],
  openGraph: {
    title: 'CelestialRecruiter - Automate WoW Guild Recruitment',
    description:
      'Stop wasting time on /who spam. Recruit smarter with automation.',
    images: ['/og-image.png'],
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'CelestialRecruiter - WoW Recruitment Addon',
    description: 'Legendary-tier guild recruitment automation',
    images: ['/og-image.png'],
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
