// EduGuard AI — Sprint 5 Module F: Seed Data Generator
// /frontend/src/pages/admin/SeedDataManager.tsx
// v5.0

import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';

const API = '/api/v2/sprint5/seed-data';

interface Batch { id: number; batch_key: string; label?: string; student_count: number; status: string; created_at: string; deleted_at?: string; }

export default function SeedDataManager() {
  const { token } = useAuth();
  const [batches, setBatches] = useState<Batch[]>([]);
  const [loading, setLoading] = useState(true);
  const [generating, setGenerating] = useState(false);
  const [deleting, setDeleting] = useState<number | null>(null);
  const [form, setForm] = useState({ label: '', description: '', student_count: 100 });
  const [showForm, setShowForm] = useState(false);
  const [msg, setMsg] = useState<{ type: 'success'|'error'; text: string } | null>(null);

  const hdr = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

  const load = async () => {
    setLoading(true);
    try {
      const d = await fetch(`${API}/batches`, { headers: hdr }).then(r => r.json());
      setBatches(Array.isArray(d) ? d : []);
    } catch {}
    setLoading(false);
  };

  useEffect(() => { load(); }, []);

  const generate = async () => {
    if (form.student_count < 1 || form.student_count > 500) {
      setMsg({ type: 'error', text: 'Student count must be between 1 and 500.' });
      return;
    }
    setGenerating(true);
    setMsg(null);
    try {
      const r = await fetch(`${API}/batches`, {
        method: 'POST', headers: hdr,
        body: JSON.stringify(form),
      });
      if (r.ok) {
        const batch = await r.json();
        setMsg({ type: 'success', text: `✓ Generated ${batch.student_count} students in batch "${batch.batch_key}"` });
        setShowForm(false);
        setForm({ label: '', description: '', student_count: 100 });
        await load();
      } else {
        const err = await r.json().catch(() => ({}));
        setMsg({ type: 'error', text: err.detail || 'Failed to generate seed data.' });
      }
    } catch {
      setMsg({ type: 'error', text: 'Network error.' });
    }
    setGenerating(false);
  };

  const deleteBatch = async (id: number, key: string) => {
    if (!window.confirm(
      `⚠️ Delete batch "${key}"?\n\nThis will permanently remove all generated students, users, course attempts, and term GPAs. This cannot be undone.`
    )) return;
    setDeleting(id);
    try {
      const r = await fetch(`${API}/batches/${id}`, { method: 'DELETE', headers: hdr });
      const result = await r.json();
      setMsg({ type: 'success', text: result.message || 'Batch deleted.' });
      await load();
    } catch {
      setMsg({ type: 'error', text: 'Failed to delete batch.' });
    }
    setDeleting(null);
  };

  const statusColor = (s: string) => ({
    completed: 'bg-green-100 text-green-700',
    in_progress: 'bg-blue-100 text-blue-700',
    deleted: 'bg-gray-100 text-gray-400',
    failed: 'bg-red-100 text-red-600',
  }[s] || 'bg-gray-100 text-gray-600');

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-5xl mx-auto">
        <div className="mb-6 flex justify-between items-start">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">🧪 Seed Data Generator</h1>
            <p className="text-gray-500 text-sm mt-1">
              Generate realistic student data for testing. Each batch is tracked and can be safely deleted
              before importing real university data.
            </p>
          </div>
          <button onClick={() => setShowForm(!showForm)}
            className="bg-blue-600 text-white text-sm px-4 py-2 rounded hover:bg-blue-700">
            {showForm ? 'Cancel' : '+ Generate Batch'}
          </button>
        </div>

        {msg && (
          <div className={`mb-4 p-3 rounded text-sm flex justify-between ${
            msg.type === 'success' ? 'bg-green-50 text-green-700 border border-green-200' : 'bg-red-50 text-red-700 border border-red-200'
          }`}>
            {msg.text}<button onClick={() => setMsg(null)} className="ml-2 opacity-60">×</button>
          </div>
        )}

        {/* Notice */}
        <div className="mb-5 p-4 bg-amber-50 border border-amber-200 rounded-lg text-sm text-amber-800">
          <p className="font-semibold mb-1">⚠️ Important — Seed Data Guidelines</p>
          <ul className="space-y-0.5 text-xs list-disc list-inside">
            <li>Seed data generates realistic students with Arabic names (transliterated), academic histories, and risk scenarios.</li>
            <li>All seed batches are tracked by <code>seed_batch_id</code>.</li>
            <li>Use "Delete Batch" to remove all generated data before importing real university data.</li>
            <li>Maximum 500 students per batch. Generation may take 1–3 minutes.</li>
            <li>Seed data includes: excellent (10%), good (25%), average (30%), at-risk (20%), dismissal-risk (8%), near-graduate (7%) scenarios.</li>
          </ul>
        </div>

        {/* Generation Form */}
        {showForm && (
          <div className="bg-white rounded-lg border border-gray-200 p-5 mb-5">
            <h2 className="font-semibold text-gray-900 mb-4">New Seed Batch</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-medium text-gray-700 block mb-1">Batch Label</label>
                <input type="text" value={form.label}
                  onChange={e => setForm(f => ({ ...f, label: e.target.value }))}
                  placeholder="e.g. CS 2024 Test Dataset"
                  className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
              </div>
              <div>
                <label className="text-xs font-medium text-gray-700 block mb-1">
                  Number of Students (1–500)
                </label>
                <input type="number" min={1} max={500} value={form.student_count}
                  onChange={e => setForm(f => ({ ...f, student_count: parseInt(e.target.value) || 0 }))}
                  className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
              </div>
              <div className="md:col-span-2">
                <label className="text-xs font-medium text-gray-700 block mb-1">Description (optional)</label>
                <textarea rows={2} value={form.description}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  placeholder="Notes about this seed batch…"
                  className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
              </div>
            </div>

            {/* Scenario Preview */}
            <div className="mt-4 grid grid-cols-3 md:grid-cols-6 gap-2">
              {[
                { label: 'Excellent', pct: 10, color: 'bg-emerald-100 text-emerald-700', icon: '⭐' },
                { label: 'Good',      pct: 25, color: 'bg-blue-100 text-blue-700',     icon: '✅' },
                { label: 'Average',   pct: 30, color: 'bg-gray-100 text-gray-700',     icon: '📊' },
                { label: 'At Risk',   pct: 20, color: 'bg-amber-100 text-amber-700',   icon: '⚠️' },
                { label: 'Dismissal', pct: 8,  color: 'bg-red-100 text-red-700',       icon: '🚨' },
                { label: 'Near Grad', pct: 7,  color: 'bg-purple-100 text-purple-700', icon: '🎓' },
              ].map(s => (
                <div key={s.label} className={`rounded-lg p-2 text-center text-xs ${s.color}`}>
                  <p className="text-lg">{s.icon}</p>
                  <p className="font-medium">{s.label}</p>
                  <p className="opacity-70">~{Math.round(form.student_count * s.pct / 100)} students</p>
                </div>
              ))}
            </div>

            <div className="flex gap-3 mt-5 justify-end">
              <button onClick={() => setShowForm(false)}
                className="text-sm px-4 py-2 border border-gray-300 rounded text-gray-700 hover:bg-gray-50">
                Cancel
              </button>
              <button onClick={generate} disabled={generating || form.student_count < 1}
                className="text-sm px-5 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-40 min-w-36">
                {generating ? (
                  <span className="flex items-center gap-2">
                    <span className="animate-spin inline-block w-3 h-3 border-2 border-white border-t-transparent rounded-full" />
                    Generating… (may take a few minutes)
                  </span>
                ) : `Generate ${form.student_count} Students`}
              </button>
            </div>
          </div>
        )}

        {/* Batches Table */}
        <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
          <div className="px-5 py-4 border-b border-gray-200">
            <h2 className="font-semibold text-gray-900 text-sm">
              Seed Batches ({batches.length})
            </h2>
          </div>
          {loading ? (
            <div className="p-8 text-center text-gray-400 text-sm">Loading…</div>
          ) : batches.length === 0 ? (
            <div className="p-8 text-center">
              <p className="text-3xl mb-2">🧪</p>
              <p className="text-gray-400 text-sm">No seed batches yet. Generate your first batch above.</p>
            </div>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-gray-50 text-xs text-gray-500 uppercase">
                  <th className="px-5 py-2 text-left">Batch Key</th>
                  <th className="px-5 py-2 text-left">Label</th>
                  <th className="px-5 py-2 text-right">Students</th>
                  <th className="px-5 py-2 text-center">Status</th>
                  <th className="px-5 py-2 text-left">Created</th>
                  <th className="px-5 py-2 text-center">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {batches.map(b => (
                  <tr key={b.id} className={`hover:bg-gray-50 ${b.status === 'deleted' ? 'opacity-50' : ''}`}>
                    <td className="px-5 py-3 font-mono text-xs text-gray-500">{b.batch_key}</td>
                    <td className="px-5 py-3 text-gray-800">{b.label || '—'}</td>
                    <td className="px-5 py-3 text-right font-semibold text-gray-900">{b.student_count}</td>
                    <td className="px-5 py-3 text-center">
                      <span className={`text-xs px-2 py-0.5 rounded-full ${statusColor(b.status)}`}>
                        {b.status}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-xs text-gray-500">
                      {new Date(b.created_at).toLocaleString()}
                    </td>
                    <td className="px-5 py-3 text-center">
                      {b.status !== 'deleted' && (
                        <button
                          onClick={() => deleteBatch(b.id, b.batch_key)}
                          disabled={deleting === b.id}
                          className="text-xs text-red-500 hover:text-red-700 hover:underline disabled:opacity-40"
                        >
                          {deleting === b.id ? 'Deleting…' : '🗑 Delete Batch'}
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}
