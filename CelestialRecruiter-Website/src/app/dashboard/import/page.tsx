'use client';

import { useState } from 'react';
import { TierProvider } from '@/components/dashboard/TierContext';
import { DataProvider, useData } from '@/components/dashboard/DataContext';
import type { ImportResult } from '@/components/dashboard/DataContext';

function timeAgo(isoString: string): string {
  const diff = Date.now() - new Date(isoString).getTime();
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return 'just now';
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

function ImportContent() {
  const { data, isLive, importData, clearData, lastImport } = useData();
  const [input, setInput] = useState('');
  const [result, setResult] = useState<ImportResult | null>(null);
  const [loading, setLoading] = useState(false);

  const handleImport = () => {
    setLoading(true);
    // Small delay for UX feedback
    setTimeout(() => {
      const res = importData(input.trim());
      setResult(res);
      if (res.success) setInput('');
      setLoading(false);
    }, 300);
  };

  const handleClear = () => {
    clearData();
    setResult(null);
    setInput('');
  };

  return (
    <div className="import-page">
      {/* Header */}
      <div className="import-header">
        <a href="/dashboard" className="import-back-link">
          {'\u2190'} Dashboard
        </a>
        <h1>Import Your Data</h1>
        <p>
          Connect your in-game CelestialRecruiter data to this dashboard.
          Export from the addon, paste below, and see your real recruitment stats.
        </p>
      </div>

      {/* Current data status */}
      {isLive && data && (
        <div className="import-status-card live">
          <div className="status-indicator">
            <span className="status-dot live" />
            Live Data Active
          </div>
          <div className="status-details">
            <div className="status-row">
              <span>Character</span>
              <span className="status-value">{data.character || 'Unknown'} - {data.realm || 'Unknown'}</span>
            </div>
            <div className="status-row">
              <span>Contacts</span>
              <span className="status-value">{Object.keys(data.contacts).length}</span>
            </div>
            <div className="status-row">
              <span>Templates</span>
              <span className="status-value">{data.templates ? Object.keys(data.templates).length : 0}</span>
            </div>
            <div className="status-row">
              <span>Last Import</span>
              <span className="status-value">{lastImport ? timeAgo(lastImport) : 'Unknown'}</span>
            </div>
          </div>
          <button className="import-clear-btn" onClick={handleClear}>
            Clear Data & Revert to Demo
          </button>
        </div>
      )}

      {/* Instructions */}
      <div className="import-instructions">
        <div className="instructions-title">
          {'\u2139'} How to Export
        </div>
        <div className="import-steps">
          <div className="step">
            <div className="step-number">1</div>
            <div className="step-content">
              <div className="step-title">Open CelestialRecruiter in WoW</div>
              <div className="step-desc">Type <code>/cr</code> or click the minimap button</div>
            </div>
          </div>
          <div className="step">
            <div className="step-number">2</div>
            <div className="step-content">
              <div className="step-title">Run the Web Export</div>
              <div className="step-desc">Type <code>/cr webexport</code> in chat — a window will open with your data</div>
            </div>
          </div>
          <div className="step">
            <div className="step-number">3</div>
            <div className="step-content">
              <div className="step-title">Copy the Text</div>
              <div className="step-desc">The text is auto-selected. Just press <code>Ctrl+C</code> to copy</div>
            </div>
          </div>
          <div className="step">
            <div className="step-number">4</div>
            <div className="step-content">
              <div className="step-title">Paste Below</div>
              <div className="step-desc">Paste the exported data into the text area and click Import</div>
            </div>
          </div>
        </div>
      </div>

      {/* Import textarea */}
      <div className="import-input-section">
        <label className="import-label">Paste Exported Data</label>
        <textarea
          className="import-textarea"
          value={input}
          onChange={(e) => {
            setInput(e.target.value);
            setResult(null);
          }}
          placeholder={'{\n  ["version"] = "web-1.0",\n  ["contacts"] = {\n    ...\n  },\n}'}
          rows={12}
          spellCheck={false}
        />
        <div className="import-actions">
          <button
            className="import-btn"
            onClick={handleImport}
            disabled={!input.trim() || loading}
          >
            {loading ? 'Parsing...' : 'Import Data'}
          </button>
          {input && (
            <span className="import-size">
              {(input.length / 1024).toFixed(1)} KB
            </span>
          )}
        </div>
      </div>

      {/* Result feedback */}
      {result && (
        <div className={`import-result ${result.success ? 'success' : 'error'}`}>
          {result.success ? (
            <>
              <div className="result-icon">{'\u2714'}</div>
              <div className="result-content">
                <div className="result-title">Import Successful</div>
                <div className="result-details">
                  {result.summary && (
                    <ul>
                      <li>{result.summary.contacts} contacts loaded</li>
                      <li>{result.summary.templates} templates loaded</li>
                      {result.summary.hasStatistics && <li>Statistics data loaded</li>}
                      {result.summary.hasSettings && <li>Settings loaded</li>}
                      {result.summary.character && (
                        <li>Character: {result.summary.character} ({result.summary.realm})</li>
                      )}
                    </ul>
                  )}
                  <a href="/dashboard" className="result-link">
                    Go to Dashboard {'\u2192'}
                  </a>
                </div>
              </div>
            </>
          ) : (
            <>
              <div className="result-icon">{'\u2716'}</div>
              <div className="result-content">
                <div className="result-title">Import Failed</div>
                <div className="result-error">{result.error}</div>
              </div>
            </>
          )}
        </div>
      )}

      {/* Privacy note */}
      <div className="import-privacy">
        <strong>Privacy:</strong> Your data is stored locally in your browser (localStorage).
        It never leaves your device and is not sent to any server.
        Clear it at any time with the button above.
      </div>
    </div>
  );
}

export default function ImportPage() {
  return (
    <TierProvider defaultTier="pro">
      <DataProvider>
        <ImportContent />
      </DataProvider>
    </TierProvider>
  );
}
