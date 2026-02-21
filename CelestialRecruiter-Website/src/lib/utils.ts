export function getTimeBasedGreeting(): string {
  const hour = new Date().getHours();

  if (hour >= 2 && hour < 6) {
    return 'Still recruiting at this hour? Hardcore.';
  } else if (hour >= 18 && hour < 23) {
    return 'Prime time recruiting hours!';
  }
  return 'Ready to Recruit Like a Legend?';
}
