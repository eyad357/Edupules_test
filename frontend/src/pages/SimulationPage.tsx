import { useState, useEffect, useCallback } from 'react';
import { Brain, ArrowRight, TrendingUp, TrendingDown, AlertTriangle, Sparkles, RotateCcw } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Badge } from '../components/ui/Badge';
import { ProgressBar } from '../components/ui/ProgressBar';
import { cn } from '../lib/utils';

const BASE = (import.meta as any).env?.VITE_FASTAPI_URL ?? 'http://localhost:8000/api/v1';
const TOKEN_KEY = 'eduguard_token';
const authHeader = () => ({ Authorization: `Bearer ${localStorage.getItem(TOKEN_KEY)}` });

interface LiveStudent {
  id: number; name: string; student_number: string; major: string;
  year: number; gpa: number; risk_level: string; probability: number;
  grades_impact: number; attendance_impact: number; activity_impact: number;
  dropout_probability: number; graduation_delay_likelihood: number; scholarship_eligibility: number;
}

interface SimResult {
  projected_risk: { probability: number; risk_level: string };
  projected_gpa: number;
  improvements: string[];
  warnings: string[];
  dropout_probability: number;
  graduation_delay: number;
  scholarship_eligibility: number;
}

function simulateLocally(student: LiveStudent, newGrade: number, newAttendance: number, newActivity: number): SimResult {
  const gradeBoost   = (newGrade - 70) * 0.5;
  const attendBoost  = (newAttendance - (student.attendance_impact || 60)) * 0.3;
  const activityBoost = (newActivity - 50) * 0.2;
  const totalReduction = gradeBoost + attendBoost + activityBoost;

  const projProb = Math.max(2, Math.min(99, student.probability - totalReduction));
  const projGpa  = Math.min(4.0, student.gpa + (newGrade - 70) * 0.01);

  let risk_level = 'Normal';
  if (projProb >= 70) risk_level = 'Critical';
  else if (projProb >= 50) risk_level = 'High';
  else if (projProb >= 25) risk_level = 'Low';

  const improvements: string[] = [];
  const warnings: string[] = [];
  if (newGrade >= 85) improvements.push('Grade improvement significantly reduces dropout risk');
  if (newAttendance >= 85) improvements.push('Attendance above 85% stabilises academic standing');
  if (newActivity >= 70) improvements.push('Platform activity correlates with +0.3 GPA improvement');
  if (projGpa >= 3.5) improvements.push('GPA trajectory qualifies for Dean\'s List consideration');
  if (newGrade < 60)  warnings.push('Grade below 60% increases course failure probability by 60%');
  if (newAttendance < 70) warnings.push('Attendance below 70% risks FL grade per university policy');

  return {
    projected_risk: { probability: Math.round(projProb), risk_level },
    projected_gpa: Math.round(projGpa * 100) / 100,
    improvements,
    warnings,
    dropout_probability: Math.max(2, student.dropout_probability - totalReduction * 0.7),
    graduation_delay: Math.max(0, student.graduation_delay_likelihood - totalReduction * 0.5),
    scholarship_eligibility: Math.min(100, student.scholarship_eligibility + totalReduction * 0.4),
  };
}

const riskColor: Record<string, string> = {
  Normal: 'text-emerald-600', Low: 'text-yellow-600',
  High: 'text-orange-600', Critical: 'text-red-600',
};

export function SimulationPage() {
  const [students, setStudents] = useState<LiveStudent[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [newGrade, setNewGrade] = useState(80);
  const [newAttendance, setNewAttendance] = useState(85);
  const [newActivity, setNewActivity] = useState(70);
  const [result, setResult] = useState<SimResult | null>(null);
  const [isSimulating, setIsSimulating] = useState(false);

  const fetchStudents = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch(`${BASE}/analytics/students?limit=100`, { headers: authHeader() });
      if (!res.ok) throw new Error(`${res.status}`);
      const data = await res.json();
      const list: LiveStudent[] = (data.students ?? data ?? []).map((s: any) => ({
        id: s.id, name: s.name, student_number: s.student_number,
        major: s.major, year: s.year ?? 1, gpa: s.gpa,
        risk_level: s.risk_level ?? 'Normal',
        probability: s.risk_probability ?? s.probability ?? 0,
        grades_impact: s.grades_impact ?? 0,
        attendance_impact: s.attendance_impact ?? 0,
        activity_impact: s.activity_impact ?? 0,
        dropout_probability: s.dropout_probability ?? 0,
        graduation_delay_likelihood: s.graduation_delay_likelihood ?? 0,
        scholarship_eligibility: s.scholarship_eligibility ?? 0,
      }));
      setStudents(list);
      // Pre-select first at-risk student for better demo
      const atRisk = list.find(s => s.risk_level === 'High' || s.risk_level === 'Critical');
      if (atRisk) setSelectedId(atRisk.id);
      else if (list.length > 0) setSelectedId(list[0].id);
    } catch { /* fallback */ }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { fetchStudents(); }, [fetchStudents]);

  const student = students.find(s => s.id === selectedId);

  const runSimulation = () => {
    if (!student) return;
    setIsSimulating(true);
    setTimeout(() => {
      setResult(simulateLocally(student, newGrade, newAttendance, newActivity));
      setIsSimulating(false);
    }, 1200);
  };

  const reset = () => { setResult(null); setNewGrade(80); setNewAttendance(85); setNewActivity(70); };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="w-8 h-8 border-2 border-red-600 border-t-transparent rounded-full animate-spin mx-auto" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900 dark:text-white">What-If Simulator</h1>
        <p className="text-neutral-500 dark:text-neutral-400 mt-0.5">
          Simulate the impact of grade, attendance, and activity changes on student risk — powered by live database data
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Controls */}
        <div className="lg:col-span-1 space-y-4">
          <Card title="Simulation Controls" subtitle="Adjust parameters">
            <div className="space-y-5">
              {/* Student Selector */}
              <div>
                <label className="block text-xs font-semibold text-neutral-500 uppercase tracking-wide mb-2">
                  Select Student
                </label>
                <select
                  value={selectedId ?? ''}
                  onChange={e => { setSelectedId(Number(e.target.value)); setResult(null); }}
                  className="w-full px-3 py-2 text-sm border border-neutral-200 dark:border-neutral-700 rounded-lg bg-white dark:bg-neutral-900 text-neutral-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-red-500"
                >
                  {students.map(s => (
                    <option key={s.id} value={s.id}>
                      {s.name} ({s.risk_level}) — GPA {s.gpa.toFixed(2)}
                    </option>
                  ))}
                </select>
              </div>

              {/* Sliders */}
              {[
                { label: 'New Average Grade', key: 'grade', value: newGrade, set: setNewGrade, min: 0, max: 100, unit: '%' },
                { label: 'New Attendance Rate', key: 'att', value: newAttendance, set: setNewAttendance, min: 0, max: 100, unit: '%' },
                { label: 'New Activity Score', key: 'act', value: newActivity, set: setNewActivity, min: 0, max: 100, unit: '%' },
              ].map(({ label, key, value, set, min, max, unit }) => (
                <div key={key}>
                  <div className="flex items-center justify-between mb-2">
                    <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300">{label}</label>
                    <span className="text-sm font-bold text-red-600">{value}{unit}</span>
                  </div>
                  <input
                    type="range" min={min} max={max} value={value}
                    onChange={e => { set(Number(e.target.value)); setResult(null); }}
                    className="w-full h-2 bg-neutral-200 dark:bg-neutral-700 rounded-lg appearance-none cursor-pointer accent-red-600"
                  />
                  <div className="flex justify-between text-xs text-neutral-400 mt-1">
                    <span>{min}{unit}</span><span>{max}{unit}</span>
                  </div>
                </div>
              ))}

              <div className="flex gap-2 pt-2">
                <button
                  onClick={runSimulation}
                  disabled={isSimulating || !student}
                  className="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-lg bg-red-600 hover:bg-red-700 text-white text-sm font-semibold transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isSimulating ? (
                    <>
                      <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      Simulating…
                    </>
                  ) : (
                    <><Brain className="w-4 h-4" /> Run Simulation</>
                  )}
                </button>
                {result && (
                  <button onClick={reset} className="px-3 py-2.5 rounded-lg border border-neutral-200 dark:border-neutral-700 text-neutral-600 dark:text-neutral-400 hover:bg-neutral-50 dark:hover:bg-neutral-800 transition-colors">
                    <RotateCcw className="w-4 h-4" />
                  </button>
                )}
              </div>
            </div>
          </Card>

          {/* Current student snapshot */}
          {student && (
            <Card title="Current Profile" subtitle="Live database values">
              <div className="space-y-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-red-100 dark:bg-red-900/20 flex items-center justify-center">
                    <span className="text-sm font-bold text-red-700">{student.name.charAt(0)}</span>
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-neutral-900 dark:text-white">{student.name}</p>
                    <p className="text-xs text-neutral-500">{student.major} · Year {student.year}</p>
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-2 text-xs">
                  <div className="p-2 bg-neutral-50 dark:bg-neutral-800 rounded">
                    <p className="text-neutral-500">GPA</p>
                    <p className="font-bold text-neutral-900 dark:text-white">{student.gpa.toFixed(2)}</p>
                  </div>
                  <div className="p-2 bg-neutral-50 dark:bg-neutral-800 rounded">
                    <p className="text-neutral-500">Risk</p>
                    <p className={cn('font-bold', riskColor[student.risk_level])}>{student.risk_level}</p>
                  </div>
                  <div className="p-2 bg-neutral-50 dark:bg-neutral-800 rounded">
                    <p className="text-neutral-500">Probability</p>
                    <p className="font-bold text-neutral-900 dark:text-white">{student.probability.toFixed(0)}%</p>
                  </div>
                  <div className="p-2 bg-neutral-50 dark:bg-neutral-800 rounded">
                    <p className="text-neutral-500">Scholarship</p>
                    <p className="font-bold text-neutral-900 dark:text-white">{student.scholarship_eligibility.toFixed(0)}%</p>
                  </div>
                </div>
              </div>
            </Card>
          )}
        </div>

        {/* Results */}
        <div className="lg:col-span-2">
          {!result ? (
            <div className="h-full flex items-center justify-center border-2 border-dashed border-neutral-200 dark:border-neutral-700 rounded-xl p-12">
              <div className="text-center">
                <Sparkles className="w-12 h-12 text-neutral-300 dark:text-neutral-600 mx-auto mb-4" />
                <p className="text-neutral-600 dark:text-neutral-400 font-medium">Select a student and run the simulation</p>
                <p className="text-sm text-neutral-400 mt-1">Adjust the parameters on the left, then click Run Simulation</p>
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              {/* Before / After */}
              <Card title="Simulation Results" subtitle="Before → After comparison">
                <div className="grid grid-cols-2 gap-4">
                  {/* Before */}
                  <div className="p-4 rounded-lg bg-neutral-50 dark:bg-neutral-800 space-y-3">
                    <p className="text-xs font-semibold text-neutral-500 uppercase tracking-wide">Current</p>
                    <div className="text-center">
                      <p className={cn('text-4xl font-bold', riskColor[student!.risk_level])}>
                        {student!.probability.toFixed(0)}%
                      </p>
                      <Badge variant={student!.risk_level.toLowerCase() as any} className="mt-2">{student!.risk_level}</Badge>
                    </div>
                    <div className="space-y-1.5 text-xs text-neutral-500">
                      <div className="flex justify-between"><span>GPA</span><span className="font-medium text-neutral-900 dark:text-white">{student!.gpa.toFixed(2)}</span></div>
                      <div className="flex justify-between"><span>Dropout Risk</span><span className="font-medium text-red-600">{student!.dropout_probability.toFixed(0)}%</span></div>
                      <div className="flex justify-between"><span>Scholarship</span><span className="font-medium text-emerald-600">{student!.scholarship_eligibility.toFixed(0)}%</span></div>
                    </div>
                  </div>

                  {/* After */}
                  <div className="p-4 rounded-lg bg-emerald-50 dark:bg-emerald-900/10 border border-emerald-200 dark:border-emerald-900/30 space-y-3">
                    <p className="text-xs font-semibold text-emerald-600 uppercase tracking-wide">Projected</p>
                    <div className="text-center">
                      <p className={cn('text-4xl font-bold', riskColor[result.projected_risk.risk_level])}>
                        {result.projected_risk.probability}%
                      </p>
                      <Badge variant={result.projected_risk.risk_level.toLowerCase() as any} className="mt-2">
                        {result.projected_risk.risk_level}
                      </Badge>
                    </div>
                    <div className="space-y-1.5 text-xs text-neutral-500">
                      <div className="flex justify-between"><span>GPA</span>
                        <span className="font-medium text-neutral-900 dark:text-white flex items-center gap-1">
                          {result.projected_gpa.toFixed(2)}
                          {result.projected_gpa > student!.gpa
                            ? <TrendingUp className="w-3 h-3 text-emerald-500" />
                            : <TrendingDown className="w-3 h-3 text-red-500" />}
                        </span>
                      </div>
                      <div className="flex justify-between"><span>Dropout Risk</span>
                        <span className="font-medium text-red-600">{result.dropout_probability.toFixed(0)}%</span>
                      </div>
                      <div className="flex justify-between"><span>Scholarship</span>
                        <span className="font-medium text-emerald-600">{result.scholarship_eligibility.toFixed(0)}%</span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Delta arrow */}
                <div className="flex items-center justify-center gap-2 mt-4 p-3 rounded-lg bg-neutral-100 dark:bg-neutral-800">
                  <span className="text-sm text-neutral-500">Risk change:</span>
                  <ArrowRight className="w-4 h-4 text-neutral-400" />
                  <span className={cn('text-sm font-bold', result.projected_risk.probability < student!.probability ? 'text-emerald-600' : 'text-red-600')}>
                    {result.projected_risk.probability < student!.probability ? '↓' : '↑'}
                    {Math.abs(result.projected_risk.probability - student!.probability).toFixed(0)}%
                    {result.projected_risk.probability < student!.probability ? ' improvement' : ' increase'}
                  </span>
                </div>
              </Card>

              {/* Improvements */}
              {result.improvements.length > 0 && (
                <Card title="Projected Improvements" subtitle="Based on simulation parameters">
                  <div className="space-y-2">
                    {result.improvements.map((imp, i) => (
                      <div key={i} className="flex items-start gap-2 p-3 rounded-lg bg-emerald-50 dark:bg-emerald-900/10">
                        <TrendingUp className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                        <p className="text-sm text-emerald-800 dark:text-emerald-300">{imp}</p>
                      </div>
                    ))}
                  </div>
                </Card>
              )}

              {/* Warnings */}
              {result.warnings.length > 0 && (
                <Card title="Risk Warnings" subtitle="Areas of concern">
                  <div className="space-y-2">
                    {result.warnings.map((w, i) => (
                      <div key={i} className="flex items-start gap-2 p-3 rounded-lg bg-red-50 dark:bg-red-900/10">
                        <AlertTriangle className="w-4 h-4 text-red-600 shrink-0 mt-0.5" />
                        <p className="text-sm text-red-800 dark:text-red-300">{w}</p>
                      </div>
                    ))}
                  </div>
                </Card>
              )}

              {/* Metric bars */}
              <Card title="Metric Comparison" subtitle="Side-by-side progress bars">
                <div className="space-y-4">
                  {[
                    { label: 'Risk Probability', current: student!.probability, projected: result.projected_risk.probability, lowerBetter: true },
                    { label: 'Dropout Risk',     current: student!.dropout_probability, projected: result.dropout_probability, lowerBetter: true },
                    { label: 'Scholarship %',    current: student!.scholarship_eligibility, projected: result.scholarship_eligibility, lowerBetter: false },
                    { label: 'Graduation Delay', current: student!.graduation_delay_likelihood, projected: result.graduation_delay, lowerBetter: true },
                  ].map(({ label, current, projected, lowerBetter }) => {
                    const improved = lowerBetter ? projected < current : projected > current;
                    return (
                      <div key={label}>
                        <div className="flex justify-between text-xs mb-1">
                          <span className="text-neutral-500">{label}</span>
                          <span className={cn('font-medium', improved ? 'text-emerald-600' : 'text-red-600')}>
                            {current.toFixed(0)}% → {projected.toFixed(0)}%
                          </span>
                        </div>
                        <div className="flex gap-2">
                          <ProgressBar value={current} size="sm" className="flex-1" />
                          <ProgressBar value={projected} size="sm" className="flex-1" />
                        </div>
                        <div className="flex justify-between text-xs text-neutral-400 mt-0.5">
                          <span>Current</span><span>Projected</span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </Card>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
