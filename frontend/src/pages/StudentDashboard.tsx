import { useState, useEffect, useCallback } from 'react';
import {
  Target, Award, Flame, BookOpen, Shield, Calendar,
  TrendingUp, TrendingDown, GraduationCap, Users,
  Bell, CheckCircle, ClipboardList,
  Star, AlertTriangle, Info,
} from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Badge } from '../components/ui/Badge';
import { ProgressBar } from '../components/ui/ProgressBar';
import { cn } from '../lib/utils';
import {
  AreaChart, Area, BarChart, Bar,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, ReferenceLine,
} from 'recharts';

const BASE      = (import.meta as any).env?.VITE_FASTAPI_URL ?? 'http://localhost:8000/api/v1';
const TOKEN_KEY = 'eduguard_token';
const authHdr   = () => ({ Authorization: `Bearer ${localStorage.getItem(TOKEN_KEY)}` });

// ── Types ─────────────────────────────────────────────────────────────────────

interface StudentInfo {
  id: number; name: string; email: string;
  student_number: string; major: string; year: number;
  gpa: number; cgpa: number; is_scholarship: boolean;
  enrollment_date: string | null; phone: string | null;
  advisor: string | null; department: string; department_code: string | null;
  academic_standing: string;
  total_credits_earned: number; total_credits_attempted: number;
  credits_to_graduation: number;
}

interface RiskInfo {
  level: string; probability: number; trend: string;
  grades_impact: number; attendance_impact: number;
  dropout_probability: number; graduation_delay_likelihood: number;
  scholarship_eligibility: number;
  explanation: string | null; recommendations: string[];
}

interface CourseEnrollment {
  course_id: number; code: string; name: string;
  grade: number | null; semester: string; status?: string;
}

interface TermGPA {
  term: string; term_name: string; academic_year: number;
  term_gpa: number; cgpa: number;
  credits_attempted: number; credits_earned: number; credits_failed: number;
  cumulative_attempted: number; cumulative_earned: number;
  standing: string; honors: string; dean_list: boolean;
}

interface InterventionPlan {
  id: number; title: string; description: string;
  status: string; priority: string; deadline: string | null;
}

interface QuizStats { total: number; avg_score: number; passed: number; }

interface DashboardData {
  student: StudentInfo;
  risk: RiskInfo | null;
  enrollments: CourseEnrollment[];
  completed_courses: CourseEnrollment[];
  term_gpa_history: TermGPA[];
  attendance_rate: number;
  intervention_plans: InterventionPlan[];
  unread_notifications: number;
  quiz_stats: QuizStats;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const RISK_PALETTE: Record<string, { text: string; bg: string; border: string; badge: string }> = {
  Normal:   { text: 'text-emerald-600', bg: 'bg-emerald-50 dark:bg-emerald-900/20', border: 'border-emerald-200 dark:border-emerald-800', badge: 'normal' },
  Low:      { text: 'text-yellow-600',  bg: 'bg-yellow-50 dark:bg-yellow-900/20',   border: 'border-yellow-200 dark:border-yellow-800',   badge: 'warning' },
  High:     { text: 'text-orange-600',  bg: 'bg-orange-50 dark:bg-orange-900/20',   border: 'border-orange-200 dark:border-orange-800',   badge: 'critical' },
  Critical: { text: 'text-red-700',     bg: 'bg-red-50 dark:bg-red-900/20',         border: 'border-red-300 dark:border-red-800',         badge: 'critical' },
};

const STANDING_LABEL: Record<string, { label: string; color: string }> = {
  active:    { label: 'Good Standing',    color: 'text-emerald-600' },
  warning:   { label: 'Academic Warning', color: 'text-yellow-600'  },
  probation: { label: 'Probation',        color: 'text-red-600'     },
  suspended: { label: 'Suspended',        color: 'text-red-700'     },
  excellent: { label: 'Dean\'s List',     color: 'text-emerald-600' },
};

function yearLabel(y: number) {
  return ['', 'Freshman', 'Sophomore', 'Junior', 'Senior', 'Graduate'][y] ?? `Year ${y}`;
}

function gradeColor(g: number) {
  if (g >= 90) return 'text-emerald-600';
  if (g >= 75) return 'text-blue-600';
  if (g >= 60) return 'text-yellow-600';
  return 'text-red-600';
}

function letterGrade(g: number) {
  if (g >= 97) return 'A+';
  if (g >= 93) return 'A';
  if (g >= 90) return 'A−';
  if (g >= 87) return 'B+';
  if (g >= 83) return 'B';
  if (g >= 80) return 'B−';
  if (g >= 77) return 'C+';
  if (g >= 73) return 'C';
  if (g >= 70) return 'C−';
  if (g >= 67) return 'D+';
  if (g >= 60) return 'D';
  return 'F';
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

function StatCard({ icon: Icon, label, value, sub, color = 'red' }: {
  icon: React.ElementType; label: string; value: string | number; sub?: string; color?: string;
}) {
  const bg  = `bg-${color}-50 dark:bg-${color}-900/20`;
  const ico = `text-${color}-600 dark:text-${color}-400`;
  return (
    <div className="bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 rounded-xl p-4 flex items-center gap-4">
      <div className={cn('w-11 h-11 rounded-xl flex items-center justify-center shrink-0', bg)}>
        <Icon className={cn('w-5 h-5', ico)} />
      </div>
      <div className="min-w-0">
        <p className="text-xs text-neutral-500 dark:text-neutral-400 truncate">{label}</p>
        <p className="text-xl font-bold text-neutral-900 dark:text-white leading-tight">{value}</p>
        {sub && <p className="text-xs text-neutral-400 mt-0.5 truncate">{sub}</p>}
      </div>
    </div>
  );
}

// ── Main Component ────────────────────────────────────────────────────────────

export function StudentDashboard() {
  const [data, setData]       = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState<string | null>(null);
  const [tab, setTab]         = useState<'overview' | 'courses' | 'progress'>('overview');

  const fetchAll = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`${BASE}/analytics/student-dashboard`, { headers: authHdr() });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      setData(await res.json());
    } catch (e: any) {
      setError(e.message ?? 'Failed to load dashboard');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchAll(); }, [fetchAll]);

  if (loading) return (
    <div className="flex items-center justify-center h-64">
      <div className="text-center space-y-3">
        <div className="w-8 h-8 border-2 border-red-600 border-t-transparent rounded-full animate-spin mx-auto" />
        <p className="text-sm text-neutral-500">Loading your dashboard…</p>
      </div>
    </div>
  );

  if (error || !data) return (
    <div className="flex items-center justify-center h-64">
      <div className="text-center space-y-3">
        <AlertTriangle className="w-10 h-10 text-red-500 mx-auto" />
        <p className="text-red-600 font-medium">Failed to load dashboard</p>
        <p className="text-sm text-neutral-500">{error ?? 'Student profile not found'}</p>
        <button onClick={fetchAll} className="btn-primary text-sm px-4 py-2">Retry</button>
      </div>
    </div>
  );

  const { student, risk, enrollments, completed_courses, term_gpa_history,
          attendance_rate, intervention_plans, unread_notifications, quiz_stats } = data;

  const riskPalette = RISK_PALETTE[risk?.level ?? 'Normal'];
  const standing    = STANDING_LABEL[student.academic_standing] ?? { label: student.academic_standing, color: 'text-neutral-600' };

  // Gamification
  const points        = Math.round(student.cgpa * 800);
  const level         = student.cgpa >= 3.7 ? 'Gold' : student.cgpa >= 3.0 ? 'Silver' : 'Bronze';
  const nextLevel     = student.cgpa >= 3.7 ? 'Platinum' : student.cgpa >= 3.0 ? 'Gold' : 'Silver';
  const ptsToNext     = Math.round((student.cgpa >= 3.7 ? 4.0 : student.cgpa >= 3.0 ? 3.7 : 3.0) * 800) - points;
  const graduationPct = Math.round(((student.total_credits_earned) / 134) * 100);

  // Chart data — prefer term GPA history, fallback to completed courses
  const gpaChartData = term_gpa_history.length > 0
    ? term_gpa_history.map(t => ({
        name:    t.term,
        termGPA: t.term_gpa,
        cgpa:    t.cgpa,
        dean:    t.dean_list,
      }))
    : completed_courses
        .filter(c => c.grade !== null)
        .map((c, i) => ({ name: `C${i + 1}`, termGPA: (c.grade ?? 0) / 25, cgpa: student.cgpa }));



  return (
    <div className="space-y-6">

      {/* ── Header ─────────────────────────────────────────────────────── */}
      <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-2xl bg-red-100 dark:bg-red-900/20 flex items-center justify-center shrink-0 shadow-sm">
            <span className="text-2xl font-bold text-red-700 dark:text-red-400">
              {student.name.charAt(0)}
            </span>
          </div>
          <div>
            <h1 className="text-2xl font-bold text-neutral-900 dark:text-white">
              {student.name}
            </h1>
            <p className="text-sm text-neutral-500 dark:text-neutral-400 mt-0.5">
              {student.student_number} · {student.department} · {yearLabel(student.year)}
            </p>
            <div className="flex items-center gap-3 mt-1.5 flex-wrap">
              <span className={cn('text-xs font-semibold', standing.color)}>
                {standing.label}
              </span>
              {student.is_scholarship && (
                <span className="flex items-center gap-1 text-xs font-medium text-amber-600 dark:text-amber-400">
                  <Star className="w-3 h-3" /> Scholarship Recipient
                </span>
              )}
              {student.advisor && (
                <span className="text-xs text-neutral-400">
                  Advisor: {student.advisor}
                </span>
              )}
            </div>
          </div>
        </div>

        <div className="flex items-center gap-2 flex-wrap">
          {unread_notifications > 0 && (
            <div className="flex items-center gap-1.5 px-3 py-2 bg-red-50 dark:bg-red-900/20 rounded-lg border border-red-100 dark:border-red-900/30">
              <Bell className="w-4 h-4 text-red-500" />
              <span className="text-sm font-semibold text-red-700 dark:text-red-400">
                {unread_notifications} unread
              </span>
            </div>
          )}
          <div className="flex items-center gap-1.5 px-3 py-2 bg-amber-50 dark:bg-amber-900/20 rounded-lg border border-amber-100 dark:border-amber-900/30">
            <Award className="w-4 h-4 text-amber-500" />
            <span className="text-sm font-semibold text-amber-700 dark:text-amber-400">
              {level} · {points} pts
            </span>
          </div>
          <button onClick={fetchAll} className="text-xs text-neutral-400 hover:text-red-600 transition-colors px-2 py-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800">
            Refresh
          </button>
        </div>
      </div>

      {/* ── KPI Strip ──────────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <StatCard icon={GraduationCap} label="CGPA" value={student.cgpa.toFixed(3)}
          sub={`out of 4.000`} color="red" />
        <StatCard icon={BookOpen} label="Credits Earned" value={student.total_credits_earned}
          sub={`${student.credits_to_graduation} to graduate`} color="blue" />
        <StatCard icon={Target}  label="Attendance" value={`${attendance_rate.toFixed(0)}%`}
          sub={attendance_rate >= 75 ? 'On track' : 'Below threshold'} color="emerald" />
        <StatCard icon={ClipboardList} label="Quizzes Passed" value={`${quiz_stats.passed}/${quiz_stats.total}`}
          sub={`Avg ${quiz_stats.avg_score.toFixed(0)}%`} color="purple" />
      </div>

      {/* ── Tab switcher ───────────────────────────────────────────────── */}
      <div className="flex gap-1 bg-neutral-100 dark:bg-neutral-800 rounded-xl p-1 w-fit">
        {(['overview', 'courses', 'progress'] as const).map(t => (
          <button key={t} onClick={() => setTab(t)}
            className={cn(
              'px-4 py-1.5 rounded-lg text-sm font-medium capitalize transition-all',
              tab === t
                ? 'bg-white dark:bg-neutral-900 text-neutral-900 dark:text-white shadow-sm'
                : 'text-neutral-500 dark:text-neutral-400 hover:text-neutral-700 dark:hover:text-neutral-300'
            )}
          >{t}</button>
        ))}
      </div>

      {/* ═══════════════════════════════════════════════════════════════════
          OVERVIEW TAB
      ════════════════════════════════════════════════════════════════════ */}
      {tab === 'overview' && (
        <>
          {/* ── Risk Banner ──────────────────────────────────────────── */}
          <div className={cn('rounded-2xl border p-5', riskPalette.bg, riskPalette.border)}>
            <div className="flex flex-col md:flex-row md:items-center gap-5">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <Shield className="w-5 h-5 text-red-600" />
                  <h2 className="text-base font-semibold text-neutral-900 dark:text-white">Risk Assessment</h2>
                  <Badge variant={riskPalette.badge as any} className="ml-1">
                    {risk?.level ?? 'Normal'}
                  </Badge>
                </div>

                {risk?.explanation && (
                  <p className="text-sm text-neutral-600 dark:text-neutral-400 mt-1 leading-relaxed">
                    {risk.explanation}
                  </p>
                )}

                {/* Recommendation chips */}
                {(risk?.recommendations ?? []).length > 0 && (
                  <div className="flex flex-wrap gap-2 mt-3">
                    {(risk!.recommendations as string[]).slice(0, 3).map((r, i) => (
                      <span key={i} className="flex items-center gap-1 text-xs px-2.5 py-1 bg-white/70 dark:bg-neutral-900/60 rounded-full border border-neutral-200 dark:border-neutral-700 text-neutral-700 dark:text-neutral-300">
                        <Info className="w-3 h-3 text-red-500 shrink-0" /> {r}
                      </span>
                    ))}
                  </div>
                )}
              </div>

              {/* Risk metrics */}
              <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-2 lg:grid-cols-4 gap-3 shrink-0">
                {[
                  { label: 'Risk Score',     value: `${risk?.probability.toFixed(0) ?? 0}%`,  color: riskPalette.text },
                  { label: 'Dropout Risk',   value: `${risk?.dropout_probability.toFixed(0) ?? 0}%`, color: risk && risk.dropout_probability > 40 ? 'text-red-600' : 'text-emerald-600' },
                  { label: 'Scholarship',    value: `${risk?.scholarship_eligibility.toFixed(0) ?? 0}%`, color: 'text-emerald-600' },
                  { label: 'Grad Delay',     value: `${risk?.graduation_delay_likelihood.toFixed(0) ?? 0}%`, color: 'text-neutral-600 dark:text-neutral-300' },
                ].map(m => (
                  <div key={m.label} className="text-center bg-white/60 dark:bg-neutral-900/60 rounded-xl p-3 border border-white/50 dark:border-neutral-800">
                    <p className={cn('text-2xl font-bold', m.color)}>{m.value}</p>
                    <p className="text-xs text-neutral-500 mt-0.5">{m.label}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* ── GPA Chart + Metrics ──────────────────────────────────── */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <Card title="CGPA Trend" subtitle={`${gpaChartData.length} terms tracked`} className="lg:col-span-2">
              <div className="h-60">
                {gpaChartData.length === 0 ? (
                  <div className="flex items-center justify-center h-full text-sm text-neutral-400">
                    No term GPA data yet
                  </div>
                ) : (
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={gpaChartData} margin={{ top: 8, right: 8, bottom: 0, left: -16 }}>
                      <defs>
                        <linearGradient id="cgpaFill" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%"  stopColor="#DC2626" stopOpacity={0.12} />
                          <stop offset="95%" stopColor="#DC2626" stopOpacity={0} />
                        </linearGradient>
                        <linearGradient id="termFill" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%"  stopColor="#3B82F6" stopOpacity={0.12} />
                          <stop offset="95%" stopColor="#3B82F6" stopOpacity={0} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="#e5e5e5" />
                      <XAxis dataKey="name" stroke="#a3a3a3" fontSize={10} tick={{ dy: 4 }} />
                      <YAxis domain={[0, 4]} stroke="#a3a3a3" fontSize={11} tickFormatter={v => v.toFixed(1)} />
                      <Tooltip
                        contentStyle={{ backgroundColor: 'white', border: '1px solid #e5e5e5', borderRadius: '10px', fontSize: 12 }}
                        formatter={(v: number, name: string) => [v.toFixed(3), name === 'cgpa' ? 'CGPA' : 'Term GPA']}
                      />
                      <ReferenceLine y={3.0} stroke="#F59E0B" strokeDasharray="4 3" label={{ value: 'Dean\'s 3.0', position: 'right', fontSize: 9, fill: '#F59E0B' }} />
                      <Area type="monotone" dataKey="termGPA" stroke="#3B82F6" fill="url(#termFill)" strokeWidth={2} dot={{ r: 3, fill: '#3B82F6' }} name="termGPA" />
                      <Area type="monotone" dataKey="cgpa"    stroke="#DC2626" fill="url(#cgpaFill)" strokeWidth={2.5} dot={{ r: 3.5, fill: '#DC2626' }} name="cgpa" />
                    </AreaChart>
                  </ResponsiveContainer>
                )}
              </div>
              {term_gpa_history.length > 0 && (
                <div className="flex items-center gap-5 mt-3 pt-3 border-t border-neutral-100 dark:border-neutral-800">
                  <div className="flex items-center gap-1.5 text-xs text-neutral-500">
                    <span className="w-3 h-0.5 bg-red-500 rounded inline-block" /> CGPA
                  </div>
                  <div className="flex items-center gap-1.5 text-xs text-neutral-500">
                    <span className="w-3 h-0.5 bg-blue-500 rounded inline-block" /> Term GPA
                  </div>
                  <div className="flex items-center gap-1.5 text-xs text-neutral-500">
                    <span className="w-3 h-0.5 bg-yellow-400 rounded inline-block" style={{ borderStyle: 'dashed' }} /> Dean's threshold
                  </div>
                </div>
              )}
            </Card>

            <Card title="Academic Summary" subtitle="Current standing">
              <div className="space-y-4">
                <div>
                  <div className="flex justify-between text-sm mb-1.5">
                    <span className="text-neutral-600 dark:text-neutral-400">CGPA</span>
                    <span className="font-bold text-neutral-900 dark:text-white">{student.cgpa.toFixed(3)} / 4.000</span>
                  </div>
                  <ProgressBar value={student.cgpa} max={4} size="md" />
                </div>
                <div>
                  <div className="flex justify-between text-sm mb-1.5">
                    <span className="text-neutral-600 dark:text-neutral-400">Graduation Progress</span>
                    <span className="font-bold text-neutral-900 dark:text-white">{graduationPct}%</span>
                  </div>
                  <ProgressBar value={student.total_credits_earned} max={134} size="md" />
                  <p className="text-xs text-neutral-400 mt-1">
                    {student.total_credits_earned} / 134 credit hours
                  </p>
                </div>
                <div>
                  <div className="flex justify-between text-sm mb-1.5">
                    <span className="text-neutral-600 dark:text-neutral-400">Attendance</span>
                    <span className={cn('font-bold', attendance_rate >= 75 ? 'text-emerald-600' : 'text-red-600')}>
                      {attendance_rate.toFixed(0)}%
                    </span>
                  </div>
                  <ProgressBar value={attendance_rate} size="md" />
                </div>
                <div>
                  <div className="flex justify-between text-sm mb-1.5">
                    <span className="text-neutral-600 dark:text-neutral-400">Scholarship Eligibility</span>
                    <span className="font-bold text-emerald-600">{risk?.scholarship_eligibility.toFixed(0) ?? 0}%</span>
                  </div>
                  <ProgressBar value={risk?.scholarship_eligibility ?? 0} size="md" />
                </div>

                {/* Info grid */}
                <div className="pt-3 border-t border-neutral-100 dark:border-neutral-800 grid grid-cols-2 gap-y-2 gap-x-3 text-xs">
                  {[
                    ['Year',    yearLabel(student.year)],
                    ['Major',   student.major],
                    ['Credits', `${student.total_credits_earned} earned`],
                    ['Trend',   risk?.trend ?? 'stable'],
                  ].map(([k, v]) => (
                    <div key={k}>
                      <span className="text-neutral-400 block">{k}</span>
                      <span className="font-medium text-neutral-700 dark:text-neutral-300 capitalize">{v}</span>
                    </div>
                  ))}
                </div>
              </div>
            </Card>
          </div>

          {/* ── Active courses + Interventions ───────────────────────── */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

            {/* Active courses */}
            <Card title="Current Semester" subtitle={`${enrollments.length} active courses`}>
              <div className="space-y-2">
                {enrollments.length === 0 ? (
                  <p className="text-sm text-neutral-400 text-center py-8">No active courses</p>
                ) : enrollments.map(e => {
                  const grade = e.grade;
                  return (
                    <div key={e.course_id} className="flex items-center gap-3 p-3 rounded-xl hover:bg-neutral-50 dark:hover:bg-neutral-800 transition-colors">
                      <div className="w-9 h-9 rounded-lg bg-red-100 dark:bg-red-900/20 flex items-center justify-center shrink-0">
                        <BookOpen className="w-4 h-4 text-red-600" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-neutral-900 dark:text-white truncate">{e.name}</p>
                        <p className="text-xs text-neutral-400">{e.code} · {e.semester}</p>
                      </div>
                      <div className="text-right shrink-0">
                        {grade !== null ? (
                          <>
                            <p className={cn('text-sm font-bold', gradeColor(grade))}>{grade.toFixed(0)}%</p>
                            <p className="text-xs text-neutral-400">{letterGrade(grade)}</p>
                          </>
                        ) : (
                          <span className="text-xs text-neutral-400">In progress</span>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </Card>

            {/* Intervention plans */}
            <Card title="Intervention Plans" subtitle="Academic support actions">
              {intervention_plans.length === 0 ? (
                <div className="text-center py-8">
                  <CheckCircle className="w-10 h-10 text-emerald-400 mx-auto" />
                  <p className="text-sm font-medium text-emerald-600 mt-2">All clear!</p>
                  <p className="text-xs text-neutral-400 mt-1">No active interventions</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {intervention_plans.map(p => (
                    <div key={p.id} className="p-4 rounded-xl border border-neutral-200 dark:border-neutral-700 hover:border-red-300 dark:hover:border-red-800 transition-colors">
                      <div className="flex items-start justify-between gap-2">
                        <div className="flex-1 min-w-0">
                          <h4 className="text-sm font-semibold text-neutral-900 dark:text-white truncate">{p.title}</h4>
                          <p className="text-xs text-neutral-500 mt-0.5 line-clamp-2">{p.description}</p>
                        </div>
                        <Badge variant={p.priority === 'high' ? 'critical' : p.priority === 'medium' ? 'warning' : 'normal'}>
                          {p.priority}
                        </Badge>
                      </div>
                      {p.deadline && (
                        <div className="flex items-center gap-1 mt-2.5 text-xs text-neutral-400">
                          <Calendar className="w-3 h-3" />
                          <span>Due {new Date(p.deadline).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })}</span>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </Card>
          </div>
        </>
      )}

      {/* ═══════════════════════════════════════════════════════════════════
          COURSES TAB
      ════════════════════════════════════════════════════════════════════ */}
      {tab === 'courses' && (
        <div className="space-y-6">
          {/* Active */}
          <Card title="Active Courses" subtitle={`${enrollments.length} enrolled this semester`}>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-neutral-100 dark:border-neutral-800">
                    {['Course', 'Code', 'Semester', 'Grade', 'Letter', 'Status'].map(h => (
                      <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-neutral-500 uppercase tracking-wider">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-neutral-50 dark:divide-neutral-800/60">
                  {enrollments.map(e => (
                    <tr key={e.course_id} className="hover:bg-neutral-50 dark:hover:bg-neutral-800/40 transition-colors">
                      <td className="px-4 py-3 text-sm font-medium text-neutral-900 dark:text-white">{e.name}</td>
                      <td className="px-4 py-3 text-sm text-neutral-500 font-mono">{e.code}</td>
                      <td className="px-4 py-3 text-xs text-neutral-400">{e.semester}</td>
                      <td className="px-4 py-3">
                        {e.grade !== null
                          ? <span className={cn('text-sm font-bold', gradeColor(e.grade))}>{e.grade.toFixed(0)}%</span>
                          : <span className="text-xs text-neutral-400">—</span>}
                      </td>
                      <td className="px-4 py-3">
                        {e.grade !== null
                          ? <span className={cn('text-sm font-bold', gradeColor(e.grade))}>{letterGrade(e.grade)}</span>
                          : <span className="text-xs text-neutral-400">—</span>}
                      </td>
                      <td className="px-4 py-3">
                        <Badge variant="info">Active</Badge>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>

          {/* Completed */}
          {completed_courses.length > 0 && (
            <Card title="Completed Courses" subtitle={`${completed_courses.length} finished`}>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-neutral-100 dark:border-neutral-800">
                      {['Course', 'Code', 'Semester', 'Final Grade', 'Letter'].map(h => (
                        <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-neutral-500 uppercase tracking-wider">{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-neutral-50 dark:divide-neutral-800/60">
                    {completed_courses.map(c => (
                      <tr key={c.course_id} className="hover:bg-neutral-50 dark:hover:bg-neutral-800/40 transition-colors">
                        <td className="px-4 py-3 text-sm text-neutral-900 dark:text-white">{c.name}</td>
                        <td className="px-4 py-3 text-sm text-neutral-500 font-mono">{c.code}</td>
                        <td className="px-4 py-3 text-xs text-neutral-400">{c.semester}</td>
                        <td className="px-4 py-3">
                          <span className={cn('text-sm font-bold', gradeColor(c.grade ?? 0))}>{(c.grade ?? 0).toFixed(0)}%</span>
                        </td>
                        <td className="px-4 py-3">
                          <span className={cn('text-sm font-bold', gradeColor(c.grade ?? 0))}>{letterGrade(c.grade ?? 0)}</span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </Card>
          )}
        </div>
      )}

      {/* ═══════════════════════════════════════════════════════════════════
          PROGRESS TAB
      ════════════════════════════════════════════════════════════════════ */}
      {tab === 'progress' && (
        <div className="space-y-6">

          {/* Graduation roadmap */}
          <Card title="Graduation Progress" subtitle={`${student.credits_to_graduation} credit hours remaining`}>
            <div className="flex flex-col sm:flex-row sm:items-center gap-6">
              <div className="flex-1">
                <div className="flex justify-between text-sm mb-2">
                  <span className="text-neutral-600 dark:text-neutral-400">Completion</span>
                  <span className="font-bold text-neutral-900 dark:text-white">{graduationPct}%</span>
                </div>
                <ProgressBar value={student.total_credits_earned} max={134} size="lg" />
                <div className="flex justify-between text-xs text-neutral-400 mt-1.5">
                  <span>0 credits</span>
                  <span>{student.total_credits_earned} earned</span>
                  <span>134 required</span>
                </div>
              </div>
              <div className="grid grid-cols-3 gap-3 shrink-0">
                {[
                  { label: 'Earned',    value: student.total_credits_earned,    color: 'text-emerald-600' },
                  { label: 'Attempted', value: student.total_credits_attempted, color: 'text-blue-600'    },
                  { label: 'Remaining', value: student.credits_to_graduation,   color: 'text-red-600'     },
                ].map(s => (
                  <div key={s.label} className="text-center p-3 bg-neutral-50 dark:bg-neutral-800 rounded-xl">
                    <p className={cn('text-2xl font-bold', s.color)}>{s.value}</p>
                    <p className="text-xs text-neutral-500 mt-0.5">{s.label}</p>
                  </div>
                ))}
              </div>
            </div>
          </Card>

          {/* Term-by-term history table */}
          {term_gpa_history.length > 0 && (
            <Card title="Term History" subtitle="Full academic record by semester">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-neutral-100 dark:border-neutral-800">
                      {['Term', 'Term GPA', 'CGPA', 'Credits', 'Standing', 'Honors'].map(h => (
                        <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-neutral-500 uppercase tracking-wider">{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-neutral-50 dark:divide-neutral-800/60">
                    {term_gpa_history.map(t => (
                      <tr key={t.term} className="hover:bg-neutral-50 dark:hover:bg-neutral-800/40 transition-colors">
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-2">
                            <span className="text-sm font-medium text-neutral-900 dark:text-white">{t.term_name ?? t.term}</span>
                            {t.dean_list && <Star className="w-3.5 h-3.5 text-amber-500" aria-label="Dean's List" />}
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-1.5">
                            <span className={cn('text-sm font-bold', t.term_gpa >= 3.7 ? 'text-emerald-600' : t.term_gpa >= 3.0 ? 'text-blue-600' : t.term_gpa >= 2.0 ? 'text-yellow-600' : 'text-red-600')}>
                              {t.term_gpa.toFixed(3)}
                            </span>
                            {t.term_gpa > (term_gpa_history[term_gpa_history.indexOf(t) - 1]?.term_gpa ?? t.term_gpa)
                              ? <TrendingUp className="w-3.5 h-3.5 text-emerald-500" />
                              : t.term_gpa < (term_gpa_history[term_gpa_history.indexOf(t) - 1]?.term_gpa ?? t.term_gpa)
                              ? <TrendingDown className="w-3.5 h-3.5 text-red-500" />
                              : null}
                          </div>
                        </td>
                        <td className="px-4 py-3 text-sm font-medium text-neutral-700 dark:text-neutral-300">{t.cgpa.toFixed(3)}</td>
                        <td className="px-4 py-3 text-xs text-neutral-500">
                          {t.credits_earned}/{t.credits_attempted}
                          {t.credits_failed > 0 && <span className="text-red-500 ml-1">({t.credits_failed}F)</span>}
                        </td>
                        <td className="px-4 py-3">
                          <span className={cn('text-xs font-medium capitalize',
                            t.standing === 'active' ? 'text-emerald-600' :
                            t.standing === 'probation' ? 'text-red-600' :
                            t.standing === 'warning' ? 'text-yellow-600' : 'text-neutral-500'
                          )}>
                            {t.standing}
                          </span>
                        </td>
                        <td className="px-4 py-3">
                          {t.honors && t.honors !== 'none' ? (
                            <span className="text-xs font-medium text-amber-600 capitalize">{t.honors.replace('_', ' ')}</span>
                          ) : (
                            <span className="text-xs text-neutral-300">—</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </Card>
          )}

          {/* Bar chart: term GPA comparison */}
          {term_gpa_history.length > 0 && (
            <Card title="Term GPA Comparison" subtitle="Each semester at a glance">
              <div className="h-52">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={gpaChartData} margin={{ top: 4, right: 4, bottom: 0, left: -16 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e5e5" />
                    <XAxis dataKey="name" stroke="#a3a3a3" fontSize={10} />
                    <YAxis domain={[0, 4]} stroke="#a3a3a3" fontSize={11} tickFormatter={v => v.toFixed(1)} />
                    <Tooltip
                      contentStyle={{ backgroundColor: 'white', border: '1px solid #e5e5e5', borderRadius: '10px', fontSize: 12 }}
                      formatter={(v: number, n: string) => [v.toFixed(3), n === 'cgpa' ? 'CGPA' : 'Term GPA']}
                    />
                    <ReferenceLine y={3.0} stroke="#F59E0B" strokeDasharray="4 3" />
                    <Bar dataKey="termGPA" fill="#DC2626" radius={[4, 4, 0, 0]} name="termGPA" />
                    <Bar dataKey="cgpa"    fill="#3B82F6" radius={[4, 4, 0, 0]} name="cgpa" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </Card>
          )}

          {/* Gamification */}
          <Card title="Achievements" subtitle="Your level and points">
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div className="p-5 rounded-2xl bg-red-50 dark:bg-red-900/10 border border-red-100 dark:border-red-900/20 text-center">
                <Award className="w-10 h-10 text-red-600 mx-auto" />
                <p className="text-2xl font-bold text-neutral-900 dark:text-white mt-2">{level}</p>
                <p className="text-xs text-neutral-500">Current Level</p>
                <div className="mt-3">
                  <ProgressBar value={points} max={points + Math.max(ptsToNext, 0)} size="sm" />
                  <p className="text-xs text-neutral-400 mt-1">{Math.max(ptsToNext, 0)} pts to {nextLevel}</p>
                </div>
              </div>
              <div className="p-5 rounded-2xl bg-amber-50 dark:bg-amber-900/10 border border-amber-100 dark:border-amber-900/20 text-center">
                <Flame className="w-10 h-10 text-amber-600 mx-auto" />
                <p className="text-2xl font-bold text-neutral-900 dark:text-white mt-2">{points}</p>
                <p className="text-xs text-neutral-500">Total Points</p>
                <p className="text-xs text-amber-600 mt-2 font-medium">CGPA × 800</p>
              </div>
              <div className="p-5 rounded-2xl bg-emerald-50 dark:bg-emerald-900/10 border border-emerald-100 dark:border-emerald-900/20 text-center">
                <Users className="w-10 h-10 text-emerald-600 mx-auto" />
                <p className="text-2xl font-bold text-neutral-900 dark:text-white mt-2">{quiz_stats.passed}</p>
                <p className="text-xs text-neutral-500">Quizzes Passed</p>
                <p className="text-xs text-emerald-600 mt-2 font-medium">
                  {quiz_stats.total > 0 ? `${Math.round((quiz_stats.passed / quiz_stats.total) * 100)}% pass rate` : 'No quizzes yet'}
                </p>
              </div>
            </div>
          </Card>
        </div>
      )}
    </div>
  );
}