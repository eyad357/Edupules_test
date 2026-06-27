import { useState, useEffect, useCallback } from 'react';
import {
  Users, Shield, TrendingUp, Plus, Search
} from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Badge } from '../components/ui/Badge';
import { ProgressBar } from '../components/ui/ProgressBar';
import { StatCard } from '../components/ui/StatCard';
import { cn } from '../lib/utils';
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  BarChart, Bar
} from 'recharts';

const BASE = (import.meta as any).env?.VITE_FASTAPI_URL ?? 'http://localhost:8000/api/v1';
const TOKEN_KEY = 'eduguard_token';
const authHeader = () => ({ Authorization: `Bearer ${localStorage.getItem(TOKEN_KEY)}` });

interface StudentRow {
  id: number; name: string; student_number: string; major: string;
  year: number; gpa: number; risk_level: string; probability: number;
  attendance_rate: number; active_interventions: number;
}

interface PlanRow {
  id: number; title: string; description: string; status: string;
  priority: string; student_id: number; student_name: string | null;
  deadline: string | null; created_at: string | null;
}

const improvementData = [
  { week: 'W1', improved: 2, stable: 8, declined: 3 },
  { week: 'W2', improved: 3, stable: 7, declined: 3 },
  { week: 'W3', improved: 5, stable: 6, declined: 2 },
  { week: 'W4', improved: 4, stable: 7, declined: 2 },
  { week: 'W5', improved: 6, stable: 5, declined: 2 },
  { week: 'W6', improved: 7, stable: 5, declined: 1 },
];

export function AdvisorDashboard() {
  const [students, setStudents] = useState<StudentRow[]>([]);
  const [plans, setPlans] = useState<PlanRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filterStatus, setFilterStatus] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');

  const fetchAll = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [stuRes, planRes] = await Promise.all([
        fetch(`${BASE}/analytics/students?limit=50`, { headers: authHeader() }),
        fetch(`${BASE}/analytics/interventions?page_size=50`, { headers: authHeader() }),
      ]);
      if (!stuRes.ok) throw new Error(`Students ${stuRes.status}`);
      const stuData = await stuRes.json();
      setStudents((stuData.students ?? stuData ?? []).map((s: any) => ({
        id: s.id,
        name: s.name,
        student_number: s.student_number,
        major: s.major,
        year: s.year ?? 1,
        gpa: s.gpa,
        risk_level: s.risk_level ?? 'Normal',
        probability: s.risk_probability ?? s.probability ?? 0,
        attendance_rate: s.attendance_rate ?? 0,
        active_interventions: s.active_interventions ?? 0,
      })));

      if (planRes.ok) {
        const planData = await planRes.json();
        setPlans(planData.plans ?? []);
      }
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchAll(); }, [fetchAll]);

  const filteredPlans = plans.filter(p => {
    if (filterStatus !== 'all' && p.status !== filterStatus) return false;
    if (searchQuery && !(p.student_name ?? '').toLowerCase().includes(searchQuery.toLowerCase())) return false;
    return true;
  });

  const stats = {
    totalStudents: students.length,
    activeInterventions: plans.filter(p => p.status === 'active').length,
    highRisk: students.filter(s => s.risk_level === 'High' || s.risk_level === 'Critical').length,
    avgGpa: students.length > 0
      ? (students.reduce((acc, s) => acc + s.gpa, 0) / students.length).toFixed(2)
      : '—',
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center space-y-3">
          <div className="w-8 h-8 border-2 border-red-600 border-t-transparent rounded-full animate-spin mx-auto" />
          <p className="text-sm text-neutral-500">Loading advisor dashboard…</p>
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

  const statusColor: Record<string, string> = {
    active: 'bg-green-100 text-green-700',
    pending: 'bg-yellow-100 text-yellow-700',
    completed: 'bg-blue-100 text-blue-700',
    cancelled: 'bg-neutral-100 text-neutral-500',
  };

  const priorityColor: Record<string, string> = {
    high: 'text-red-600',
    medium: 'text-orange-500',
    low: 'text-neutral-500',
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900 dark:text-white">Advisor Dashboard</h1>
          <p className="text-neutral-500 dark:text-neutral-400 mt-0.5">Manage your assigned students and interventions</p>
        </div>
        <div className="flex gap-2">
          <button onClick={fetchAll} className="text-sm text-neutral-500 hover:text-red-600 underline">Refresh</button>
          <button className="btn-primary flex items-center gap-2">
            <Plus className="w-4 h-4" />
            New Intervention
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard title="Total Students" value={stats.totalStudents} icon={Users} color="red" />
        <StatCard title="Active Interventions" value={stats.activeInterventions} icon={Shield} color="orange" />
        <StatCard title="High Risk Students" value={stats.highRisk} subtitle="Need attention" icon={TrendingUp} color="red" />
        <StatCard title="Avg GPA" value={stats.avgGpa} subtitle="All advised students" icon={TrendingUp} color="blue" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Weekly Improvement Chart */}
        <Card title="Student Progress Trend" subtitle="Improvement week by week">
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={improvementData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e5e5" />
                <XAxis dataKey="week" stroke="#737373" fontSize={11} />
                <YAxis stroke="#737373" fontSize={12} />
                <Tooltip contentStyle={{ backgroundColor: 'white', border: '1px solid #e5e5e5', borderRadius: '8px' }} />
                <Area type="monotone" dataKey="improved" stroke="#22c55e" fill="#dcfce7" name="Improved" />
                <Area type="monotone" dataKey="stable" stroke="#64748b" fill="#f1f5f9" name="Stable" />
                <Area type="monotone" dataKey="declined" stroke="#ef4444" fill="#fef2f2" name="Declined" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        {/* Risk Distribution Chart */}
        <Card title="Risk Distribution" subtitle="Students by risk level">
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={[
                { level: 'Normal', count: students.filter(s => s.risk_level === 'Normal').length },
                { level: 'Low',    count: students.filter(s => s.risk_level === 'Low').length },
                { level: 'High',   count: students.filter(s => s.risk_level === 'High').length },
                { level: 'Critical', count: students.filter(s => s.risk_level === 'Critical').length },
              ]}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e5e5" />
                <XAxis dataKey="level" stroke="#737373" fontSize={11} />
                <YAxis stroke="#737373" fontSize={12} allowDecimals={false} />
                <Tooltip contentStyle={{ backgroundColor: 'white', border: '1px solid #e5e5e5', borderRadius: '8px' }} />
                <Bar dataKey="count" fill="#DC2626" radius={[4, 4, 0, 0]} name="Students" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>

      {/* Interventions Table */}
      <Card title="Intervention Plans" subtitle="All active and pending plans from database">
        <div className="space-y-4">
          <div className="flex flex-col sm:flex-row gap-3">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
              <input
                type="text"
                placeholder="Search by student name…"
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                className="w-full pl-9 pr-4 py-2 text-sm border border-neutral-200 dark:border-neutral-700 rounded-lg bg-white dark:bg-neutral-900 text-neutral-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-red-500"
              />
            </div>
            <select
              value={filterStatus}
              onChange={e => setFilterStatus(e.target.value)}
              className="px-3 py-2 text-sm border border-neutral-200 dark:border-neutral-700 rounded-lg bg-white dark:bg-neutral-900 text-neutral-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-red-500"
            >
              <option value="all">All Status</option>
              <option value="active">Active</option>
              <option value="pending">Pending</option>
              <option value="completed">Completed</option>
            </select>
          </div>

          {filteredPlans.length === 0 ? (
            <p className="text-sm text-neutral-500 text-center py-8">No intervention plans found</p>
          ) : (
            <div className="space-y-3">
              {filteredPlans.map(plan => (
                <div key={plan.id} className="p-4 border border-neutral-200 dark:border-neutral-700 rounded-lg hover:bg-neutral-50 dark:hover:bg-neutral-800 transition-colors">
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-neutral-900 dark:text-white truncate">{plan.title}</p>
                      <p className="text-xs text-neutral-500 mt-0.5 line-clamp-2">{plan.description}</p>
                      {plan.student_name && (
                        <p className="text-xs text-red-600 mt-1 font-medium">Student: {plan.student_name}</p>
                      )}
                    </div>
                    <div className="flex flex-col items-end gap-1.5 flex-shrink-0">
                      <span className={cn('text-xs font-medium px-2 py-0.5 rounded-full', statusColor[plan.status] ?? 'bg-neutral-100 text-neutral-500')}>
                        {plan.status}
                      </span>
                      <span className={cn('text-xs font-semibold', priorityColor[plan.priority] ?? 'text-neutral-500')}>
                        {plan.priority} priority
                      </span>
                    </div>
                  </div>
                  {plan.deadline && (
                    <p className="text-xs text-neutral-400 mt-2">
                      Deadline: {new Date(plan.deadline).toLocaleDateString()}
                    </p>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </Card>

      {/* Student List */}
      <Card title="Advised Students" subtitle="All students — live from database">
        <div className="space-y-2">
          {students.slice(0, 10).map(student => (
            <div key={student.id} className="flex items-center gap-4 p-3 rounded-lg hover:bg-neutral-50 dark:hover:bg-neutral-800 transition-colors">
              <div className="w-9 h-9 rounded-full bg-red-100 dark:bg-red-900/20 flex items-center justify-center flex-shrink-0">
                <span className="text-sm font-semibold text-red-700 dark:text-red-400">{student.name.charAt(0)}</span>
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-neutral-900 dark:text-white truncate">{student.name}</p>
                <p className="text-xs text-neutral-500 truncate">{student.major} · Year {student.year} · GPA {student.gpa.toFixed(2)}</p>
              </div>
              <div className="flex items-center gap-3 flex-shrink-0">
                <div className="w-24">
                  <ProgressBar value={student.probability} size="sm" />
                  <p className="text-xs text-neutral-400 mt-0.5 text-right">{student.probability.toFixed(0)}% risk</p>
                </div>
                <Badge variant={student.risk_level.toLowerCase() as any}>{student.risk_level}</Badge>
              </div>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}
