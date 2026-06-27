import { useState, useEffect, useCallback } from 'react';
import {
  Users, BookOpen, AlertTriangle, BarChart3
} from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Badge } from '../components/ui/Badge';
import { ProgressBar } from '../components/ui/ProgressBar';
import { StatCard } from '../components/ui/StatCard';
import { cn } from '../lib/utils';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar
} from 'recharts';

const BASE = (import.meta as any).env?.VITE_FASTAPI_URL ?? 'http://localhost:8000/api/v1';
const TOKEN_KEY = 'eduguard_token';
const authHeader = () => ({ Authorization: `Bearer ${localStorage.getItem(TOKEN_KEY)}` });

interface DashboardData {
  professor: { id: number; name: string; department: string; title: string };
  courses: { id: number; code: string; name: string; semester: string; year: number; credits: number; enrolled: number }[];
  total_students: number;
  at_risk: number;
  avg_gpa: number;
  attendance_rate: number;
}

interface StudentRow {
  id: number; name: string; student_number: string; major: string;
  gpa: number; risk_level: string; probability: number;
  grades_impact: number; attendance_impact: number; activity_impact: number;
  dropout_probability: number;
}

const RISK_COLOR: Record<string, string> = {
  Normal: 'bg-emerald-500',
  Low: 'bg-yellow-500',
  High: 'bg-orange-500',
  Critical: 'bg-red-500',
};

export function ProfessorDashboard() {
  const [dashboard, setDashboard] = useState<DashboardData | null>(null);
  const [students, setStudents] = useState<StudentRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedStudent, setSelectedStudent] = useState<number | null>(null);

  const fetchAll = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [dashRes, stuRes] = await Promise.all([
        fetch(`${BASE}/analytics/professor-dashboard`, { headers: authHeader() }),
        fetch(`${BASE}/analytics/students?limit=50`, { headers: authHeader() }),
      ]);
      if (!dashRes.ok) throw new Error(`Dashboard ${dashRes.status}`);
      const dashData: DashboardData = await dashRes.json();
      setDashboard(dashData);

      if (stuRes.ok) {
        const stuData = await stuRes.json();
        const list: StudentRow[] = (stuData.students ?? stuData ?? []).slice(0, 8).map((s: any) => ({
          id: s.id,
          name: s.name,
          student_number: s.student_number,
          major: s.major,
          gpa: s.gpa,
          risk_level: s.risk_level ?? 'Normal',
          probability: s.risk_probability ?? s.probability ?? 0,
          grades_impact: s.grades_impact ?? 0,
          attendance_impact: s.attendance_impact ?? 0,
          activity_impact: s.activity_impact ?? 0,
          dropout_probability: s.dropout_probability ?? 0,
        }));
        setStudents(list);
      }
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchAll(); }, [fetchAll]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center space-y-3">
          <div className="w-8 h-8 border-2 border-red-600 border-t-transparent rounded-full animate-spin mx-auto" />
          <p className="text-sm text-neutral-500">Loading professor dashboard…</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center space-y-3">
          <p className="text-red-600 font-medium">Failed to load dashboard</p>
          <p className="text-sm text-neutral-500">{error}</p>
          <button onClick={fetchAll} className="btn-primary text-sm px-4 py-2">Retry</button>
        </div>
      </div>
    );
  }

  const coursePerformance = (dashboard?.courses ?? []).map(c => ({
    course: c.code,
    enrolled: c.enrolled,
    credits: c.credits,
  }));

  const radarData = [
    { subject: 'Attendance', A: dashboard?.attendance_rate ?? 0, fullMark: 100 },
    { subject: 'GPA', A: ((dashboard?.avg_gpa ?? 0) / 4) * 100, fullMark: 100 },
    { subject: 'At Risk%', A: dashboard && dashboard.total_students > 0
        ? 100 - (dashboard.at_risk / dashboard.total_students) * 100 : 100, fullMark: 100 },
    { subject: 'Courses', A: Math.min((dashboard?.courses.length ?? 0) * 20, 100), fullMark: 100 },
    { subject: 'Enrolled', A: Math.min((dashboard?.total_students ?? 0) * 3, 100), fullMark: 100 },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900 dark:text-white">Professor Dashboard</h1>
          <p className="text-neutral-500 dark:text-neutral-400 mt-0.5">Monitor your courses and student performance</p>
        </div>
        <button onClick={fetchAll} className="text-sm text-neutral-500 hover:text-red-600 underline">
          Refresh
        </button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard title="My Students" value={dashboard?.total_students ?? 0} icon={Users} color="red" />
        <StatCard title="At Risk" value={dashboard?.at_risk ?? 0} subtitle="Need attention" icon={AlertTriangle} color="orange" />
        <StatCard title="Avg GPA" value={dashboard?.avg_gpa?.toFixed(2) ?? '—'} subtitle="Across all courses" icon={BarChart3} color="blue" />
        <StatCard title="Courses" value={dashboard?.courses.length ?? 0} subtitle="Active this semester" icon={BookOpen} color="purple" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Risk Heatmap */}
        <Card title="Risk Heatmap" subtitle="Students by risk level">
          <div className="space-y-3">
            {students.length === 0 ? (
              <p className="text-sm text-neutral-500 text-center py-8">No student data available</p>
            ) : students.map(student => (
              <div
                key={student.id}
                className="flex items-center gap-3 p-3 rounded-lg hover:bg-neutral-50 dark:hover:bg-neutral-800 cursor-pointer transition-colors"
                onClick={() => setSelectedStudent(selectedStudent === student.id ? null : student.id)}
              >
                <div className={cn('w-3 h-12 rounded-full flex-shrink-0', RISK_COLOR[student.risk_level] ?? 'bg-neutral-300')} />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-2">
                    <p className="text-sm font-medium text-neutral-900 dark:text-white truncate">{student.name}</p>
                    <Badge variant={student.risk_level.toLowerCase() as any}>{student.risk_level}</Badge>
                  </div>
                  <div className="flex items-center gap-3 mt-1.5">
                    <ProgressBar value={student.probability} size="sm" className="flex-1" />
                    <span className="text-xs text-neutral-500 w-10 text-right">{student.probability.toFixed(0)}%</span>
                  </div>
                  {selectedStudent === student.id && (
                    <div className="mt-3 p-3 bg-neutral-50 dark:bg-neutral-800 rounded-lg space-y-2">
                      <div className="flex justify-between text-xs">
                        <span className="text-neutral-500">Grades Impact</span>
                        <span className="font-medium">{student.grades_impact}%</span>
                      </div>
                      <div className="flex justify-between text-xs">
                        <span className="text-neutral-500">Attendance Impact</span>
                        <span className="font-medium">{student.attendance_impact}%</span>
                      </div>
                      <div className="flex justify-between text-xs">
                        <span className="text-neutral-500">Dropout Probability</span>
                        <span className="font-medium text-red-600">{student.dropout_probability}%</span>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </Card>

        {/* Course Enrollment Chart */}
        <Card title="Course Enrollment" subtitle="Enrolled students per course">
          <div className="h-72">
            {coursePerformance.length === 0 ? (
              <div className="flex items-center justify-center h-full text-sm text-neutral-500">No course data</div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={coursePerformance}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e5e5" />
                  <XAxis dataKey="course" stroke="#737373" fontSize={11} />
                  <YAxis stroke="#737373" fontSize={12} />
                  <Tooltip contentStyle={{ backgroundColor: 'white', border: '1px solid #e5e5e5', borderRadius: '8px' }} />
                  <Bar dataKey="enrolled" fill="#DC2626" radius={[4, 4, 0, 0]} name="Enrolled" />
                </BarChart>
              </ResponsiveContainer>
            )}
          </div>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <Card title="Department Profile" subtitle="Performance overview" className="lg:col-span-1">
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <RadarChart data={radarData}>
                <PolarGrid stroke="#e5e5e5" />
                <PolarAngleAxis dataKey="subject" tick={{ fontSize: 11, fill: '#737373' }} />
                <PolarRadiusAxis angle={30} domain={[0, 100]} tick={{ fontSize: 10, fill: '#a3a3a3' }} />
                <Radar name="Performance" dataKey="A" stroke="#DC2626" fill="#DC2626" fillOpacity={0.15} strokeWidth={2} />
                <Tooltip />
              </RadarChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card title="Student Rankings" subtitle="By GPA — live from database" className="lg:col-span-2">
          <div className="space-y-2">
            {[...students].sort((a, b) => b.gpa - a.gpa).map((student, index) => (
              <div key={student.id} className="flex items-center gap-4 p-3 rounded-lg hover:bg-neutral-50 dark:hover:bg-neutral-800 transition-colors">
                <div className={cn(
                  'w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold flex-shrink-0',
                  index === 0 ? 'bg-yellow-100 text-yellow-700' :
                  index === 1 ? 'bg-neutral-200 text-neutral-700' :
                  index === 2 ? 'bg-orange-100 text-orange-700' :
                  'bg-neutral-100 text-neutral-500'
                )}>
                  {index + 1}
                </div>
                <div className="w-9 h-9 rounded-full bg-red-100 dark:bg-red-900/20 flex items-center justify-center flex-shrink-0">
                  <span className="text-sm font-semibold text-red-700 dark:text-red-400">{student.name.charAt(0)}</span>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-neutral-900 dark:text-white truncate">{student.name}</p>
                  <p className="text-xs text-neutral-500 truncate">{student.major}</p>
                </div>
                <div className="text-right flex-shrink-0">
                  <p className="text-sm font-semibold text-neutral-900 dark:text-white">{student.gpa.toFixed(2)}</p>
                  <p className="text-xs text-neutral-500">GPA</p>
                </div>
                <div className="text-right w-20 flex-shrink-0">
                  <ProgressBar value={student.probability} size="sm" />
                  <p className="text-xs text-neutral-400 mt-0.5">{student.probability.toFixed(0)}% risk</p>
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}
