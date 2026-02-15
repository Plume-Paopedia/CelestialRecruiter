'use client';

import { useState, useRef, useEffect, useCallback } from 'react';
import { usePatch } from '@/components/dashboard/PatchContext';

interface ExportPatchModalProps {
  onClose: () => void;
}

export function ExportPatchModal({ onClose }: ExportPatchModalProps) {
  const { dirtySummary, generatePatchString, resetAll } = usePatch();
  const [patchString, setPatchString] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    const str = generatePatchString();
    setPatchString(str);
  }, [generatePatchString]);

  const handleCopy = useCallback(async () => {
    if (!patchString) return;
    try {
      await navigator.clipboard.writeText(patchString);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Fallback: select text
      textareaRef.current?.select();
    }
  }, [patchString]);

  const handleReset = useCallback(() => {
    resetAll();
    onClose();
  }, [resetAll, onClose]);

  // Close on ESC
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [onClose]);

  const sizeKB = patchString ? (patchString.length / 1024).toFixed(1) : '0';

  return (
    <div className="export-modal-overlay" onClick={onClose}>
      <div className="export-modal" onClick={(e) => e.stopPropagation()}>
        {/* Header */}
        <div className="export-modal-header">
          <h2>Export Changes</h2>
          <button className="template-delete-btn" onClick={onClose}>{'\u2716'}</button>
        </div>

        {/* Summary */}
        <div className="export-modal-summary">
          <div className="export-modal-summary-title">Changes Summary</div>
          <div className="export-modal-summary-items">
            {dirtySummary.templates > 0 && (
              <div className="export-summary-item">
                <span className="export-summary-icon">{'\u2637'}</span>
                {dirtySummary.templates} templates
              </div>
            )}
            {dirtySummary.settings > 0 && (
              <div className="export-summary-item">
                <span className="export-summary-icon">{'\u2699'}</span>
                {dirtySummary.settings} settings
              </div>
            )}
            {dirtySummary.blacklist > 0 && (
              <div className="export-summary-item">
                <span className="export-summary-icon">{'\u26D4'}</span>
                {dirtySummary.blacklist} blacklist entries
              </div>
            )}
          </div>
        </div>

        {/* Patch string */}
        <div className="export-modal-patch">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
            <span style={{ fontSize: '0.72rem', color: '#6b5f4d', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
              Lua Patch String
            </span>
            <span style={{ fontSize: '0.65rem', color: '#6b5f4d' }}>
              {sizeKB} KB
            </span>
          </div>
          <textarea
            ref={textareaRef}
            className="export-patch-textarea"
            value={patchString || ''}
            readOnly
            rows={10}
            onFocus={(e) => e.target.select()}
            spellCheck={false}
          />
        </div>

        {/* Actions */}
        <div className="export-modal-actions">
          <button
            className={`export-copy-btn ${copied ? 'copied' : ''}`}
            onClick={handleCopy}
          >
            {copied ? 'Copied!' : 'Copy to Clipboard'}
          </button>
          <button
            className="export-reset-btn"
            onClick={handleReset}
          >
            Revert All Changes
          </button>
        </div>

        {/* Instructions */}
        <div className="export-modal-instructions">
          Copiez ce texte et utilisez <code>/cr webimport</code> en jeu pour appliquer les modifications.
        </div>
      </div>
    </div>
  );
}
