'use client';

import { useEffect, useRef } from 'react';

interface Star {
  x: number;
  y: number;
  baseOpacity: number;
  size: number;
  driftX: number;
  driftY: number;
  hue: number;
  twinkleOffset: number;
}

export function StarfieldCanvas() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let animationId: number;
    let time = 0;

    const resize = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };
    resize();

    const starCount = 200;
    const speed = 0.15;
    const stars: Star[] = [];

    for (let i = 0; i < starCount; i++) {
      stars.push({
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height,
        baseOpacity: Math.random() * 0.3 + 0.1,
        size: Math.random() * 1.5 + 0.5,
        driftX: (Math.random() - 0.5) * speed,
        driftY: (Math.random() - 0.5) * speed * 0.5,
        hue: Math.random() * 15 + 30, // Warm amber/gold range: 30-45
        twinkleOffset: Math.random() * Math.PI * 2,
      });
    }

    function animate() {
      if (!ctx || !canvas) return;

      time += 0.01;

      // Warm near-black clear
      ctx.fillStyle = 'rgba(13, 12, 10, 0.08)';
      ctx.fillRect(0, 0, canvas.width, canvas.height);

      for (let i = 0; i < stars.length; i++) {
        const star = stars[i];

        // Gentle drift
        star.x += star.driftX;
        star.y += star.driftY;

        // Wrap around edges
        if (star.x < 0) star.x = canvas.width;
        if (star.x > canvas.width) star.x = 0;
        if (star.y < 0) star.y = canvas.height;
        if (star.y > canvas.height) star.y = 0;

        // Subtle twinkle: oscillate opacity gently
        const twinkle = Math.sin(time * 1.5 + star.twinkleOffset) * 0.5 + 0.5;
        const opacity = star.baseOpacity * (0.5 + twinkle * 0.5) * 0.5;

        const lightness = 60 + twinkle * 20;

        ctx.beginPath();
        ctx.arc(star.x, star.y, star.size, 0, Math.PI * 2);
        ctx.fillStyle = `hsla(${star.hue}, 60%, ${lightness}%, ${opacity})`;
        ctx.fill();
      }

      animationId = requestAnimationFrame(animate);
    }

    animate();
    window.addEventListener('resize', resize);

    return () => {
      cancelAnimationFrame(animationId);
      window.removeEventListener('resize', resize);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="starfield-canvas"
      aria-hidden="true"
    />
  );
}
