'use client';

export function SectionDivider({ className = '' }: { className?: string }) {
  return (
    <div
      className={`section-divider ${className}`}
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '1rem',
        padding: '0.5rem 0',
        opacity: 0.5,
      }}
    >
      <div
        style={{
          flex: 1,
          maxWidth: '120px',
          height: '1px',
          background: 'linear-gradient(90deg, transparent, #6b5635)',
        }}
      />
      <svg
        width="18"
        height="18"
        viewBox="0 0 18 18"
        fill="none"
        style={{ flexShrink: 0 }}
      >
        <path
          d="M9 1L11 7H17L12 10.5L14 17L9 13L4 17L6 10.5L1 7H7L9 1Z"
          fill="none"
          stroke="#8B7340"
          strokeWidth="1"
        />
      </svg>
      <div
        style={{
          flex: 1,
          maxWidth: '120px',
          height: '1px',
          background: 'linear-gradient(270deg, transparent, #6b5635)',
        }}
      />
    </div>
  );
}
