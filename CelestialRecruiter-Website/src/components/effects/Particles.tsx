'use client';

import { useEffect, useRef } from 'react';

interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  size: number;
  opacity: number;
  hue: number;
  life: number;
  maxLife: number;
}

interface ParticleSystemProps {
  count?: number;
}

export function ParticleSystem({ count = 15 }: ParticleSystemProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let animationId: number;

    const resize = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };
    resize();

    const particles: Particle[] = [];

    function spawnParticle() {
      if (!canvas) return;
      particles.push({
        x: Math.random() * canvas.width,
        y: canvas.height + 10,
        vx: (Math.random() - 0.5) * 0.2,
        vy: -(Math.random() * 0.3 + 0.1),
        size: Math.random() * 1 + 1, // 1-2px
        opacity: Math.random() * 0.3 + 0.1, // 0.1-0.4
        hue: Math.random() * 10 + 35, // Warm gold: 35-45
        life: 0,
        maxLife: Math.random() * 400 + 400, // 400-800
      });
    }

    // Initial particles
    for (let i = 0; i < count; i++) {
      spawnParticle();
      if (particles[i] && canvas) {
        particles[i].y = Math.random() * canvas.height;
        particles[i].life = Math.random() * particles[i].maxLife;
      }
    }

    function animate() {
      if (!ctx || !canvas) return;

      ctx.clearRect(0, 0, canvas.width, canvas.height);

      for (let i = particles.length - 1; i >= 0; i--) {
        const p = particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.life++;

        const lifeRatio = p.life / p.maxLife;
        const fadeOpacity = lifeRatio > 0.7
          ? p.opacity * (1 - (lifeRatio - 0.7) / 0.3)
          : p.opacity;

        // Subtle glow via shadow
        const color = `hsla(${p.hue}, 55%, 65%, ${fadeOpacity})`;
        ctx.shadowBlur = 4;
        ctx.shadowColor = color;

        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
        ctx.fillStyle = color;
        ctx.fill();

        // Reset shadow so it doesn't bleed into other draws
        ctx.shadowBlur = 0;

        if (p.life >= p.maxLife) {
          particles.splice(i, 1);
          spawnParticle();
        }
      }

      animationId = requestAnimationFrame(animate);
    }

    animate();
    window.addEventListener('resize', resize);

    return () => {
      cancelAnimationFrame(animationId);
      window.removeEventListener('resize', resize);
    };
  }, [count]);

  return (
    <canvas
      ref={canvasRef}
      aria-hidden="true"
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        zIndex: 1,
        pointerEvents: 'none',
      }}
    />
  );
}
