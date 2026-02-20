'use client';

import { useMemo } from 'react';
import { CLASS_COLORS } from '@/lib/constants';
import { useData } from '@/components/dashboard/DataContext';

export function AnalyticsPanel() {
  const { data } = useData();

  const { stats, weeklyData, classDistribution, conversionFunnel } = useMemo(() => {
    const contacts = data ? Object.values(data.contacts) : [];
    const joined = contacts.filter(c => c.status === 'joined').length;
    const contacted = contacts.filter(c => ['contacted', 'invited', 'joined'].includes(c.status)).length;
    const rate = contacted > 0 ? ((joined / contacted) * 100).toFixed(1) : '0';

    // Build class distribution from contacts
    const classCounts: Record<string, number> = {};
    for (const c of contacts) {
      const cls = c.classLabel || c.classFile || 'Unknown';
      classCounts[cls] = (classCounts[cls] || 0) + 1;
    }
    const classDistData = Object.entries(classCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 8)
      .map(([className, count]) => ({
        className,
        count,
        color: CLASS_COLORS[className.toLowerCase().replace(' ', '-')] || '#C9AA71',
      }));

    // Build daily data from statistics.dailyHistory
    const dh = data?.statistics?.dailyHistory || {};
    const days = Object.keys(dh).sort().slice(-7);
    const dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    const wData = days.map(d => {
      const date = new Date(d);
      return {
        day: dayNames[date.getDay()] || d.slice(-2),
        recruits: dh[d]?.joined || 0,
      };
    });

    // Conversion funnel
    const funnel = data?.statistics?.conversionFunnel;
    const scanned = contacts.length;
    const funnelData = [
      { stage: 'Scanned', count: scanned },
      { stage: 'Contacted', count: funnel?.contacted || contacted },
      { stage: 'Invited', count: funnel?.invited || contacts.filter(c => c.status === 'invited' || c.status === 'joined').length },
      { stage: 'Recruited', count: funnel?.joined || joined },
    ];

    // Best day
    let bestDay = '\u2014';
    let bestCount = 0;
    for (const [d, val] of Object.entries(dh)) {
      if ((val.joined || 0) > bestCount) {
        bestCount = val.joined;
        const date = new Date(d);
        bestDay = dayNames[date.getDay()] || d;
      }
    }

    return {
      stats: [
        { label: 'Total Recruits', value: String(joined) },
        { label: 'Conversion Rate', value: `${rate}%` },
        { label: 'Total Contacts', value: String(contacts.length) },
        { label: 'Best Day', value: bestDay },
      ],
      weeklyData: wData,
      classDistribution: classDistData,
      conversionFunnel: funnelData,
    };
  }, [data]);

  const maxRecruits = Math.max(...weeklyData.map((d) => d.recruits), 1);
  const maxClassCount = Math.max(...classDistribution.map((c) => c.count), 1);
  const funnelMax = Math.max(conversionFunnel[0]?.count || 1, 1);

  return (
    <div>
      {/* Stats grid */}
      <div className="stats-grid">
        {stats.map((stat) => (
          <div key={stat.label} className="stat-card">
            <div className="stat-value">{stat.value}</div>
            <div className="stat-label">{stat.label}</div>
          </div>
        ))}
      </div>

      {/* Weekly recruits bar chart */}
      <div className="panel-card">
        <div className="panel-title">
          <span className="panel-icon">{'\u2584'}</span>
          Weekly Recruits
        </div>
        {weeklyData.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '2rem', color: '#6b5f4d', fontSize: '0.82rem' }}>
            No daily history data available.
          </div>
        ) : (
          <div className="bar-chart" style={{ marginBottom: '1.5rem' }}>
            {weeklyData.map((d) => (
              <div
                key={d.day}
                className="bar"
                style={{ height: `${(d.recruits / maxRecruits) * 100}%` }}
              >
                <span className="bar-label">{d.day}</span>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Class distribution */}
      <div className="panel-card">
        <div className="panel-title">
          <span className="panel-icon">{'\u2660'}</span>
          Class Distribution
        </div>
        {classDistribution.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '2rem', color: '#6b5f4d', fontSize: '0.82rem' }}>
            No class data available.
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
            {classDistribution.map((cls) => (
              <div key={cls.className}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.78rem', marginBottom: '0.2rem' }}>
                  <span style={{ color: cls.color, fontWeight: 600 }}>{cls.className}</span>
                  <span style={{ color: '#6b5f4d' }}>{cls.count}</span>
                </div>
                <div
                  style={{
                    width: '100%',
                    height: 6,
                    background: '#211d18',
                    borderRadius: 3,
                    overflow: 'hidden',
                  }}
                >
                  <div
                    style={{
                      width: `${(cls.count / maxClassCount) * 100}%`,
                      height: '100%',
                      background: cls.color,
                      borderRadius: 3,
                      opacity: 0.6,
                      transition: 'width 0.3s ease',
                    }}
                  />
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Conversion funnel */}
      <div className="panel-card">
        <div className="panel-title">
          <span className="panel-icon">{'\u25BD'}</span>
          Conversion Funnel
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', alignItems: 'center' }}>
          {conversionFunnel.map((stage, i) => {
            const widthPercent = (stage.count / funnelMax) * 100;
            const opacity = 1 - i * 0.15;
            return (
              <div
                key={stage.stage}
                style={{
                  width: `${widthPercent}%`,
                  minWidth: '40%',
                  padding: '0.5rem 0.75rem',
                  background: `rgba(201, 170, 113, ${0.08 + i * 0.04})`,
                  border: '1px solid rgba(201, 170, 113, 0.12)',
                  borderRadius: 3,
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  opacity,
                }}
              >
                <span style={{ fontSize: '0.78rem', color: '#d4c5a9' }}>{stage.stage}</span>
                <span style={{ fontSize: '0.82rem', fontWeight: 700, color: '#C9AA71' }}>{stage.count}</span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
