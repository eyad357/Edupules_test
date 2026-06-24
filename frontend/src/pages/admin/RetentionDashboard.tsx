// EduGuard AI — Sprint 5 Module H: Retention Analytics Dashboard
// /frontend/src/pages/admin/RetentionDashboard.tsx
// v5.0 — Dean / Registrar / Academic Affairs visibility

import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';

const API = '/api/v2/sprint5/retention';
const SUCCESS_API = '/api/v2/sprint5/student-success';

interface RetentionData {
  total_students: number; active_students: number;
  below_2_cgpa: number; between_2_and_2_5_cgpa: number; above_2_5_cgpa: number;
  dismissal_risk_count: number; probation_count: number;
  expected_graduates: number; graduation_delay_count: number;
  critical_warnings_count: number;
  avg_success_score: number; avg_cgpa: number; retention_rate: number;
  cgpa_distribution: Array<{ label: string; count: number; pct: number }>;
  risk_trend: Array<{ date: string; dismissal_risk: number; probation: number; critical_warnings: number }>;
  success_trend: Array<{ date: string; avg_score: number; avg_cgpa: number; retention_rate: number }>;
}

interface AtRiskStudent {
  student_id: number; name: string; cgpa: number; standing: string; credits: number;
}

type RiskFilter = 'below_2' | 'monitoring' | 'dismissal_risk' | 'probation';

const RISK_LABELS: Record<RiskFilter, string> = {
  below_2: 'Below 2.0 CGPA',
  monitoring: '2.0 – 2.5 CGPA (Monitoring)',
  dismissal_risk: 'Dismissal Risk',
  probation: 'On Probation',
};

export default function RetentionDashboard() {
  const { token } = useAuth();
  const [data, setData]     = useState<RetentionData | null>(null);
  const [atRisk, setAtRisk] = useState<AtRiskStudent[]>([]);
  const [riskFilter, setRiskFilter] = useState<RiskFilter>('below_2');
  const [loading, setLoading] = useState(true);
  const [snapLoading, setSnapLoading] = useState(false);
  const [atRiskLoading, setAtRiskLoading] = useState(false);
  const [atRiskTotal, setAtRiskTotal] = useState(0);

  const hdr = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

  const loadDashboard = async () => {
    setLoading(true);
    try {
      const r = await fetch(`${API}/dashboard`, { headers: hdr });
      if (r.ok) setData(await r.json());
    } catch {}
    setLoading(false);
  };

  const loadAtRisk = async (filter: RiskFilter) => {
    setAtRiskLoading(true);
    try {
      const r = await fetch(`${API}/at-risk?risk_type=${filter}&limit=50`, { headers: hdr });
      if (r.ok) {
        const d = await r.json();
        setAtRisk(d.items || []);
        setAtRiskTotal(d.total || 0);
      }
    } catch {}
    setAtRiskLoading(false);
  };

  const computeSnapshot = async () => {
    setSnapLoading(true);
    try {
      await fetch(`${API}/snapshot`, { method: 'POST', headers: hdr });
      await loadDashboard();
    } catch {}
    setSnapLoading(false);
  };

  useEffect(() => { loadDashboard(); }, []);
  useEffect(() => { loadAtRisk(riskFilter); }, [riskFilter]);

  if (loading) return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="text-center">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600 mx-auto mb-3"></div>
        <p className="text-gray-500 text-sm">Loading retention analytics…</p>
      </div>
    </div>
  );

  const d = data!;

  const kpis = [
    { label: 'Total Students',      value: d.total_students,     icon: '👥', color: 'text-gray-900' },
    { label: 'Dismissal Risk',       value: d.dismissal_risk_count, icon: '🚨', color: 'text-red-600' },
    { label: 'CGPA Monitoring Zone', value: d.between_2_and_2_5_cgpa, icon: '⚠️', color: 'text-amber-600' },
    { label: 'Expected Graduates',   value: d.expected_graduates, icon: '🎓', color: 'text-emerald-600' },
    { label: 'On Probation',         value: d.probation_count,   icon: '📋', color: 'text-orange-600' },
    { label: 'Critical Warnings',    value: d.critical_warnings_count, icon: '🔔', color: 'text-red-500' },
    { label: 'Avg CGPA',             value: d.avg_cgpa?.toFixed(3) || '—', icon: '📊', color: 'text-blue-600' },
    { label: 'Retention Rate',       value: `${d.retention_rate?.toFixed(1) || '—'}%`, icon: '📈', color: 'text-emerald-600' },
  ];

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">

        {/* Header */}
        <div className="mb-6 flex justify-between items-start">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">📊 Retention Analytics</h1>
            <p className="text-gray-500 text-sm mt-1">
              Dean · Registrar · Academic Affairs — Institutional Risk Overview
            </p>
          </div>
          <button
            onClick={computeSnapshot}
            disabled={snapLoading}
            className="bg-blue-600 text-white text-sm px-4 py-2 rounded hover:bg-blue-700 disabled:opacity-40 transition"
          >
            {snapLoading ? 'Computing…' : '🔄 Refresh Snapshot'}
          </button>
        </div>

        {/* KPI Grid */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          {kpis.map(k => (
            <div key={k.label} className="bg-white rounded-lg border border-gray-200 p-4">
              <div className="flex items-center justify-between">
                <p className="text-xs text-gray-500 uppercase tracking-wide">{k.label}</p>
                <span className="text-xl">{k.icon}</span>
              </div>
              <p className={`text-2xl font-bold mt-2 ${k.color}`}>{k.value}</p>
            </div>
          ))}
        </div>

        {/* CGPA Distribution */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          <div className="bg-white rounded-lg border border-gray-200 p-5">
            <h3 className="font-semibold text-sm text-gray-900 mb-4">CGPA Distribution</h3>
            <div className="space-y-4">
              {d.cgpa_distribution.map(bucket => (
                <div key={bucket.label}>
                  <div className="flex justify-between text-sm mb-1">
                    <span className="text-gray-700">{bucket.label}</span>
                    <span className="font-medium text-gray-900">{bucket.count} ({bucket.pct}%)</span>
                  </div>
                  <div className="w-full bg-gray-100 rounded-full h-3">
                    <div
                      className={`h-3 rounded-full ${
                        bucket.label.includes('Below') ? 'bg-red-500' :
                        bucket.label.includes('2.5') ? 'bg-amber-500' : 'bg-emerald-500'
                      }`}
                      style={{ width: `${bucket.pct}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>

            {/* Avg Success Score */}
            <div className="mt-6 pt-4 border-t border-gray-100">
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-500">Average Success Score</span>
                <span className={`text-xl font-bold ${
                  d.avg_success_score >= 70 ? 'text-emerald-600' :
                  d.avg_success_score >= 50 ? 'text-amber-600' : 'text-red-600'
                }`}>{d.avg_success_score?.toFixed(1) || '—'}/100</span>
              </div>
              <div className="mt-2 bg-gray-100 rounded-full h-2">
                <div
                  className={`h-2 rounded-full ${d.avg_success_score >= 70 ? 'bg-emerald-500' : d.avg_success_score >= 50 ? 'bg-amber-500' : 'bg-red-500'}`}
                  style={{ width: `${d.avg_success_score || 0}%` }}
                />
              </div>
            </div>
          </div>

          {/* Risk Trend */}
          <div className="bg-white rounded-lg border border-gray-200 p-5">
            <h3 className="font-semibold text-sm text-gray-900 mb-4">Risk Trend History</h3>
            {d.risk_trend.length === 0 ? (
              <p className="text-sm text-gray-400 py-4 text-center">
                No trend data yet. Generate a snapshot to begin tracking.
              </p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-xs">
                  <thead>
                    <tr className="text-gray-500 border-b border-gray-100">
                      <th className="pb-2 text-left">Date</th>
                      <th className="pb-2 text-right">Dismissal Risk</th>
                      <th className="pb-2 text-right">Probation</th>
                      <th className="pb-2 text-right">Critical Warnings</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-50">
                    {d.risk_trend.map((row, i) => (
                      <tr key={i}>
                        <td className="py-1.5 text-gray-600">{row.date}</td>
                        <td className="py-1.5 text-right text-red-600 font-medium">{row.dismissal_risk}</td>
                        <td className="py-1.5 text-right text-amber-600 font-medium">{row.probation}</td>
                        <td className="py-1.5 text-right text-orange-600 font-medium">{row.critical_warnings}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>

        {/* At-Risk Students Table */}
        <div className="bg-white rounded-lg border border-gray-200">
          <div className="px-5 py-4 border-b border-gray-200">
            <div className="flex justify-between items-center">
              <h3 className="font-semibold text-sm text-gray-900">
                At-Risk Students
                <span className="ml-2 text-xs text-gray-400">({atRiskTotal} total)</span>
              </h3>
              <div className="flex gap-2">
                {(Object.keys(RISK_LABELS) as RiskFilter[]).map(f => (
                  <button
                    key={f}
                    onClick={() => setRiskFilter(f)}
                    className={`text-xs px-3 py-1 rounded-full transition ${
                      riskFilter === f
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                    }`}
                  >
                    {RISK_LABELS[f]}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {atRiskLoading ? (
            <div className="p-8 text-center text-gray-400 text-sm">Loading…</div>
          ) : atRisk.length === 0 ? (
            <div className="p-8 text-center">
              <p className="text-2xl mb-2">✅</p>
              <p className="text-gray-400 text-sm">No students in this risk category.</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="bg-gray-50 text-xs text-gray-500 uppercase">
                    <th className="px-5 py-2 text-left">Student</th>
                    <th className="px-5 py-2 text-right">CGPA</th>
                    <th className="px-5 py-2 text-center">Standing</th>
                    <th className="px-5 py-2 text-right">Credits Earned</th>
                    <th className="px-5 py-2 text-center">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {atRisk.map(s => (
                    <tr key={s.student_id} className="hover:bg-gray-50">
                      <td className="px-5 py-3">
                        <span className="font-medium text-gray-900">{s.name}</span>
                        <span className="ml-2 text-xs text-gray-400">#{s.student_id}</span>
                      </td>
                      <td className={`px-5 py-3 text-right font-bold ${s.cgpa < 2.0 ? 'text-red-600' : s.cgpa < 2.5 ? 'text-amber-600' : 'text-gray-700'}`}>
                        {s.cgpa.toFixed(3)}
                      </td>
                      <td className="px-5 py-3 text-center">
                        <span className={`text-xs px-2 py-0.5 rounded-full capitalize ${
                          s.standing === 'dismissed' ? 'bg-red-100 text-red-700' :
                          s.standing === 'probation' ? 'bg-orange-100 text-orange-700' :
                          s.standing === 'warning' ? 'bg-yellow-100 text-yellow-700' :
                          'bg-green-100 text-green-700'
                        }`}>{s.standing}</span>
                      </td>
                      <td className="px-5 py-3 text-right text-gray-600">{s.credits}</td>
                      <td className="px-5 py-3 text-center">
                        <a
                          href={`/success/${s.student_id}`}
                          className="text-xs text-blue-600 hover:underline"
                        >
                          View Dashboard →
                        </a>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
