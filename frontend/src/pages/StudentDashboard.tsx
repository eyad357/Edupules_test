import { useState, useEffect, useCallback } from 'react';
import {
  Target, Award, Flame,
  BookOpen, Shield, Calendar
} from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Badge } from '../components/ui/Badge';
import { ProgressBar } from '../components/ui/ProgressBar';
import { cn } from '../lib/utils';
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer
} from 'recharts';

const BASE = (import.meta as any).env?.VITE_FASTAPI_URL ?? 'http://localhost:8000/api/v1';
const TOKEN_KEY = 'eduguard_token';
const authHeader = () => ({ Authorization: `Bearer ${localStorage.getItem(TOKEN_KEY)}` });

interface StudentData {
  id: number; name: string; student_number: string; major: string;
  year: number; gpa: number; email: string;
}

interface RiskData {
  level: string; probability: number; trend: string;
  grades_impact?: number; attendance_impact?: number;
  dropout_probability?: number; graduation_delay_likelihood?: number;
  scholarship_eligibility?: number;
}

interface Enrollment {
  course_id: number; code: string; name: string;
  grade: number | null; semester: string;
}

interface InterventionPlan {
  id: number; title: string; description: string;
  status: string; priority: string; deadline: string | null;
}

const riskColor: Record<string, string> = {
  Normal: 'text-emerald-600', Low: 'text-yellow-600',
  High: 'text-orange-600', Critical: 'text-red-600',
};

const riskBg: Record<string, string> = {
  Normal: 'bg-emerald-50 dark:bg-emerald-900/20',
  Low: 'bg-yellow-50 dark:bg-yellow-900/20',
  High: 'bg-orange-50 dark:bg-orange-900/20',
  Critical: 'bg-red-50 dark:bg-red-900/20',
};

export function StudentDashboard() {
  const [student, setStudent] = useState<StudentData | null>(null);
  const [risk, setRisk] = useState<RiskData | null>(null);
  const [enrollments, setEnrollments] = useState<Enrollment[]>([]);
  const [plans, setPlans] = useState<InterventionPlan[]>([]);
  const [attendanceRate, setAttendanceRate] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAll = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`${BASE}/analytics/student-dashboard`, { headers: authHeader() });
      if (!res.ok) throw new Error(`Student dashboard ${res.status}`);
      const data = await res.json();

      setStudent(data.student);
      setRisk(data.risk ?? null);
      setEnrollments(data.enrollments ?? []);
      setAttendanceRate(data.attendance_rate ?? 0);

      // fetch intervention plans
      const planRes = await fetch(`${BASE}/analytics/interventions?page_size=20`, { headers: authHeader() });
      if (planRes.ok) {
        const planData = await planRes.json();
        const myPlans = (planData.plans ?? []).filter(
          (p: any) => p.student_id === data.student?.id
        );
        setPlans(myPlans);
      }
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchAll(); }, [fetchAll]);

  // Build a simple GPA trend from enrollment grades for the chart
  const gpaChartData = enrollments
    .filter(e => e.grade !== null)
    .map((e, i) => ({
      date: `Course ${i + 1}`,
      gpa: ((e.grade ?? 0) / 25), // scale 0-100 → 0-4
    }));

  const gamification = {
    points: Math.round((student?.gpa ?? 2) * 800),
    streak: 12,
    level: (student?.gpa ?? 0) >= 3.5 ? 'Gold' : (student?.gpa ?? 0) >= 3.0 ? 'Silver' : 'Bronze',
    nextLevel: (student?.gpa ?? 0) >= 3.5 ? 'Platinum' : (student?.gpa ?? 0) >= 3.0 ? 'Gold' : 'Silver',
    pointsToNext: 550,
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center space-y-3">
          <div className="w-8 h-8 border-2 border-red-600 border-t-transparent rounded-full animate-spin mx-auto" />
          <p className="text-sm text-neutral-500">Loading your dashboard…</p>
        </div>
      </div>
    );
  }

  if (error || !student) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center space-y-3">
          <p className="text-red-600 font-medium">Failed to load dashboard</p>
          <p className="text-sm text-neutral-500">{error ?? 'Student profile not found'}</p>
          <button onClick={fetchAll} className="btn-primary text-sm px-4 py-2">Retry</button>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Welcome Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-full bg-red-100 dark:bg-red-900/20 flex items-center justify-center">
            <span className="text-xl font-bold text-red-700 dark:text-red-400">{student.name.charAt(0)}</span>
          </div>
          <div>
            <h1 className="text-2xl font-bold text-neutral-900 dark:text-white">
              Welcome back, {student.name.split(' ')[0]}
            </h1>
            <p className="text-neutral-500 dark:text-neutral-400 text-sm">{student.major} · Year {student.year}</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 px-3 py-2 bg-amber-50 dark:bg-amber-900/20 rounded-lg border border-amber-100 dark:border-amber-900/30">
            <Flame className="w-4 h-4 text-amber-500" />
            <span className="text-sm font-semibold text-amber-700 dark:text-amber-400">{gamification.streak} day streak</span>
          </div>
          <div className="flex items-center gap-2 px-3 py-2 bg-red-50 dark:bg-red-900/20 rounded-lg border border-red-100 dark:border-red-900/30">
            <Award className="w-4 h-4 text-red-500" />
            <span className="text-sm font-semibold text-red-700 dark:text-red-400">{gamification.points} pts</span>
          </div>
          <button onClick={fetchAll} className="text-sm text-neutral-400 hover:text-red-600 underline">Refresh</button>
        </div>
      </div>

      {/* Risk Score Card */}
      <div className={cn('rounded-xl border p-6', riskBg[risk?.level ?? 'Normal'], 'border-red-100 dark:border-red-900/20')}>
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-2">
              <Shield className="w-5 h-5 text-red-600" />
              <h2 className="text-lg font-semibold text-neutral-900 dark:text-white">Your Risk Assessment</h2>
            </div>
            <p className="text-sm text-neutral-600 dark:text-neutral-400">Based on your grades, attendance, and platform activity</p>
            <div className="flex flex-wrap gap-4 mt-4">
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 rounded-full bg-red-500" />
                <span className="text-xs text-neutral-600 dark:text-neutral-400">Grades: {risk?.grades_impact ?? 0}%</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 rounded-full bg-orange-500" />
                <span className="text-xs text-neutral-600 dark:text-neutral-400">Attendance: {attendanceRate.toFixed(0)}%</span>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-6">
            <div className="text-center">
              <div className={cn('text-4xl font-bold', riskColor[risk?.level ?? 'Normal'])}>
                {risk?.probability.toFixed(0) ?? 0}%
              </div>
              <p className="text-xs text-neutral-500 mt-1">Risk Probability</p>
            </div>
            <div className="w-px h-16 bg-red-200 dark:bg-red-900/30" />
            <div className="text-center">
              <Badge variant={(risk?.level ?? 'Normal').toLowerCase() as any} className="text-sm px-3 py-1">
                {risk?.level ?? 'Normal'}
              </Badge>
              <p className="text-xs text-neutral-500 mt-1">Risk Level</p>
            </div>
          </div>
        </div>
      </div>

      {/* GPA Chart & Key Metrics */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <Card title="GPA Trend" subtitle="Your course performance" className="lg:col-span-2">
          <div className="h-64">
            {gpaChartData.length === 0 ? (
              <div className="flex items-center justify-center h-full text-sm text-neutral-500">
                No grade data available yet
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={gpaChartData}>
                  <defs>
                    <linearGradient id="studentGpa" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#DC2626" stopOpacity={0.1} />
                      <stop offset="95%" stopColor="#DC2626" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e5e5" />
                  <XAxis dataKey="date" stroke="#737373" fontSize={11} />
                  <YAxis domain={[0, 4]} stroke="#737373" fontSize={12} />
                  <Tooltip
                    contentStyle={{ backgroundColor: 'white', border: '1px solid #e5e5e5', borderRadius: '8px' }}
                    formatter={(v: number) => [v.toFixed(2), 'GPA']}
                  />
                  <Area type="monotone" dataKey="gpa" stroke="#DC2626" fill="url(#studentGpa)" strokeWidth={2} />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </div>
        </Card>

        <Card title="Key Metrics" subtitle="Current semester">
          <div className="space-y-5">
            <div>
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-neutral-600 dark:text-neutral-400">Current GPA</span>
                <span className="text-sm font-bold text-neutral-900 dark:text-white">{student.gpa.toFixed(2)}</span>
              </div>
              <ProgressBar value={student.gpa} max={4} size="md" />
            </div>
            <div>
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-neutral-600 dark:text-neutral-400">Attendance</span>
                <span className="text-sm font-bold text-neutral-900 dark:text-white">{attendanceRate.toFixed(0)}%</span>
              </div>
              <ProgressBar value={attendanceRate} size="md" />
            </div>
            <div>
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-neutral-600 dark:text-neutral-400">Dropout Risk</span>
                <span className="text-sm font-bold text-red-600">{risk?.dropout_probability?.toFixed(0) ?? risk?.probability.toFixed(0) ?? 0}%</span>
              </div>
              <ProgressBar value={risk?.dropout_probability ?? risk?.probability ?? 0} size="md" />
            </div>
            <div>
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-neutral-600 dark:text-neutral-400">Scholarship Eligibility</span>
                <span className="text-sm font-bold text-emerald-600">{risk?.scholarship_eligibility?.toFixed(0) ?? 0}%</span>
              </div>
              <ProgressBar value={risk?.scholarship_eligibility ?? 0} size="md" />
            </div>
          </div>
        </Card>
      </div>

      {/* Enrolled Courses & Interventions */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card title="My Courses" subtitle="Active enrollments this semester">
          <div className="space-y-3">
            {enrollments.length === 0 ? (
              <p className="text-sm text-neutral-500 text-center py-8">No active enrollments found</p>
            ) : enrollments.map(e => (
              <div key={e.course_id} className="flex items-center gap-3 p-3 rounded-lg hover:bg-neutral-50 dark:hover:bg-neutral-800 transition-colors">
                <div className="w-9 h-9 rounded-lg bg-red-100 dark:bg-red-900/20 flex items-center justify-center flex-shrink-0">
                  <BookOpen className="w-4 h-4 text-red-600 dark:text-red-400" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-neutral-900 dark:text-white truncate">{e.name}</p>
                  <p className="text-xs text-neutral-500">{e.code} · {e.semester}</p>
                </div>
                <div className="text-right flex-shrink-0">
                  {e.grade !== null ? (
                    <>
                      <p className="text-sm font-bold text-neutral-900 dark:text-white">{e.grade.toFixed(0)}%</p>
                      <p className="text-xs text-neutral-500">Grade</p>
                    </>
                  ) : (
                    <span className="text-xs text-neutral-400">In progress</span>
                  )}
                </div>
              </div>
            ))}
          </div>
        </Card>

        <Card title="My Intervention Plans" subtitle="Personalized action items">
          {plans.length === 0 ? (
            <div className="text-center py-8">
              <Shield className="w-10 h-10 text-neutral-300 mx-auto" />
              <p className="text-sm text-neutral-500 mt-2">No active interventions</p>
              <p className="text-xs text-neutral-400">You're doing great!</p>
            </div>
          ) : (
            <div className="space-y-3">
              {plans.map(plan => (
                <div key={plan.id} className="p-4 rounded-lg border border-neutral-200 dark:border-neutral-700 hover:border-red-300 dark:hover:border-red-800 transition-colors">
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex-1 min-w-0">
                      <h4 className="text-sm font-semibold text-neutral-900 dark:text-white truncate">{plan.title}</h4>
                      <p className="text-xs text-neutral-500 mt-0.5 line-clamp-2">{plan.description}</p>
                    </div>
                    <Badge variant={plan.priority === 'high' ? 'critical' : plan.priority === 'medium' ? 'warning' : 'normal'}>
                      {plan.priority}
                    </Badge>
                  </div>
                  {plan.deadline && (
                    <div className="flex items-center gap-1 mt-3 text-xs text-neutral-500">
                      <Calendar className="w-3 h-3" />
                      <span>Due {new Date(plan.deadline).toLocaleDateString()}</span>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </Card>
      </div>

      {/* Gamification */}
      <Card title="Achievements" subtitle="Your progress and level">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="p-4 rounded-xl bg-red-50 dark:bg-red-900/10 border border-red-100 dark:border-red-900/20 text-center">
            <Award className="w-8 h-8 text-red-600 mx-auto" />
            <p className="text-2xl font-bold text-neutral-900 dark:text-white mt-2">{gamification.level}</p>
            <p className="text-xs text-neutral-500">Current Level</p>
            <div className="mt-3">
              <ProgressBar value={gamification.points} max={gamification.points + gamification.pointsToNext} size="sm" />
              <p className="text-xs text-neutral-500 mt-1">{gamification.pointsToNext} pts to {gamification.nextLevel}</p>
            </div>
          </div>
          <div className="p-4 rounded-xl bg-amber-50 dark:bg-amber-900/10 border border-amber-100 dark:border-amber-900/20 text-center">
            <Flame className="w-8 h-8 text-amber-600 mx-auto" />
            <p className="text-2xl font-bold text-neutral-900 dark:text-white mt-2">{gamification.streak}</p>
            <p className="text-xs text-neutral-500">Day Streak</p>
            <p className="text-xs text-amber-600 mt-2 font-medium">Keep it up!</p>
          </div>
          <div className="p-4 rounded-xl bg-emerald-50 dark:bg-emerald-900/10 border border-emerald-100 dark:border-emerald-900/20 text-center">
            <Target className="w-8 h-8 text-emerald-600 mx-auto" />
            <p className="text-2xl font-bold text-neutral-900 dark:text-white mt-2">{gamification.points}</p>
            <p className="text-xs text-neutral-500">Total Points</p>
            <p className="text-xs text-emerald-600 mt-2 font-medium">
              GPA-based ranking
            </p>
          </div>
        </div>
      </Card>
    </div>
  );
}