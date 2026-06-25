// EduGuard AI — Sprint 5 Module A: Configuration Center
// /frontend/src/pages/admin/ConfigurationCenter.tsx
// v5.0 — Full settings management with audit history and rollback

import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';

const API = '/api/v2/sprint5/config';

interface Category { id: number; key: string; label: string; description?: string; icon?: string; }
interface Setting  { id: number; key: string; label: string; description?: string; data_type: string; current_value?: string; default_value?: string; is_required: boolean; }
interface AuditEntry { id: number; setting_key: string; old_value?: string; new_value?: string; change_reason?: string; created_at: string; }

export default function ConfigurationCenter() {
  const { token } = useAuth();
  const [categories, setCategories] = useState<Category[]>([]);
  const [selectedCat, setSelectedCat] = useState<string>('academic_rules');
  const [settings, setSettings]   = useState<Setting[]>([]);
  const [edits, setEdits]          = useState<Record<string, string>>({});
  const [reasons, setReasons]      = useState<Record<string, string>>({});
  const [audit, setAudit]          = useState<AuditEntry[]>([]);
  const [auditKey, setAuditKey]    = useState<string | null>(null);
  const [saving, setSaving]        = useState(false);
  const [msg, setMsg]              = useState<{ type: 'success'|'error'; text: string } | null>(null);

  const hdr = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

  useEffect(() => {
    fetch(`${API}/categories`, { headers: hdr })
      .then(r => r.json()).then(setCategories).catch(() => {});
  }, []);

  useEffect(() => {
    if (!selectedCat) return;
    fetch(`${API}/categories/${selectedCat}`, { headers: hdr })
      .then(r => r.json()).then(d => { setSettings(d.settings || []); setEdits({}); })
      .catch(() => {});
  }, [selectedCat]);

  const handleChange = (key: string, val: string) =>
    setEdits(e => ({ ...e, [key]: val }));

  const handleReasonChange = (key: string, val: string) =>
    setReasons(r => ({ ...r, [key]: val }));

  const saveAll = async () => {
    setSaving(true); setMsg(null);
    const updates = Object.entries(edits).map(([key, value]) => ({
      key, value, reason: reasons[key] || undefined,
    }));
    if (!updates.length) { setSaving(false); setMsg({ type: 'error', text: 'No changes to save.' }); return; }
    try {
      const r = await fetch(`${API}/settings`, {
        method: 'PUT', headers: hdr,
        body: JSON.stringify({ updates }),
      });
      if (r.ok) {
        setMsg({ type: 'success', text: `${updates.length} setting(s) saved successfully.` });
        setEdits({}); setReasons({});
        // Refresh
        const d = await fetch(`${API}/categories/${selectedCat}`, { headers: hdr }).then(r => r.json());
        setSettings(d.settings || []);
      } else {
        setMsg({ type: 'error', text: 'Failed to save settings.' });
      }
    } catch { setMsg({ type: 'error', text: 'Network error.' }); }
    setSaving(false);
  };

  const loadAudit = async (key: string) => {
    setAuditKey(key);
    const data = await fetch(`${API}/settings/${key}/audit`, { headers: hdr }).then(r => r.json());
    setAudit(Array.isArray(data) ? data : []);
  };

  const rollback = async (auditId: number, settingKey: string) => {
    if (!window.confirm('Rollback this setting to its previous value?')) return;
    await fetch(`${API}/settings/${settingKey}/rollback/${auditId}`, { method: 'POST', headers: hdr });
    const d = await fetch(`${API}/categories/${selectedCat}`, { headers: hdr }).then(r => r.json());
    setSettings(d.settings || []);
    setMsg({ type: 'success', text: 'Setting rolled back.' });
    setAudit([]); setAuditKey(null);
  };

  const catIcons: Record<string, string> = {
    academic_rules: '📚', risk_thresholds: '⚠️', graduation_rules: '🎓',
    dismissal_rules: '🚫', notification_settings: '🔔', workflow_settings: '🔀',
    student_success: '📈', calendar_settings: '📅', retention_settings: '👥',
    escalation_rules: '⬆️', semester_rules: '🗓️', alert_settings: '🚨',
  };

  const renderInput = (s: Setting) => {
    const val = edits[s.key] !== undefined ? edits[s.key] : (s.current_value ?? s.default_value ?? '');
    const changed = edits[s.key] !== undefined;

    if (s.data_type === 'boolean') {
      return (
        <select
          value={val}
          onChange={e => handleChange(s.key, e.target.value)}
          className={`border rounded px-2 py-1 text-sm ${changed ? 'border-blue-400 bg-blue-50' : 'border-gray-300'}`}
        >
          <option value="true">True</option>
          <option value="false">False</option>
        </select>
      );
    }
    return (
      <input
        type={s.data_type === 'integer' || s.data_type === 'decimal' ? 'number' : 'text'}
        value={val}
        onChange={e => handleChange(s.key, e.target.value)}
        className={`border rounded px-2 py-1 text-sm w-32 ${changed ? 'border-blue-400 bg-blue-50' : 'border-gray-300'}`}
        step={s.data_type === 'decimal' ? '0.01' : '1'}
      />
    );
  };

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-gray-900">⚙️ Configuration Center</h1>
          <p className="text-gray-500 text-sm mt-1">
            Manage all academic rules, thresholds, and platform settings.
            All values are stored in the database — no hardcoded configuration.
          </p>
        </div>

        {msg && (
          <div className={`mb-4 p-3 rounded text-sm ${msg.type === 'success' ? 'bg-green-50 text-green-700 border border-green-200' : 'bg-red-50 text-red-700 border border-red-200'}`}>
            {msg.text}
          </div>
        )}

        <div className="flex gap-6">
          {/* Sidebar */}
          <div className="w-64 shrink-0">
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
              {categories.map(cat => (
                <button
                  key={cat.key}
                  onClick={() => setSelectedCat(cat.key)}
                  className={`w-full text-left px-4 py-3 text-sm flex items-center gap-2 border-b border-gray-100 transition-colors ${
                    selectedCat === cat.key
                      ? 'bg-blue-50 text-blue-700 font-medium border-l-4 border-l-blue-500'
                      : 'text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <span>{catIcons[cat.key] || '🔧'}</span>
                  <span>{cat.label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Main Content */}
          <div className="flex-1">
            {/* Settings Table */}
            <div className="bg-white rounded-lg shadow-sm border border-gray-200">
              <div className="px-5 py-4 border-b border-gray-200 flex justify-between items-center">
                <div>
                  <h2 className="font-semibold text-gray-900">
                    {categories.find(c => c.key === selectedCat)?.label || 'Settings'}
                  </h2>
                  <p className="text-xs text-gray-500 mt-0.5">
                    {categories.find(c => c.key === selectedCat)?.description}
                  </p>
                </div>
                <div className="flex gap-2">
                  {Object.keys(edits).length > 0 && (
                    <span className="text-xs bg-yellow-100 text-yellow-700 px-2 py-1 rounded-full">
                      {Object.keys(edits).length} unsaved change(s)
                    </span>
                  )}
                  <button
                    onClick={saveAll}
                    disabled={saving || Object.keys(edits).length === 0}
                    className="bg-blue-600 text-white text-sm px-4 py-1.5 rounded hover:bg-blue-700 disabled:opacity-40 transition"
                  >
                    {saving ? 'Saving…' : '💾 Save Changes'}
                  </button>
                </div>
              </div>

              <div className="divide-y divide-gray-100">
                {settings.length === 0 ? (
                  <div className="p-8 text-center text-gray-400 text-sm">No settings in this category.</div>
                ) : settings.map(s => (
                  <div key={s.key} className="px-5 py-4 hover:bg-gray-50 transition-colors">
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium text-gray-900">{s.label}</span>
                          {s.is_required && (
                            <span className="text-xs bg-red-50 text-red-600 px-1.5 py-0.5 rounded">Required</span>
                          )}
                          <span className="text-xs text-gray-400 font-mono">{s.key}</span>
                        </div>
                        {s.description && (
                          <p className="text-xs text-gray-500 mt-0.5">{s.description}</p>
                        )}
                        {s.default_value && (
                          <p className="text-xs text-gray-400 mt-0.5">Default: <code>{s.default_value}</code></p>
                        )}
                      </div>
                      <div className="flex flex-col gap-2 items-end">
                        {renderInput(s)}
                        {edits[s.key] !== undefined && (
                          <input
                            type="text"
                            placeholder="Reason for change…"
                            value={reasons[s.key] || ''}
                            onChange={e => handleReasonChange(s.key, e.target.value)}
                            className="border border-gray-300 rounded px-2 py-1 text-xs w-48"
                          />
                        )}
                        <button
                          onClick={() => loadAudit(s.key)}
                          className="text-xs text-blue-500 hover:underline"
                        >
                          Audit History
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Audit Panel */}
            {auditKey && (
              <div className="mt-4 bg-white rounded-lg shadow-sm border border-gray-200">
                <div className="px-5 py-3 border-b border-gray-200 flex justify-between">
                  <h3 className="font-semibold text-sm text-gray-900">
                    Audit History — <code className="text-blue-600">{auditKey}</code>
                  </h3>
                  <button onClick={() => { setAuditKey(null); setAudit([]); }}
                    className="text-gray-400 hover:text-gray-600 text-lg leading-none">×</button>
                </div>
                <div className="divide-y divide-gray-100 max-h-64 overflow-y-auto">
                  {audit.length === 0 ? (
                    <p className="text-sm text-gray-400 p-4">No audit history.</p>
                  ) : audit.map(a => (
                    <div key={a.id} className="px-5 py-3 text-xs flex items-center justify-between">
                      <div>
                        <span className="text-gray-500">{new Date(a.created_at).toLocaleString()}</span>
                        <span className="mx-2 text-gray-400">→</span>
                        <span className="text-red-500 line-through mr-2">{a.old_value || '(empty)'}</span>
                        <span className="text-green-600 font-medium">{a.new_value || '(empty)'}</span>
                        {a.change_reason && (
                          <span className="ml-2 text-gray-400 italic">"{a.change_reason}"</span>
                        )}
                      </div>
                      <button
                        onClick={() => rollback(a.id, auditKey)}
                        className="text-xs text-orange-500 hover:underline ml-4"
                      >
                        ↩ Rollback
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
