'use client';

import CountUp from 'react-countup';
import { useInView } from 'react-intersection-observer';

interface AnimatedCounterProps {
  end: number;
  suffix?: string;
  prefix?: string;
  decimals?: number;
  duration?: number;
}

export function AnimatedCounter({
  end,
  suffix = '',
  prefix = '',
  decimals = 0,
  duration = 2.5,
}: AnimatedCounterProps) {
  const { ref, inView } = useInView({ triggerOnce: true, threshold: 0.3 });

  return (
    <span ref={ref}>
      {inView ? (
        <CountUp
          end={end}
          suffix={suffix}
          prefix={prefix}
          decimals={decimals}
          duration={duration}
          separator=","
        />
      ) : (
        <span>0{suffix}</span>
      )}
    </span>
  );
}
