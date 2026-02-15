'use client';

// A very subtle radial glow effect for section backgrounds
// Used to add depth without being flashy
// Props: color (default warm gold), opacity (default 0.04), size (default 500px)
// Renders as an absolutely positioned div with a radial gradient
// Should be barely perceptible — just enough to add warmth

interface AmbientGlowProps {
  color?: string;
  opacity?: number;
  size?: number;
  position?: 'center' | 'left' | 'right';
}

function hexToRgb(hex: string): { r: number; g: number; b: number } {
  const cleaned = hex.replace('#', '');
  const r = parseInt(cleaned.substring(0, 2), 16);
  const g = parseInt(cleaned.substring(2, 4), 16);
  const b = parseInt(cleaned.substring(4, 6), 16);
  return { r, g, b };
}

export function AmbientGlow({
  color = '#C9AA71',
  opacity = 0.04,
  size = 500,
  position = 'center',
}: AmbientGlowProps) {
  const { r, g, b } = hexToRgb(color);

  const positionStyles: React.CSSProperties = (() => {
    switch (position) {
      case 'left':
        return {
          top: '50%',
          left: '20%',
          transform: 'translate(-50%, -50%)',
        };
      case 'right':
        return {
          top: '50%',
          right: '20%',
          transform: 'translate(50%, -50%)',
        };
      case 'center':
      default:
        return {
          top: '50%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
        };
    }
  })();

  return (
    <div
      aria-hidden="true"
      style={{
        position: 'absolute',
        pointerEvents: 'none',
        width: `${size}px`,
        height: `${size}px`,
        borderRadius: '50%',
        background: `radial-gradient(circle, rgba(${r}, ${g}, ${b}, ${opacity}) 0%, transparent 70%)`,
        ...positionStyles,
      }}
    />
  );
}
