'use client';

import { motion, AnimatePresence } from 'framer-motion';
import { useEffect, useState, useCallback } from 'react';

interface Toast {
  id: number;
  title: string;
  description: string;
  icon: string;
}

let toastId = 0;
const listeners: Set<(toast: Toast) => void> = new Set();

export function showAchievement(toast: Omit<Toast, 'id'>) {
  const newToast = { ...toast, id: ++toastId };
  listeners.forEach((fn) => fn(newToast));
}

const toastVariants = {
  hidden: {
    y: -80,
    opacity: 0,
  },
  visible: {
    y: 0,
    opacity: 1,
    transition: {
      duration: 0.5,
      ease: [0.25, 0.1, 0.25, 1] as const,
    },
  },
  exit: {
    y: -40,
    opacity: 0,
    transition: {
      duration: 0.3,
      ease: [0.25, 0.1, 0.25, 1] as const,
    },
  },
} as const;

export function AchievementToastContainer() {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const addToast = useCallback((toast: Toast) => {
    setToasts((prev) => [...prev, toast]);
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== toast.id));
    }, 3500);
  }, []);

  useEffect(() => {
    listeners.add(addToast);
    return () => { listeners.delete(addToast); };
  }, [addToast]);

  return (
    <div
      style={{
        position: 'fixed',
        top: '1.5rem',
        left: '50%',
        transform: 'translateX(-50%)',
        zIndex: 200,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: '0.75rem',
      }}
    >
      <AnimatePresence>
        {toasts.map((toast) => (
          <motion.div
            key={toast.id}
            variants={toastVariants}
            initial="hidden"
            animate="visible"
            exit="exit"
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.75rem',
              background: 'linear-gradient(180deg, #2d2820 0%, #1a1814 100%)',
              border: '2px solid #8B7340',
              borderRadius: '4px',
              boxShadow: '0 4px 20px rgba(0,0,0,0.8), inset 0 1px 0 rgba(201,170,113,0.1)',
              padding: '0.75rem 1.25rem',
              minWidth: '280px',
            }}
          >
            <div
              style={{
                width: '2.5rem',
                height: '2.5rem',
                borderRadius: '50%',
                border: '2px solid #8B7340',
                background: '#231f1a',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '1.25rem',
                flexShrink: 0,
              }}
            >
              {toast.icon}
            </div>
            <div>
              <h4
                style={{
                  fontFamily: 'Cinzel, serif',
                  color: '#C9AA71',
                  fontSize: '0.85rem',
                  margin: 0,
                  lineHeight: 1.3,
                }}
              >
                {toast.title}
              </h4>
              <p
                style={{
                  color: '#a89b80',
                  fontSize: '0.75rem',
                  margin: '0.15rem 0 0 0',
                  lineHeight: 1.3,
                }}
              >
                {toast.description}
              </p>
            </div>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}
