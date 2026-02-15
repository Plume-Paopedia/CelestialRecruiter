export function getTierColor(tier: string): string {
  switch (tier) {
    case 'legendary': return '255, 128, 0';
    case 'epic': return '163, 53, 238';
    case 'rare': return '0, 112, 221';
    case 'uncommon': return '30, 255, 0';
    default: return '157, 157, 157';
  }
}

export function getTimeBasedGreeting(): string {
  const hour = new Date().getHours();

  if (hour >= 2 && hour < 6) {
    return 'Still recruiting at this hour? Hardcore.';
  } else if (hour >= 18 && hour < 23) {
    return 'Prime time recruiting hours!';
  }
  return 'Ready to Recruit Like a Legend?';
}
