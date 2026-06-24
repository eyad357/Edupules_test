// EduGuard AI — Sprint 5 Module D3: Student Success Dashboard
// /frontend/src/pages/student/StudentSuccessDashboard.tsx
// v5.0 — Full success platform with score, readiness, warnings, timeline

import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';

const API = '/api/v2/sprint5/student-success';

interface SuccessScore {
  score: number; band: string; trend: string;
  cgpa_score: number; attendance_score: number;
  course_completion_score: number; progress_score: number;
  active_warnings: number;
}

interface GradReadiness {
  readiness_pct: number; status: string;
  completed_credits: number; total_required_credits: number;
  remaining_credits: number; completed_courses: number;
  total_required_courses: number; cgpa_eligible: boolean;
  missing_required?: string[]; estimated_graduation_term?: string;
}

interface Warning { id: number; warning_type: string; severity: string; title: string; status: string; }
interface Intervention { id: number; title: string; status: string; priority: string; intervention_type: string; description?: string; }
interface TimelinePoint { period: string; term_gpa: number; cgpa: number; standing: string; credits_earned: number; cumulative_earned: number; }

interface DashboardData {
  student_name: string; student_code: string; program_name?: string;
  current_gpa: number; current_cgpa: number; academic_standing: string;
  success_score?: SuccessScore;
  graduation_readiness?: GradReadiness;
  active_warnings: Warning[];
  active_interventions: Intervention[];
  risk_level: string;
  total_credits_completed: number; credits_remaining: number;
  regular_semesters: number; dismissal_risk: boolean;
  recommendations: string[];
  timeline_summary: TimelinePoint[];
}

const BAND_COLORS: Record<string, string> = {
  excellent: 'text-emerald-600', good: 'text-blue-600',
  warning: 'text-amber-600', critical: 'text-red-600',
};
const BAND_BG: Record<string, string> = {
  excellent: 'bg-emerald-50 border-emerald-200', good: 'bg-blue-50 border-blue-200',
  warning: 'bg-amber-50 border-amber-200', critical: 'bg-red-50 border-red-200',
};
const SEV_COLORS: Record<string, string> = {
  urgent: 'bg-red-100 text-red-700', critical: 'bg-orange-100 text-orange-700',
  warning: 'bg-yellow-100 text-yellow-700', info: 'bg-blue-100 text-blue-700',
};
const RISK_BADGES: Record<string, string> = {
  critical: 'bg-red-100 text-red-700', high: 'bg-orange-100 text-orange-700',
  medium: 'bg-yellow-100 text-yellow-700', low: 'bg-green-100 text-green-700',
};
const READINESS_COLORS: Record<string, string> = {
  ready: 'text-emerald-600', nearly_ready: 'text-blue-600',
  needs_attention: 'text-amber-600', not_eligible: 'text-red-600',
};

export default function StudentSuccessDashboard() {
  const { studentId } = useParams<{ studentId: string }>();
  const { token, user } = useAuth();
  const sid = studentId || user?.student_id;

  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'overview'|'warnings'|'interventions'|'timeline'>('overview');
  const [acknowledging, setAcknowledging] = useState<number | null>(null);

  const hdr = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

  const load = async () => {
    if (!sid) return;
    setLoading(true);
    try {
      const r = await fetch(`${API}/dashboard/${sid}`, { headers: hdr });
      if (r.ok) setData(await r.json());
    } catch {}
    setLoading(false);
  };

  useEffect(() => { load(); }, [sid]);

  const acknowledgeWarning = async (wid: number) => {
    setAcknowledging(wid);
    await fetch(`${API}/warnings/${wid}/acknowledge`, {
      method: 'POST', headers: hdr, body: JSON.stringify({ notes: '' }),
    });
    await load();
    setAcknowledging(null);
  };

  const generateInterventions = async () => {
    await fetch(`${API}/interventions/generate/${sid}`, { method: 'POST', headers: hdr });
    await load();
  };

  if (loading) return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="text-center">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600 mx-auto mb-3"></div>
        <p className="text-gray-500 text-sm">Computing student success metrics…</p>
      </div>
    </div>
  );

  if (!data) return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <p className="text-gray-500">Student not found.</p>
    </div>
  );

  const score = data.success_score;
  const readiness = data.graduation_readiness;

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">

        {/* Header */}
        <div className="mb-6 flex items-start justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">
              🎓 {data.student_name}
            </h1>
            <p className="text-gray-500 text-sm mt-1">
              {data.student_code} • {data.program_name || 'Computer Science'}
              • {data.regular_semesters} Regular Semesters
            </p>
          </div>
          <div className="flex items-center gap-3">
            <span className={`px-3 py-1 rounded-full text-sm font-medium ${RISK_BADGES[data.risk_level] || 'bg-gray-100 text-gray-700'}`}>
              {data.risk_level.toUpperCase()} RISK
            </span>
            {data.dismissal_risk && (
              <span className="px-3 py-1 rounded-full text-sm font-medium bg-red-600 text-white animate-pulse">
                ⚠️ DISMISSAL RISK
              </span>
            )}
          </div>
        </div>

        {/* KPI Cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-white rounded-lg border border-gray-200 p-4">
            <p className="text-xs text-gray-500 uppercase tracking-wide">Current GPA</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">{data.current_gpa.toFixed(3)}</p>
            <p className="text-xs text-gray-400 mt-1">Term GPA</p>
          </div>
          <div className="bg-white rounded-lg border border-gray-200 p-4">
            <p className="text-xs text-gray-500 uppercase tracking-wide">CGPA</p>
            <p className={`text-2xl font-bold mt-1 ${data.current_cgpa < 2.0 ? 'text-red-600' : data.current_cgpa < 2.5 ? 'text-amber-600' : 'text-emerald-600'}`}>
              {data.current_cgpa.toFixed(3)}
            </p>
            <p className="text-xs text-gray-400 mt-1">Cumulative</p>
          </div>
          <div className="bg-white rounded-lg border border-gray-200 p-4">
            <p className="text-xs text-gray-500 uppercase tracking-wide">Credits</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">{data.total_credits_completed}</p>
            <p className="text-xs text-gray-400 mt-1">{data.credits_remaining} remaining</p>
          </div>
          <div className="bg-white rounded-lg border border-gray-200 p-4">
            <p className="text-xs text-gray-500 uppercase tracking-wide">Academic Standing</p>
            <p className={`text-lg font-bold mt-1 capitalize ${data.academic_standing === 'good' || data.academic_standing === 'honors' ? 'text-emerald-600' : 'text-red-600'}`}>
              {data.academic_standing}
            </p>
            <p className="text-xs text-gray-400 mt-1">{data.active_warnings.length} active warning(s)</p>
          </div>
        </div>

        {/* Success Score + Graduation Readiness */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
          {/* Success Score */}
          {score && (
            <div className={`bg-white rounded-lg border-2 p-5 ${BAND_BG[score.band] || ''}`}>
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-xs text-gray-500 uppercase tracking-wide">Student Success Score</p>
                  <p className={`text-5xl font-bold mt-2 ${BAND_COLORS[score.band]}`}>
                    {score.score.toFixed(0)}
                    <span className="text-xl font-normal text-gray-400">/100</span>
                  </p>
                  <p className={`text-sm font-medium capitalize mt-1 ${BAND_COLORS[score.band]}`}>
                    {score.band} • {score.trend === 'improving' ? '↑ Improving' : score.trend === 'declining' ? '↓ Declining' : '→ Stable'}
                  </p>
                </div>
                <div className="text-5xl">
                  {score.band === 'excellent' ? '⭐' : score.band === 'good' ? '✅' : score.band === 'warning' ? '⚠️' : '🚨'}
                </div>
              </div>
              {/* Component breakdown */}
              <div className="mt-4 space-y-2">
                {[
                  { label: 'CGPA', value: score.cgpa_score, icon: '📊' },
                  { label: 'Attendance', value: score.attendance_score, icon: '📋' },
                  { label: 'Course Completion', value: score.course_completion_score, icon: '✔️' },
                  { label: 'Academic Progress', value: score.progress_score, icon: '📈' },
                ].map(({ label, value, icon }) => (
                  <div key={label} className="flex items-center gap-2">
                    <span className="text-xs w-36 text-gray-500">{icon} {label}</span>
                    <div className="flex-1 bg-gray-100 rounded-full h-2">
                      <div
                        className={`h-2 rounded-full ${value >= 75 ? 'bg-emerald-500' : value >= 50 ? 'bg-blue-500' : value >= 25 ? 'bg-amber-500' : 'bg-red-500'}`}
                        style={{ width: `${value}%` }}
                      />
                    </div>
                    <span className="text-xs font-medium text-gray-600 w-8 text-right">{value.toFixed(0)}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Graduation Readiness */}
          {readiness && (
            <div className="bg-white rounded-lg border border-gray-200 p-5">
              <p className="text-xs text-gray-500 uppercase tracking-wide mb-3">Graduation Readiness</p>
              <div className="flex items-center gap-4">
                {/* Circular progress */}
                <div className="relative w-24 h-24 shrink-0">
                  <svg viewBox="0 0 36 36" className="w-24 h-24 -rotate-90">
                    <circle cx="18" cy="18" r="15.9" fill="none" stroke="#e5e7eb" strokeWidth="3" />
                    <circle
                      cx="18" cy="18" r="15.9" fill="none"
                      stroke={readiness.readiness_pct >= 95 ? '#10b981' : readiness.readiness_pct >= 75 ? '#3b82f6' : readiness.readiness_pct >= 40 ? '#f59e0b' : '#ef4444'}
                      strokeWidth="3"
                      strokeDasharray={`${readiness.readiness_pct} ${100 - readiness.readiness_pct}`}
                    />
                  </svg>
                  <div className="absolute inset-0 flex items-center justify-center">
                    <span className="text-lg font-bold text-gray-900">{readiness.readiness_pct.toFixed(0)}%</span>
                  </div>
                </div>
                <div>
                  <p className={`text-lg font-semibold capitalize ${READINESS_COLORS[readiness.status] || 'text-gray-700'}`}>
                    {readiness.status.replace('_', ' ')}
                  </p>
                  <p className="text-sm text-gray-500 mt-1">
                    {readiness.completed_credits}/{readiness.total_required_credits} credits
                  </p>
                  <p className="text-sm text-gray-500">
                    {readiness.completed_courses}/{readiness.total_required_courses} required courses
                  </p>
                  <p className={`text-xs mt-1 ${readiness.cgpa_eligible ? 'text-emerald-600' : 'text-red-600'}`}>
                    {readiness.cgpa_eligible ? '✓ CGPA Eligible' : '✗ CGPA Below Minimum'}
                  </p>
                  {readiness.estimated_graduation_term && (
                    <p className="text-xs text-blue-600 mt-1">
                      Est. graduation: {readiness.estimated_graduation_term}
                    </p>
                  )}
                </div>
              </div>
              {readiness.missing_required && readiness.missing_required.length > 0 && (
                <div className="mt-4">
                  <p className="text-xs text-red-600 font-medium mb-1">
                    Missing Required Courses ({readiness.missing_required.length}):
                  </p>
                  <div className="flex flex-wrap gap-1">
                    {readiness.missing_required.slice(0, 12).map(code => (
                      <span key={code} className="text-xs bg-red-50 text-red-600 px-2 py-0.5 rounded border border-red-100">
                        {code}
                      </span>
                    ))}
                    {readiness.missing_required.length > 12 && (
                      <span className="text-xs text-gray-400">+{readiness.missing_required.length - 12} more</span>
                    )}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Recommendations */}
        {data.recommendations.length > 0 && (
          <div className="bg-amber-50 border border-amber-200 rounded-lg p-4 mb-6">
            <h3 className="font-semibold text-amber-800 text-sm mb-2">💡 Recommendations</h3>
            <ul className="space-y-1">
              {data.recommendations.map((rec, i) => (
                <li key={i} className="text-sm text-amber-700">{rec}</li>
              ))}
            </ul>
          </div>
        )}

        {/* Tabs */}
        <div className="bg-white rounded-lg border border-gray-200">
          <div className="flex border-b border-gray-200">
            {[
              { key: 'overview',       label: '📊 Overview' },
              { key: 'warnings',       label: `⚠️ Warnings (${data.active_warnings.length})` },
              { key: 'interventions',  label: `🎯 Interventions (${data.active_interventions.length})` },
              { key: 'timeline',       label: '📈 Timeline' },
            ].map(tab => (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key as any)}
                className={`px-5 py-3 text-sm font-medium transition-colors ${
                  activeTab === tab.key
                    ? 'border-b-2 border-blue-500 text-blue-600'
                    : 'text-gray-500 hover:text-gray-700'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>

          <div className="p-5">
            {/* Overview Tab */}
            {activeTab === 'overview' && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <h3 className="font-semibold text-sm text-gray-900 mb-3">Recent Warnings</h3>
                  {data.active_warnings.slice(0, 4).length === 0 ? (
                    <p className="text-sm text-green-600">✓ No active warnings</p>
                  ) : data.active_warnings.slice(0, 4).map(w => (
                    <div key={w.id} className={`mb-2 px-3 py-2 rounded text-xs ${SEV_COLORS[w.severity] || 'bg-gray-100'}`}>
                      {w.title}
                    </div>
                  ))}
                </div>
                <div>
                  <h3 className="font-semibold text-sm text-gray-900 mb-3">Active Interventions</h3>
                  {data.active_interventions.slice(0, 4).length === 0 ? (
                    <div>
                      <p className="text-sm text-gray-400 mb-3">No active interventions.</p>
                      <button
                        onClick={generateInterventions}
                        className="text-xs bg-blue-600 text-white px-3 py-1.5 rounded hover:bg-blue-700"
                      >
                        Generate Recommendations
                      </button>
                    </div>
                  ) : data.active_interventions.slice(0, 4).map(iv => (
                    <div key={iv.id} className="mb-2 px-3 py-2 rounded text-xs bg-blue-50 text-blue-700 border border-blue-100">
                      {iv.title}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Warnings Tab */}
            {activeTab === 'warnings' && (
              <div>
                {data.active_warnings.length === 0 ? (
                  <div className="text-center py-8">
                    <p className="text-4xl mb-2">✅</p>
                    <p className="text-gray-500">No active warnings</p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {data.active_warnings.map(w => (
                      <div key={w.id} className={`border rounded-lg p-4 ${SEV_COLORS[w.severity]}`}>
                        <div className="flex justify-between items-start">
                          <div>
                            <p className="font-medium text-sm">{w.title}</p>
                            <p className="text-xs mt-1 opacity-80 capitalize">{w.warning_type.replace('_', ' ')} · {w.severity}</p>
                          </div>
                          <button
                            onClick={() => acknowledgeWarning(w.id)}
                            disabled={acknowledging === w.id}
                            className="text-xs px-3 py-1 bg-white bg-opacity-60 rounded hover:bg-opacity-80 transition"
                          >
                            {acknowledging === w.id ? '…' : 'Acknowledge'}
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}

            {/* Interventions Tab */}
            {activeTab === 'interventions' && (
              <div>
                <div className="flex justify-between items-center mb-4">
                  <h3 className="font-semibold text-sm text-gray-900">Intervention Plans</h3>
                  <button
                    onClick={generateInterventions}
                    className="text-xs bg-blue-600 text-white px-3 py-1.5 rounded hover:bg-blue-700"
                  >
                    + Generate New
                  </button>
                </div>
                {data.active_interventions.length === 0 ? (
                  <p className="text-sm text-gray-400">No intervention plans active.</p>
                ) : (
                  <div className="space-y-4">
                    {data.active_interventions.map(iv => (
                      <div key={iv.id} className="border border-gray-200 rounded-lg p-4">
                        <div className="flex justify-between items-start mb-2">
                          <p className="font-medium text-sm text-gray-900">{iv.title}</p>
                          <div className="flex gap-2">
                            <span className={`text-xs px-2 py-0.5 rounded-full ${iv.priority === 'high' ? 'bg-red-100 text-red-700' : iv.priority === 'medium' ? 'bg-amber-100 text-amber-700' : 'bg-gray-100 text-gray-600'}`}>
                              {iv.priority}
                            </span>
                            <span className="text-xs px-2 py-0.5 rounded-full bg-blue-50 text-blue-700 capitalize">
                              {iv.status.replace('_', ' ')}
                            </span>
                          </div>
                        </div>
                        {iv.description && <p className="text-sm text-gray-600">{iv.description}</p>}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}

            {/* Timeline Tab */}
            {activeTab === 'timeline' && (
              <div>
                <h3 className="font-semibold text-sm text-gray-900 mb-4">Academic Health Timeline</h3>
                {data.timeline_summary.length === 0 ? (
                  <p className="text-sm text-gray-400">No semester history available.</p>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="bg-gray-50 text-xs text-gray-500 uppercase">
                          <th className="px-3 py-2 text-left">Period</th>
                          <th className="px-3 py-2 text-right">Term GPA</th>
                          <th className="px-3 py-2 text-right">CGPA</th>
                          <th className="px-3 py-2 text-right">Credits</th>
                          <th className="px-3 py-2 text-right">Cumulative</th>
                          <th className="px-3 py-2 text-center">Standing</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-100">
                        {data.timeline_summary.map((t, i) => (
                          <tr key={i} className="hover:bg-gray-50">
                            <td className="px-3 py-2 text-gray-700">
                              {t.period}{t.is_summer && <span className="ml-1 text-xs text-orange-500">(Summer)</span>}
                            </td>
                            <td className={`px-3 py-2 text-right font-medium ${t.term_gpa >= 2.0 ? 'text-emerald-600' : 'text-red-600'}`}>
                              {t.term_gpa.toFixed(3)}
                            </td>
                            <td className={`px-3 py-2 text-right font-medium ${t.cgpa >= 2.0 ? 'text-emerald-600' : 'text-red-600'}`}>
                              {t.cgpa.toFixed(3)}
                            </td>
                            <td className="px-3 py-2 text-right text-gray-600">{t.credits_earned}</td>
                            <td className="px-3 py-2 text-right text-gray-600">{t.cumulative_earned}</td>
                            <td className="px-3 py-2 text-center">
                              <span className={`text-xs px-2 py-0.5 rounded-full capitalize ${
                                t.standing === 'honors' ? 'bg-purple-100 text-purple-700' :
                                t.standing === 'good' ? 'bg-green-100 text-green-700' :
                                t.standing === 'warning' ? 'bg-yellow-100 text-yellow-700' :
                                'bg-red-100 text-red-700'
                              }`}>{t.standing}</span>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
