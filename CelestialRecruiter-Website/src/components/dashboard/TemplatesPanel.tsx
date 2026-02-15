'use client';

import { useMemo, useState, useRef, useEffect, useCallback } from 'react';
import { useData } from '@/components/dashboard/DataContext';
import { usePatch } from '@/components/dashboard/PatchContext';

const TEMPLATE_VARIABLES = [
  { token: '{name}', desc: 'Player name' },
  { token: '{class}', desc: 'Player class' },
  { token: '{level}', desc: 'Player level' },
  { token: '{guild}', desc: 'Guild name' },
  { token: '{discord}', desc: 'Discord link' },
  { token: '{raidDays}', desc: 'Raid schedule' },
  { token: '{goal}', desc: 'Recruitment goal' },
  { token: '{inviteKeyword}', desc: 'Invite keyword' },
];

const BUILTIN_TEMPLATES = ['default', 'raid', 'short'];
const MAX_TEMPLATE_LENGTH = 500;

function renderTemplateText(text: string) {
  const parts = text.split(/(\{[^}]+\})/g);
  return parts.map((part, i) => {
    if (part.startsWith('{') && part.endsWith('}')) {
      return <span key={i} className="template-var">{part}</span>;
    }
    return <span key={i}>{part.replace(/</g, '\u2039').replace(/>/g, '\u203A')}</span>;
  });
}

export function TemplatesPanel() {
  const { data, isLive } = useData();
  const { editedTemplates, setEditedTemplates, dirtySummary } = usePatch();

  const [newTemplateName, setNewTemplateName] = useState('');
  const [showAddForm, setShowAddForm] = useState(false);
  const textareaRefs = useRef<Record<string, HTMLTextAreaElement | null>>({});

  // Current templates: edited version or original from data
  const templates = useMemo(() => {
    return editedTemplates || data?.templates || {};
  }, [data, editedTemplates]);

  // Initialize edited state from data when live
  useEffect(() => {
    if (isLive && data?.templates && !editedTemplates) {
      setEditedTemplates({ ...data.templates });
    }
  }, [isLive, data?.templates, editedTemplates, setEditedTemplates]);

  const templateEntries = Object.entries(templates);
  const isDirty = dirtySummary.templates > 0;

  const updateTemplate = useCallback((id: string, text: string) => {
    const updated = { ...templates, [id]: text };
    setEditedTemplates(updated);
  }, [templates, setEditedTemplates]);

  const deleteTemplate = useCallback((id: string) => {
    const updated = { ...templates };
    delete updated[id];
    setEditedTemplates(updated);
  }, [templates, setEditedTemplates]);

  const addTemplate = useCallback(() => {
    const name = newTemplateName.trim();
    if (!name || templates[name]) return;
    const updated = { ...templates, [name]: '' };
    setEditedTemplates(updated);
    setNewTemplateName('');
    setShowAddForm(false);
  }, [newTemplateName, templates, setEditedTemplates]);

  const insertVariable = useCallback((templateId: string, token: string) => {
    const textarea = textareaRefs.current[templateId];
    if (!textarea) return;
    const start = textarea.selectionStart;
    const end = textarea.selectionEnd;
    const current = templates[templateId] || '';
    const updated = current.substring(0, start) + token + current.substring(end);
    updateTemplate(templateId, updated);
    // Restore cursor position after React re-render
    setTimeout(() => {
      if (textareaRefs.current[templateId]) {
        const pos = start + token.length;
        textareaRefs.current[templateId]!.setSelectionRange(pos, pos);
        textareaRefs.current[templateId]!.focus();
      }
    }, 0);
  }, [templates, updateTemplate]);

  return (
    <div>
      <div className="panel-card">
        <div className="panel-title">
          <span className="panel-icon">{'\u2637'}</span>
          Message Templates
          {isLive && (
            <span style={{ marginLeft: '0.5rem', fontSize: '0.65rem', color: '#4ade80', fontWeight: 400 }}>
              ({templateEntries.length} from addon)
            </span>
          )}
          {isDirty && <span className="dirty-dot" />}
        </div>

        {templateEntries.length === 0 && (
          <div style={{ textAlign: 'center', padding: '2rem', color: '#6b5f4d', fontSize: '0.82rem' }}>
            No templates. Import your addon data to manage templates.
          </div>
        )}

        {templateEntries.map(([name, text]) => {
          const isBuiltin = BUILTIN_TEMPLATES.includes(name);
          const charCount = text.length;
          const isWarning = charCount > 450;
          const isOver = charCount > MAX_TEMPLATE_LENGTH;

          return (
            <div key={name} style={{ marginBottom: '1.25rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                <span style={{ fontSize: '0.82rem', fontWeight: 600, color: '#d4c5a9' }}>
                  {name}
                  {isBuiltin && (
                    <span style={{ marginLeft: '0.4rem', fontSize: '0.6rem', color: '#6b5f4d', fontWeight: 400 }}>
                      (built-in)
                    </span>
                  )}
                </span>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  {isLive && (
                    <span style={{
                      fontSize: '0.65rem',
                      color: isOver ? '#e74c3c' : isWarning ? '#C9AA71' : '#6b5f4d',
                    }}>
                      {charCount}/{MAX_TEMPLATE_LENGTH}
                    </span>
                  )}
                  {isLive && !isBuiltin && (
                    <button
                      className="template-delete-btn"
                      onClick={() => deleteTemplate(name)}
                      title="Delete template"
                    >
                      {'\u2716'}
                    </button>
                  )}
                </div>
              </div>

              {isLive ? (
                <textarea
                  ref={(el) => { textareaRefs.current[name] = el; }}
                  className="template-edit-textarea"
                  value={text}
                  onChange={(e) => updateTemplate(name, e.target.value)}
                  rows={3}
                  maxLength={MAX_TEMPLATE_LENGTH}
                  spellCheck={false}
                  placeholder="Write your recruitment message..."
                />
              ) : (
                <div className="template-editor">
                  {renderTemplateText(text)}
                </div>
              )}
            </div>
          );
        })}

        {/* Add template button (live only) */}
        {isLive && (
          <div style={{ marginBottom: '1rem' }}>
            {showAddForm ? (
              <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                <input
                  type="text"
                  className="settings-input"
                  value={newTemplateName}
                  onChange={(e) => setNewTemplateName(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && addTemplate()}
                  placeholder="Template name..."
                  style={{ flex: 1 }}
                  autoFocus
                />
                <button
                  className="template-add-btn"
                  onClick={addTemplate}
                  disabled={!newTemplateName.trim() || !!templates[newTemplateName.trim()]}
                >
                  Add
                </button>
                <button
                  className="template-delete-btn"
                  onClick={() => { setShowAddForm(false); setNewTemplateName(''); }}
                >
                  {'\u2716'}
                </button>
              </div>
            ) : (
              <button
                className="template-add-btn"
                onClick={() => setShowAddForm(true)}
              >
                + Add Template
              </button>
            )}
          </div>
        )}

        {/* A/B Variant removed - no showcase data */}

        {/* Variables reference / insertion chips */}
        <div style={{
          padding: '0.75rem', background: '#211d18', borderRadius: 3,
          border: '1px solid #2a2318',
        }}>
          <div style={{
            fontSize: '0.72rem', fontWeight: 600, color: '#6b5f4d', marginBottom: '0.5rem',
            textTransform: 'uppercase', letterSpacing: '0.06em',
          }}>
            {isLive ? 'Click to Insert Variable' : 'Available Variables'}
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.4rem' }}>
            {TEMPLATE_VARIABLES.map((v) => (
              <span
                key={v.token}
                className={isLive ? 'template-var-chip clickable' : 'template-var-chip'}
                title={v.desc}
                onClick={isLive ? () => {
                  // Insert into the last focused template
                  const focused = document.activeElement;
                  if (focused && focused.tagName === 'TEXTAREA') {
                    const id = templateEntries.find(([, ]) => textareaRefs.current[templateEntries[0]?.[0]] === focused)?.[0];
                    if (id) insertVariable(id, v.token);
                  }
                } : undefined}
              >
                {v.token}
              </span>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
