// EduGuard AI — Sprint 5 Module C: Academic Calendar
// /frontend/src/pages/admin/AcademicCalendar.tsx
// v5.0 — Full calendar management with versioning and audit

import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';

const API = '/api/v2/sprint5/calendar';

interface AcademicYear { id: number; label: string; start_date: string; end_date: string; is_current: boolean; is_active: boolean; }
interface CalendarEvent { id: number; academic_year_id?: number; event_type: string; label: string; description?: string; start_date: string; end_date?: string; is_active: boolean; program_id?: number; }

const EVENT_TYPE_LABELS: Record<string, { label: string; color: string; icon: string }> = {
  academic_year_start:       { label: 'Year Start',           color: 'bg-blue-500',   icon: '🎓' },
  academic_year_end:         { label: 'Year End',             color: 'bg-blue-800',   icon: '🏁' },
  semester_start:            { label: 'Semester Start',       color: 'bg-green-500',  icon: '📅' },
  semester_end:              { label: 'Semester End',         color: 'bg-green-800',  icon: '📆' },
  registration_open:         { label: 'Registration Open',    color: 'bg-emerald-500',icon: '📝' },
  registration_close:        { label: 'Registration Close',   color: 'bg-emerald-700',icon: '🔒' },
  add_drop_open:             { label: 'Add/Drop Open',        color: 'bg-teal-500',   icon: '➕' },
  add_drop_close:            { label: 'Add/Drop Close',       color: 'bg-teal-700',   icon: '➖' },
  withdrawal_deadline:       { label: 'Withdrawal Deadline',  color: 'bg-orange-500', icon: '⚠️' },
  exam_period_start:         { label: 'Exams Start',          color: 'bg-purple-500', icon: '📋' },
  exam_period_end:           { label: 'Exams End',            color: 'bg-purple-700', icon: '✅' },
  graduation_deadline:       { label: 'Graduation Deadline',  color: 'bg-yellow-500', icon: '🎓' },
  grade_submission_deadline: { label: 'Grade Submission',     color: 'bg-red-500',    icon: '📤' },
  holiday:                   { label: 'Holiday',              color: 'bg-gray-500',   icon: '🏖️' },
  other:                     { label: 'Other',                color: 'bg-gray-400',   icon: '📌' },
};

const EMPTY_EVENT = {
  academic_year_id: 0, term_id: undefined, event_type: 'semester_start',
  label: '', description: '', start_date: '', end_date: '',
  affects_all_programs: true, program_id: undefined,
};

export default function AcademicCalendar() {
  const { token } = useAuth();
  const [years, setYears]       = useState<AcademicYear[]>([]);
  const [events, setEvents]     = useState<CalendarEvent[]>([]);
  const [dashboard, setDashboard] = useState<any>(null);
  const [selectedYear, setSelectedYear] = useState<number | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [showYearForm, setShowYearForm] = useState(false);
  const [editEvent, setEditEvent] = useState<any>(EMPTY_EVENT);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [newYear, setNewYear]   = useState({ label: '', start_date: '', end_date: '', is_current: false });
  const [saving, setSaving]     = useState(false);
  const [msg, setMsg]           = useState<string | null>(null);
  const [filterType, setFilterType] = useState<string>('all');
  const [view, setView]         = useState<'list' | 'dashboard'>('dashboard');

  const hdr = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

  const loadAll = async () => {
    const [yearsR, dashR] = await Promise.all([
      fetch(`${API}/years`, { headers: hdr }).then(r => r.json()),
      fetch(`${API}/dashboard`, { headers: hdr }).then(r => r.json()),
    ]);
    setYears(Array.isArray(yearsR) ? yearsR : []);
    setDashboard(dashR);
    const current = (Array.isArray(yearsR) ? yearsR : []).find((y: AcademicYear) => y.is_current);
    if (current) setSelectedYear(current.id);
  };

  const loadEvents = async (yearId?: number) => {
    const params = yearId ? `?year_id=${yearId}` : '';
    const data = await fetch(`${API}/events${params}`, { headers: hdr }).then(r => r.json());
    setEvents(Array.isArray(data) ? data : []);
  };

  useEffect(() => { loadAll(); }, []);
  useEffect(() => { if (selectedYear) loadEvents(selectedYear); }, [selectedYear]);

  const saveEvent = async () => {
    setSaving(true);
    const body = { ...editEvent, academic_year_id: selectedYear || editEvent.academic_year_id };
    try {
      const url = editingId ? `${API}/events/${editingId}` : `${API}/events`;
      const method = editingId ? 'PUT' : 'POST';
      const r = await fetch(url, { method, headers: hdr, body: JSON.stringify(body) });
      if (r.ok) {
        setMsg('Event saved ✓');
        setShowForm(false); setEditingId(null); setEditEvent(EMPTY_EVENT);
        await loadEvents(selectedYear || undefined);
      }
    } catch {}
    setSaving(false);
  };

  const deleteEvent = async (id: number) => {
    if (!window.confirm('Deactivate this event?')) return;
    await fetch(`${API}/events/${id}`, { method: 'DELETE', headers: hdr });
    await loadEvents(selectedYear || undefined);
  };

  const snapshotYear = async () => {
    if (!selectedYear) return;
    const r = await fetch(`${API}/years/${selectedYear}/snapshot`, { method: 'POST', headers: hdr });
    if (r.ok) setMsg('Calendar version snapshot saved ✓');
  };

  const createYear = async () => {
    const r = await fetch(`${API}/years`, {
      method: 'POST', headers: hdr, body: JSON.stringify(newYear),
    });
    if (r.ok) {
      setShowYearForm(false);
      setNewYear({ label: '', start_date: '', end_date: '', is_current: false });
      await loadAll();
    }
  };

  const openEdit = (ev: CalendarEvent) => {
    setEditEvent({ ...ev });
    setEditingId(ev.id);
    setShowForm(true);
  };

  const filtered = filterType === 'all' ? events : events.filter(e => e.event_type === filterType);
  const sortedEvents = [...filtered].sort((a, b) => a.start_date.localeCompare(b.start_date));

  const today = new Date().toISOString().split('T')[0];
  const upcoming = events.filter(e => e.start_date >= today).sort((a, b) => a.start_date.localeCompare(b.start_date));

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">

        {/* Header */}
        <div className="mb-6 flex justify-between items-start">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">📅 Academic Calendar</h1>
            <p className="text-gray-500 text-sm mt-1">
              Manage academic years, semesters, registration windows, exam periods, and key dates.
            </p>
          </div>
          <div className="flex gap-2">
            <button onClick={() => setView(v => v === 'dashboard' ? 'list' : 'dashboard')}
              className="text-sm border border-gray-300 px-3 py-1.5 rounded hover:bg-gray-50 text-gray-700">
              {view === 'dashboard' ? '📋 List View' : '📊 Dashboard View'}
            </button>
            <button onClick={() => setShowYearForm(true)}
              className="text-sm border border-gray-300 px-3 py-1.5 rounded hover:bg-gray-50 text-gray-700">
              + Academic Year
            </button>
            <button onClick={snapshotYear} disabled={!selectedYear}
              className="text-sm border border-gray-300 px-3 py-1.5 rounded hover:bg-gray-50 text-gray-700 disabled:opacity-40">
              📸 Snapshot
            </button>
            <button onClick={() => { setShowForm(true); setEditingId(null); setEditEvent(EMPTY_EVENT); }}
              className="text-sm bg-blue-600 text-white px-4 py-1.5 rounded hover:bg-blue-700">
              + Add Event
            </button>
          </div>
        </div>

        {msg && (
          <div className="mb-4 p-3 rounded bg-green-50 text-green-700 text-sm border border-green-200 flex justify-between">
            {msg} <button onClick={() => setMsg(null)} className="text-green-500">×</button>
          </div>
        )}

        {/* Dashboard View */}
        {view === 'dashboard' && dashboard && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <div className={`rounded-lg border-2 p-4 ${dashboard.registration_open ? 'bg-emerald-50 border-emerald-300' : 'bg-white border-gray-200'}`}>
              <div className="flex items-center gap-2">
                <span className="text-2xl">📝</span>
                <div>
                  <p className="text-xs text-gray-500 uppercase">Registration</p>
                  <p className={`font-semibold text-sm ${dashboard.registration_open ? 'text-emerald-600' : 'text-gray-500'}`}>
                    {dashboard.registration_open ? '✓ Open' : 'Closed'}
                  </p>
                </div>
              </div>
            </div>
            <div className={`rounded-lg border-2 p-4 ${dashboard.add_drop_open ? 'bg-teal-50 border-teal-300' : 'bg-white border-gray-200'}`}>
              <div className="flex items-center gap-2">
                <span className="text-2xl">➕</span>
                <div>
                  <p className="text-xs text-gray-500 uppercase">Add / Drop</p>
                  <p className={`font-semibold text-sm ${dashboard.add_drop_open ? 'text-teal-600' : 'text-gray-500'}`}>
                    {dashboard.add_drop_open ? '✓ Open' : 'Closed'}
                  </p>
                </div>
              </div>
            </div>
            <div className={`rounded-lg border-2 p-4 ${dashboard.exam_period ? 'bg-purple-50 border-purple-300' : 'bg-white border-gray-200'}`}>
              <div className="flex items-center gap-2">
                <span className="text-2xl">📋</span>
                <div>
                  <p className="text-xs text-gray-500 uppercase">Exam Period</p>
                  <p className={`font-semibold text-sm ${dashboard.exam_period ? 'text-purple-600' : 'text-gray-500'}`}>
                    {dashboard.exam_period ? '✓ Active' : 'Not Active'}
                  </p>
                </div>
              </div>
            </div>
            {dashboard.next_event && (
              <div className="md:col-span-3 bg-blue-50 border border-blue-200 rounded-lg p-4">
                <p className="text-xs text-blue-500 uppercase tracking-wide mb-1">Next Event</p>
                <p className="font-semibold text-blue-800">{dashboard.next_event.label}</p>
                <p className="text-sm text-blue-600 mt-0.5">
                  {dashboard.next_event.start_date}
                  {dashboard.days_to_next_event !== null && ` · in ${dashboard.days_to_next_event} day(s)`}
                </p>
              </div>
            )}
          </div>
        )}

        <div className="flex gap-4">
          {/* Sidebar: Year Selector */}
          <div className="w-48 shrink-0">
            <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
              <div className="px-3 py-2 border-b border-gray-100 text-xs text-gray-500 uppercase tracking-wide">
                Academic Years
              </div>
              {years.length === 0 ? (
                <p className="text-xs text-gray-400 p-3">No years yet.</p>
              ) : years.map(y => (
                <button key={y.id}
                  onClick={() => setSelectedYear(y.id)}
                  className={`w-full text-left px-3 py-2 text-sm transition-colors border-b border-gray-50 ${
                    selectedYear === y.id ? 'bg-blue-50 text-blue-700 font-medium' : 'text-gray-700 hover:bg-gray-50'
                  }`}>
                  {y.label}
                  {y.is_current && <span className="ml-1 text-xs text-emerald-600">●</span>}
                </button>
              ))}
            </div>
          </div>

          {/* Main Events */}
          <div className="flex-1">
            {/* Filter bar */}
            <div className="flex gap-2 mb-4 flex-wrap">
              <button onClick={() => setFilterType('all')}
                className={`text-xs px-3 py-1 rounded-full border ${filterType === 'all' ? 'bg-blue-600 text-white border-blue-600' : 'border-gray-300 text-gray-600'}`}>
                All ({events.length})
              </button>
              {Object.entries(EVENT_TYPE_LABELS).map(([key, meta]) => {
                const cnt = events.filter(e => e.event_type === key).length;
                if (!cnt) return null;
                return (
                  <button key={key} onClick={() => setFilterType(key)}
                    className={`text-xs px-3 py-1 rounded-full border ${filterType === key ? 'bg-blue-600 text-white border-blue-600' : 'border-gray-300 text-gray-600'}`}>
                    {meta.icon} {meta.label} ({cnt})
                  </button>
                );
              })}
            </div>

            {/* Events list */}
            <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
              {sortedEvents.length === 0 ? (
                <div className="p-8 text-center">
                  <p className="text-3xl mb-2">📭</p>
                  <p className="text-gray-400 text-sm">No events for this year/filter.</p>
                  <button onClick={() => setShowForm(true)}
                    className="mt-3 text-sm text-blue-600 hover:underline">Add first event →</button>
                </div>
              ) : sortedEvents.map(ev => {
                const meta = EVENT_TYPE_LABELS[ev.event_type] || EVENT_TYPE_LABELS.other;
                const isPast = ev.start_date < today;
                const isToday = ev.start_date === today;
                return (
                  <div key={ev.id}
                    className={`flex items-center gap-4 px-5 py-3 border-b border-gray-100 hover:bg-gray-50 ${isPast ? 'opacity-60' : ''}`}>
                    <div className={`w-2 h-2 rounded-full ${meta.color} shrink-0`} />
                    <div className="w-28 shrink-0">
                      <p className={`text-sm font-mono ${isToday ? 'text-blue-600 font-bold' : 'text-gray-600'}`}>
                        {ev.start_date}
                      </p>
                      {ev.end_date && ev.end_date !== ev.start_date && (
                        <p className="text-xs text-gray-400">→ {ev.end_date}</p>
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-gray-900 truncate">{ev.label}</p>
                      <p className="text-xs text-gray-400">
                        {meta.icon} {meta.label}
                        {isToday && <span className="ml-2 text-blue-500 font-semibold">TODAY</span>}
                      </p>
                    </div>
                    <div className="flex gap-2 shrink-0">
                      <button onClick={() => openEdit(ev)}
                        className="text-xs text-blue-500 hover:underline">Edit</button>
                      <button onClick={() => deleteEvent(ev.id)}
                        className="text-xs text-red-400 hover:underline">Delete</button>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* Event Form Modal */}
        {showForm && (
          <div className="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl shadow-xl w-full max-w-lg p-6">
              <div className="flex justify-between items-center mb-5">
                <h2 className="font-bold text-gray-900">{editingId ? 'Edit Event' : 'Add Calendar Event'}</h2>
                <button onClick={() => { setShowForm(false); setEditingId(null); }} className="text-gray-400 hover:text-gray-600 text-xl">×</button>
              </div>
              <div className="space-y-4">
                <div>
                  <label className="text-xs font-medium text-gray-700 block mb-1">Event Type *</label>
                  <select value={editEvent.event_type}
                    onChange={e => setEditEvent((v: any) => ({ ...v, event_type: e.target.value }))}
                    className="w-full border border-gray-300 rounded px-3 py-2 text-sm">
                    {Object.entries(EVENT_TYPE_LABELS).map(([k, m]) => (
                      <option key={k} value={k}>{m.icon} {m.label}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-700 block mb-1">Label *</label>
                  <input type="text" value={editEvent.label}
                    onChange={e => setEditEvent((v: any) => ({ ...v, label: e.target.value }))}
                    placeholder="e.g. Fall 2024 Semester Start"
                    className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-700 block mb-1">Description</label>
                  <textarea value={editEvent.description}
                    onChange={e => setEditEvent((v: any) => ({ ...v, description: e.target.value }))}
                    rows={2}
                    className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-xs font-medium text-gray-700 block mb-1">Start Date *</label>
                    <input type="date" value={editEvent.start_date}
                      onChange={e => setEditEvent((v: any) => ({ ...v, start_date: e.target.value }))}
                      className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
                  </div>
                  <div>
                    <label className="text-xs font-medium text-gray-700 block mb-1">End Date</label>
                    <input type="date" value={editEvent.end_date || ''}
                      onChange={e => setEditEvent((v: any) => ({ ...v, end_date: e.target.value }))}
                      className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
                  </div>
                </div>
                <label className="flex items-center gap-2 text-sm text-gray-700">
                  <input type="checkbox" checked={editEvent.affects_all_programs}
                    onChange={e => setEditEvent((v: any) => ({ ...v, affects_all_programs: e.target.checked }))} />
                  Affects all programs
                </label>
              </div>
              <div className="flex gap-3 mt-6 justify-end">
                <button onClick={() => { setShowForm(false); setEditingId(null); }}
                  className="text-sm px-4 py-2 border border-gray-300 rounded text-gray-700 hover:bg-gray-50">
                  Cancel
                </button>
                <button onClick={saveEvent} disabled={saving || !editEvent.label || !editEvent.start_date}
                  className="text-sm px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-40">
                  {saving ? 'Saving…' : editingId ? 'Update Event' : 'Add Event'}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Academic Year Form Modal */}
        {showYearForm && (
          <div className="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
              <div className="flex justify-between items-center mb-5">
                <h2 className="font-bold text-gray-900">Add Academic Year</h2>
                <button onClick={() => setShowYearForm(false)} className="text-gray-400 hover:text-gray-600 text-xl">×</button>
              </div>
              <div className="space-y-4">
                <div>
                  <label className="text-xs font-medium text-gray-700 block mb-1">Label (e.g. 2024/2025)</label>
                  <input type="text" value={newYear.label}
                    onChange={e => setNewYear(v => ({ ...v, label: e.target.value }))}
                    className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-xs font-medium text-gray-700 block mb-1">Start Date</label>
                    <input type="date" value={newYear.start_date}
                      onChange={e => setNewYear(v => ({ ...v, start_date: e.target.value }))}
                      className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
                  </div>
                  <div>
                    <label className="text-xs font-medium text-gray-700 block mb-1">End Date</label>
                    <input type="date" value={newYear.end_date}
                      onChange={e => setNewYear(v => ({ ...v, end_date: e.target.value }))}
                      className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
                  </div>
                </div>
                <label className="flex items-center gap-2 text-sm text-gray-700">
                  <input type="checkbox" checked={newYear.is_current}
                    onChange={e => setNewYear(v => ({ ...v, is_current: e.target.checked }))} />
                  Set as current academic year
                </label>
              </div>
              <div className="flex gap-3 mt-6 justify-end">
                <button onClick={() => setShowYearForm(false)}
                  className="text-sm px-4 py-2 border border-gray-300 rounded text-gray-700 hover:bg-gray-50">Cancel</button>
                <button onClick={createYear} disabled={!newYear.label}
                  className="text-sm px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-40">
                  Create Year
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
