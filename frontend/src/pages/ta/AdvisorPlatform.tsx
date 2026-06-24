// EduGuard AI — Sprint 5 Module D8: Advisor / TA Intervention Platform
// /frontend/src/pages/ta/AdvisorPlatform.tsx
// v5.0 — Assigned students, risk cases, meetings, notes, follow-up

import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';

const API = '/api/v2/sprint5/student-success';

interface Intervention {
  id: number; student_id: number; title: string; status: string;
  priority: string; intervention_type: string; description?: string;
  due_date?: string; created_at: string;
  recommendations?: string[];
  target_cgpa?: number; required_next_gpa?: number;
  marks_needed?: Record<string, any>;
}
interface Warning { id: number; student_id: number; warning_type: string; severity: string; title: string; status: string; created_at: string; }
interface Meeting { id: number; student_id: number; meeting_type: string; scheduled_at: string; status: string; notes?: string; duration_minutes?: number; }
interface Note { id: number; student_id: number; content: string; note_type: string; is_private: boolean; created_at: string; }

const PRIORITY_STYLE: Record<string, string> = {
  high: 'bg-red-100 text-red-700 border-red-200',
  medium: 'bg-amber-100 text-amber-700 border-amber-200',
  low: 'bg-gray-100 text-gray-600 border-gray-200',
};
const SEV_STYLE: Record<string, string> = {
  urgent: 'bg-red-50 border-red-300 text-red-700',
  critical: 'bg-orange-50 border-orange-300 text-orange-700',
  warning: 'bg-yellow-50 border-yellow-300 text-yellow-700',
  info: 'bg-blue-50 border-blue-300 text-blue-700',
};
const STATUS_STYLE: Record<string, string> = {
  recommended: 'bg-blue-50 text-blue-700',
  scheduled: 'bg-purple-50 text-purple-700',
  in_progress: 'bg-amber-50 text-amber-700',
  completed: 'bg-green-50 text-green-700',
  cancelled: 'bg-gray-100 text-gray-500',
  no_response: 'bg-red-50 text-red-600',
};

export default function AdvisorPlatform() {
  const { token, user } = useAuth();
  const [tab, setTab] = useState<'dashboard'|'interventions'|'warnings'|'meetings'|'notes'>('dashboard');
  const [dashboard, setDashboard] = useState<any>(null);
  const [interventions, setInterventions] = useState<Intervention[]>([]);
  const [warnings, setWarnings] = useState<Warning[]>([]);
  const [meetings, setMeetings] = useState<Meeting[]>([]);
  const [loading, setLoading] = useState(true);

  // Modals
  const [showNoteModal, setShowNoteModal] = useState(false);
  const [showMeetingModal, setShowMeetingModal] = useState(false);
  const [selectedStudentId, setSelectedStudentId] = useState<number | null>(null);
  const [selectedInterventionId, setSelectedInterventionId] = useState<number | null>(null);
  const [noteForm, setNoteForm] = useState({ content: '', note_type: 'general', is_private: false });
  const [meetingForm, setMeetingForm] = useState({ meeting_type: 'in_person', scheduled_at: '', duration_minutes: 60, notes: '' });
  const [statusUpdate, setStatusUpdate] = useState<{ id: number; status: string } | null>(null);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);

  const hdr = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

  const loadDashboard = async () => {
    setLoading(true);
    try {
      const d = await fetch(`${API}/advisor/dashboard`, { headers: hdr }).then(r => r.json());
      setDashboard(d);
      setInterventions(d.my_interventions || []);
      setWarnings(d.recent_warnings || []);
    } catch {}
    setLoading(false);
  };

  const loadMeetings = async () => {
    const d = await fetch(`${API}/advisor/meetings`, { headers: hdr }).then(r => r.json());
    setMeetings(Array.isArray(d) ? d : []);
  };

  useEffect(() => { loadDashboard(); loadMeetings(); }, []);

  const saveNote = async () => {
    if (!selectedStudentId || !noteForm.content.trim()) return;
    setSaving(true);
    await fetch(`${API}/advisor/notes`, {
      method: 'POST', headers: hdr,
      body: JSON.stringify({
        student_id: selectedStudentId,
        intervention_id: selectedInterventionId,
        ...noteForm,
      }),
    });
    setMsg('Note saved ✓');
    setShowNoteModal(false);
    setNoteForm({ content: '', note_type: 'general', is_private: false });
    setSaving(false);
  };

  const saveMeeting = async () => {
    if (!selectedStudentId || !meetingForm.scheduled_at) return;
    setSaving(true);
    await fetch(`${API}/advisor/meetings`, {
      method: 'POST', headers: hdr,
      body: JSON.stringify({
        student_id: selectedStudentId,
        intervention_id: selectedInterventionId,
        ...meetingForm,
        scheduled_at: new Date(meetingForm.scheduled_at).toISOString(),
      }),
    });
    setMsg('Meeting scheduled ✓');
    setShowMeetingModal(false);
    setMeetingForm({ meeting_type: 'in_person', scheduled_at: '', duration_minutes: 60, notes: '' });
    await loadMeetings();
    setSaving(false);
  };

  const updateStatus = async (id: number, status: string) => {
    await fetch(`${API}/interventions/${id}/status?status=${status}`, {
      method: 'PUT', headers: hdr,
    });
    setMsg(`Intervention status updated to ${status} ✓`);
    await loadDashboard();
  };

  const acknowledgeWarning = async (wid: number) => {
    await fetch(`${API}/warnings/${wid}/acknowledge`, {
      method: 'POST', headers: hdr,
      body: JSON.stringify({ notes: 'Acknowledged by advisor' }),
    });
    setMsg('Warning acknowledged ✓');
    await loadDashboard();
  };

  const openNote = (studentId: number, interventionId?: number) => {
    setSelectedStudentId(studentId);
    setSelectedInterventionId(interventionId || null);
    setShowNoteModal(true);
  };

  const openMeeting = (studentId: number, interventionId?: number) => {
    setSelectedStudentId(studentId);
    setSelectedInterventionId(interventionId || null);
    setShowMeetingModal(true);
  };

  if (loading) return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="text-center">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600 mx-auto mb-3" />
        <p className="text-gray-500 text-sm">Loading advisor platform…</p>
      </div>
    </div>
  );

  const d = dashboard;

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">

        {/* Header */}
        <div className="mb-6 flex justify-between items-start">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">👨‍🏫 Advisor / TA Platform</h1>
            <p className="text-gray-500 text-sm mt-1">
              Student intervention management, follow-up, and success tracking
            </p>
          </div>
        </div>

        {msg && (
          <div className="mb-4 p-3 rounded bg-green-50 text-green-700 text-sm border border-green-200 flex justify-between">
            {msg}<button onClick={() => setMsg(null)} className="text-green-500">×</button>
          </div>
        )}

        {/* Summary Stats */}
        {d && (
          <div className="grid grid-cols-2 md:grid-cols-6 gap-3 mb-6">
            {[
              { label: 'Assigned Students', value: d.total_assigned,       color: 'text-gray-900', icon: '👥' },
              { label: 'At Risk',           value: d.at_risk_count,        color: 'text-amber-600', icon: '⚠️' },
              { label: 'Critical',          value: d.critical_count,       color: 'text-red-600',   icon: '🚨' },
              { label: 'Active Plans',      value: d.active_interventions, color: 'text-blue-600',  icon: '📋' },
              { label: 'Meetings/Week',     value: d.meetings_this_week,   color: 'text-purple-600',icon: '🗓️' },
              { label: 'Pending Escalations', value: d.pending_escalations, color: 'text-orange-600',icon: '⬆️' },
            ].map(k => (
              <div key={k.label} className="bg-white rounded-lg border border-gray-200 p-3">
                <div className="flex items-center justify-between mb-1">
                  <p className="text-xs text-gray-400">{k.label}</p>
                  <span>{k.icon}</span>
                </div>
                <p className={`text-xl font-bold ${k.color}`}>{k.value}</p>
              </div>
            ))}
          </div>
        )}

        {/* Tabs */}
        <div className="bg-white rounded-lg border border-gray-200">
          <div className="flex border-b border-gray-200 overflow-x-auto">
            {[
              { key: 'dashboard',      label: '📊 Overview' },
              { key: 'interventions',  label: `🎯 My Interventions (${interventions.length})` },
              { key: 'warnings',       label: `⚠️ Active Warnings (${warnings.length})` },
              { key: 'meetings',       label: `🗓️ Meetings (${meetings.length})` },
            ].map(t => (
              <button key={t.key}
                onClick={() => setTab(t.key as any)}
                className={`px-5 py-3 text-sm font-medium whitespace-nowrap transition-colors ${
                  tab === t.key ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-500 hover:text-gray-700'
                }`}>
                {t.label}
              </button>
            ))}
          </div>

          <div className="p-5">
            {/* Overview Tab */}
            {tab === 'dashboard' && (
              <div className="space-y-6">
                {/* Quick Actions */}
                <div>
                  <h3 className="font-semibold text-sm text-gray-900 mb-3">Recent Warnings</h3>
                  {warnings.slice(0, 5).map(w => (
                    <div key={w.id} className={`mb-2 border rounded-lg px-4 py-3 flex justify-between items-center ${SEV_STYLE[w.severity] || 'bg-gray-50 border-gray-200'}`}>
                      <div>
                        <p className="text-sm font-medium">{w.title}</p>
                        <p className="text-xs opacity-70 mt-0.5">
                          Student #{w.student_id} · {w.warning_type.replace(/_/g, ' ')} · {w.severity}
                        </p>
                      </div>
                      <div className="flex gap-2 shrink-0 ml-4">
                        <button onClick={() => openNote(w.student_id)}
                          className="text-xs px-2 py-1 bg-white bg-opacity-60 rounded hover:bg-opacity-80">
                          + Note
                        </button>
                        <button onClick={() => openMeeting(w.student_id)}
                          className="text-xs px-2 py-1 bg-white bg-opacity-60 rounded hover:bg-opacity-80">
                          Schedule
                        </button>
                        <button onClick={() => acknowledgeWarning(w.id)}
                          className="text-xs px-2 py-1 bg-white bg-opacity-60 rounded hover:bg-opacity-80">
                          ✓ Ack
                        </button>
                      </div>
                    </div>
                  ))}
                  {warnings.length === 0 && <p className="text-sm text-green-600">✓ No active warnings for your students</p>}
                </div>

                {/* Upcoming Meetings */}
                <div>
                  <h3 className="font-semibold text-sm text-gray-900 mb-3">Upcoming Meetings</h3>
                  {meetings.filter(m => m.status === 'scheduled').slice(0, 4).map(m => (
                    <div key={m.id} className="mb-2 border border-gray-200 rounded-lg px-4 py-3 flex justify-between items-center bg-purple-50">
                      <div>
                        <p className="text-sm font-medium text-purple-800">
                          Student #{m.student_id} — {m.meeting_type.replace('_', ' ')}
                        </p>
                        <p className="text-xs text-purple-600 mt-0.5">
                          {new Date(m.scheduled_at).toLocaleString()}
                          {m.duration_minutes && ` · ${m.duration_minutes} min`}
                        </p>
                      </div>
                      <span className="text-xs bg-purple-100 text-purple-700 px-2 py-0.5 rounded-full">Scheduled</span>
                    </div>
                  ))}
                  {meetings.filter(m => m.status === 'scheduled').length === 0 && (
                    <p className="text-sm text-gray-400">No upcoming meetings.</p>
                  )}
                </div>
              </div>
            )}

            {/* Interventions Tab */}
            {tab === 'interventions' && (
              <div>
                <div className="flex justify-between items-center mb-4">
                  <h3 className="font-semibold text-sm text-gray-900">My Assigned Interventions</h3>
                </div>
                {interventions.length === 0 ? (
                  <div className="text-center py-8">
                    <p className="text-3xl mb-2">📭</p>
                    <p className="text-gray-400 text-sm">No interventions assigned to you.</p>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {interventions.map(iv => (
                      <div key={iv.id} className="border border-gray-200 rounded-lg overflow-hidden">
                        <div className="px-4 py-3 flex items-start justify-between bg-gray-50">
                          <div>
                            <p className="font-medium text-sm text-gray-900">{iv.title}</p>
                            <p className="text-xs text-gray-500 mt-0.5">
                              Student #{iv.student_id}
                              · Type: {iv.intervention_type.replace(/_/g, ' ')}
                              {iv.due_date && ` · Due: ${iv.due_date}`}
                            </p>
                          </div>
                          <div className="flex gap-2 items-start ml-4 shrink-0">
                            <span className={`text-xs px-2 py-0.5 rounded-full border ${PRIORITY_STYLE[iv.priority]}`}>
                              {iv.priority}
                            </span>
                            <span className={`text-xs px-2 py-0.5 rounded-full ${STATUS_STYLE[iv.status]}`}>
                              {iv.status.replace(/_/g, ' ')}
                            </span>
                          </div>
                        </div>
                        {iv.description && (
                          <div className="px-4 py-2 text-sm text-gray-600 border-t border-gray-100">
                            {iv.description}
                          </div>
                        )}
                        {iv.recommendations && iv.recommendations.length > 0 && (
                          <div className="px-4 py-2 bg-blue-50 border-t border-blue-100">
                            <p className="text-xs font-medium text-blue-700 mb-1">Recommendations:</p>
                            <ul className="space-y-0.5">
                              {iv.recommendations.map((rec, i) => (
                                <li key={i} className="text-xs text-blue-600">• {rec}</li>
                              ))}
                            </ul>
                          </div>
                        )}
                        {iv.target_cgpa && (
                          <div className="px-4 py-2 grid grid-cols-3 gap-3 bg-amber-50 border-t border-amber-100 text-xs">
                            <div>
                              <p className="text-amber-600 font-medium">Target CGPA</p>
                              <p className="text-amber-800 font-bold text-base">{iv.target_cgpa.toFixed(2)}</p>
                            </div>
                            {iv.required_next_gpa && (
                              <div>
                                <p className="text-amber-600 font-medium">Required Next GPA</p>
                                <p className="text-amber-800 font-bold text-base">{Math.min(4.0, iv.required_next_gpa).toFixed(2)}</p>
                              </div>
                            )}
                          </div>
                        )}
                        <div className="px-4 py-2 border-t border-gray-100 flex gap-3">
                          <select
                            defaultValue={iv.status}
                            onChange={e => updateStatus(iv.id, e.target.value)}
                            className="text-xs border border-gray-300 rounded px-2 py-1 bg-white"
                          >
                            {['recommended','scheduled','in_progress','completed','cancelled','no_response'].map(s => (
                              <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>
                            ))}
                          </select>
                          <button onClick={() => openNote(iv.student_id, iv.id)}
                            className="text-xs text-blue-600 hover:underline">+ Note</button>
                          <button onClick={() => openMeeting(iv.student_id, iv.id)}
                            className="text-xs text-purple-600 hover:underline">+ Meeting</button>
                          <a href={`/success/${iv.student_id}`}
                            className="text-xs text-gray-500 hover:underline ml-auto">View Dashboard →</a>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}

            {/* Warnings Tab */}
            {tab === 'warnings' && (
              <div>
                <h3 className="font-semibold text-sm text-gray-900 mb-4">Active Warnings — My Students</h3>
                {warnings.length === 0 ? (
                  <div className="text-center py-8">
                    <p className="text-3xl mb-2">✅</p>
                    <p className="text-gray-400 text-sm">No active warnings for your assigned students.</p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {warnings.map(w => (
                      <div key={w.id} className={`border rounded-lg p-4 ${SEV_STYLE[w.severity] || 'bg-gray-50 border-gray-200'}`}>
                        <div className="flex justify-between items-start">
                          <div>
                            <p className="font-medium text-sm">{w.title}</p>
                            <p className="text-xs opacity-70 mt-1">
                              Student #{w.student_id}
                              · {w.warning_type.replace(/_/g, ' ')}
                              · {new Date(w.created_at).toLocaleDateString()}
                            </p>
                          </div>
                          <div className="flex gap-2 ml-4 shrink-0">
                            <button onClick={() => openNote(w.student_id)}
                              className="text-xs px-2 py-1 bg-white bg-opacity-70 rounded border border-current border-opacity-30">
                              + Note
                            </button>
                            <button onClick={() => openMeeting(w.student_id)}
                              className="text-xs px-2 py-1 bg-white bg-opacity-70 rounded border border-current border-opacity-30">
                              Schedule Meeting
                            </button>
                            <button onClick={() => acknowledgeWarning(w.id)}
                              className="text-xs px-2 py-1 bg-white bg-opacity-70 rounded border border-current border-opacity-30">
                              ✓ Acknowledge
                            </button>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}

            {/* Meetings Tab */}
            {tab === 'meetings' && (
              <div>
                <div className="flex justify-between items-center mb-4">
                  <h3 className="font-semibold text-sm text-gray-900">Scheduled Meetings</h3>
                  <button onClick={() => { setSelectedStudentId(null); setShowMeetingModal(true); }}
                    className="text-xs bg-purple-600 text-white px-3 py-1.5 rounded hover:bg-purple-700">
                    + Schedule Meeting
                  </button>
                </div>
                {meetings.length === 0 ? (
                  <p className="text-sm text-gray-400">No meetings scheduled.</p>
                ) : (
                  <div className="space-y-3">
                    {meetings.map(m => (
                      <div key={m.id} className="border border-gray-200 rounded-lg p-4 flex items-center justify-between">
                        <div>
                          <p className="font-medium text-sm text-gray-900">
                            Student #{m.student_id} — {m.meeting_type.replace(/_/g, ' ')}
                          </p>
                          <p className="text-xs text-gray-500 mt-0.5">
                            {new Date(m.scheduled_at).toLocaleString()}
                            {m.duration_minutes && ` · ${m.duration_minutes} min`}
                          </p>
                          {m.notes && <p className="text-xs text-gray-400 mt-1 italic">{m.notes}</p>}
                        </div>
                        <span className={`text-xs px-2 py-0.5 rounded-full ml-4 shrink-0 ${
                          m.status === 'completed' ? 'bg-green-100 text-green-700' :
                          m.status === 'scheduled' ? 'bg-purple-100 text-purple-700' :
                          m.status === 'no_show'   ? 'bg-red-100 text-red-700' :
                          'bg-gray-100 text-gray-500'
                        }`}>{m.status.replace('_', ' ')}</span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        </div>

        {/* Note Modal */}
        {showNoteModal && (
          <div className="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
              <div className="flex justify-between items-center mb-4">
                <h2 className="font-bold text-gray-900">Add Advisor Note</h2>
                <button onClick={() => setShowNoteModal(false)} className="text-gray-400 text-xl">×</button>
              </div>
              {!selectedStudentId && (
                <div className="mb-4">
                  <label className="text-xs font-medium text-gray-700 block mb-1">Student ID</label>
                  <input type="number" placeholder="Enter student ID"
                    onChange={e => setSelectedStudentId(parseInt(e.target.value))}
                    className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
                </div>
              )}
              <div className="space-y-3">
                <div>
                  <label className="text-xs font-medium text-gray-700 block mb-1">Note Type</label>
                  <select value={noteForm.note_type}
                    onChange={e => setNoteForm(n => ({ ...n, note_type: e.target.value }))}
                    className="w-full border border-gray-300 rounded px-3 py-2 text-sm">
                    <option value="general">General</option>
                    <option value="follow_up">Follow-up</option>
                    <option value="meeting">Meeting Summary</option>
                    <option value="phone">Phone Call</option>
                    <option value="email">Email</option>
                  </select>
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-700 block mb-1">Note Content *</label>
                  <textarea rows={4} value={noteForm.content}
                    onChange={e => setNoteForm(n => ({ ...n, content: e.target.value }))}
                    placeholder="Enter your note…"
                    className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
                </div>
                <label className="flex items-center gap-2 text-sm text-gray-700">
                  <input type="checkbox" checked={noteForm.is_private}
                    onChange={e => setNoteForm(n => ({ ...n, is_private: e.target.checked }))} />
                  Private note (only visible to you)
                </label>
              </div>
              <div className="flex gap-3 mt-5 justify-end">
                <button onClick={() => setShowNoteModal(false)}
                  className="text-sm px-4 py-2 border border-gray-300 rounded text-gray-700 hover:bg-gray-50">Cancel</button>
                <button onClick={saveNote} disabled={saving || !noteForm.content.trim()}
                  className="text-sm px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-40">
                  {saving ? 'Saving…' : 'Save Note'}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Meeting Modal */}
        {showMeetingModal && (
          <div className="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
              <div className="flex justify-between items-center mb-4">
                <h2 className="font-bold text-gray-900">Schedule Meeting</h2>
                <button onClick={() => setShowMeetingModal(false)} className="text-gray-400 text-xl">×</button>
              </div>
              {!selectedStudentId && (
                <div className="mb-4">
                  <label className="text-xs font-medium text-gray-700 block mb-1">Student ID</label>
                  <input type="number" placeholder="Enter student ID"
                    onChange={e => setSelectedStudentId(parseInt(e.target.value))}
                    className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
                </div>
              )}
              <div className="space-y-3">
                <div>
                  <label className="text-xs font-medium text-gray-700 block mb-1">Meeting Type</label>
                  <select value={meetingForm.meeting_type}
                    onChange={e => setMeetingForm(m => ({ ...m, meeting_type: e.target.value }))}
                    className="w-full border border-gray-300 rounded px-3 py-2 text-sm">
                    <option value="in_person">In Person</option>
                    <option value="online">Online</option>
                    <option value="phone">Phone</option>
                  </select>
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-700 block mb-1">Date & Time *</label>
                  <input type="datetime-local" value={meetingForm.scheduled_at}
                    onChange={e => setMeetingForm(m => ({ ...m, scheduled_at: e.target.value }))}
                    className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-700 block mb-1">Duration (minutes)</label>
                  <input type="number" value={meetingForm.duration_minutes}
                    onChange={e => setMeetingForm(m => ({ ...m, duration_minutes: parseInt(e.target.value) }))}
                    className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-700 block mb-1">Notes (optional)</label>
                  <textarea rows={2} value={meetingForm.notes}
                    onChange={e => setMeetingForm(m => ({ ...m, notes: e.target.value }))}
                    className="w-full border border-gray-300 rounded px-3 py-2 text-sm" />
                </div>
              </div>
              <div className="flex gap-3 mt-5 justify-end">
                <button onClick={() => setShowMeetingModal(false)}
                  className="text-sm px-4 py-2 border border-gray-300 rounded text-gray-700 hover:bg-gray-50">Cancel</button>
                <button onClick={saveMeeting} disabled={saving || !meetingForm.scheduled_at || !selectedStudentId}
                  className="text-sm px-4 py-2 bg-purple-600 text-white rounded hover:bg-purple-700 disabled:opacity-40">
                  {saving ? 'Scheduling…' : 'Schedule Meeting'}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
