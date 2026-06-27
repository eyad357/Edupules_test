import { useState, useEffect, useCallback } from 'react';
import { AlertTriangle, Flame, Info } from 'lucide-react';
import { Card } from '../../components/ui/Card';
import { Badge } from '../../components/ui/Badge';
import { ProgressBar } from '../../components/ui/ProgressBar';
import { cn } from '../../lib/utils';
import {
  ScatterChart, Scatter, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, Cell
} from 'recharts';

const BASE = (import.meta as any).env?.VITE_FASTAPI_URL ?? 'http://localhost:8000/api/v1';
const TOKEN_KEY = 'eduguard_token';
const authHeader = () => ({ Authorization: `Bearer ${localStorage.getItem(TOKEN_KEY)}` });

const riskColors: Record<string, string> = {
  Normal: '#10b981', Low: '#f59e0b', High: '#f97316', Critical: '#dc2626',
};
const riskBg: Record<string, string> = {
  Normal: 'bg-emerald-50 dark:bg-emerald-900/10 border-emerald-200 dark:border-emerald-900/30',
  Low: 'bg-yellow-50 dark:bg-yellow-900/10 border-yellow-200 dark:border-yellow-900/30',
  High: 'bg-orange-50 dark:bg-orange-900/10 border-orange-200 dark:border-orange-900/30',
  Critical: 'bg-red-50 dark:bg-red-900/10 border-red-200 dark:border-red-900/30',
};

interface StudentRisk {
  id: number; name: string; major: string; gpa: number;
  risk_level: string; probability: number;
  attendance_impact: number; grades_impact: number;
}

export function RiskHeatmap() {
  const [students, setStudents] = useState<StudentRisk[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedLevel, setSelectedLevel] = useState<string | null>(null);

  const fetchStudents = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch(`${BASE}/analytics/students?limit=100`, { headers: authHeader() });
      if (!res.ok) throw new Error(`${res.status}`);
      const data = await res.json();
      setStudents((data.students ?? data ?? []).map((s: any) => ({
        id: s.id, name: s.name, major: s.major, gpa: s.gpa,
        risk_level: s.risk_level ?? 'Normal',
        probability: s.risk_probability ?? s.probability ?? 0,
        attendance_impact: s.attendance_impact ?? 0,
        grades_impact: s.grades_impact ?? 0,
      })));
    } catch { /* empty */ }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { fetchStudents(); }, [fetchStudents]);

  const filtered = selectedLevel
    ? students.filter(s => s.risk_level === selectedLevel)
    : students;

  const scatterData = students.map(s => ({
    name: s.name,
    x: s.attendance_impact,
    y: s.grades_impact,
    z: s.probability,
    level: s.risk_level,
  }));

  const levelCounts: Record<string, number> = {
    Critical: students.filter(s => s.risk_level === 'Critical').length,
    High:     students.filter(s => s.risk_level === 'High').length,
    Low:      students.filter(s => s.risk_level === 'Low').length,
    Normal:   students.filter(s => s.risk_level === 'Normal').length,
  };
  const total = students.length || 1;

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="w-8 h-8 border-2 border-red-600 border-t-transparent rounded-full animate-spin mx-auto" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900 dark:text-white">Risk Heatmap</h1>
          <p className="text-neutral-500 dark:text-neutral-400 mt-0.5">Visual overview of student risk levels — live from database</p>
        </div>
        <button onClick={fetchStudents} className="text-sm text-neutral-400 hover:text-red-600 underline">Refresh</button>
      </div>

      {/* Risk level summary cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {(['Critical', 'High', 'Low', 'Normal'] as const).map(level => (
          <button
            key={level}
            onClick={() => setSelectedLevel(selectedLevel === level ? null : level)}
            className={cn(
              'p-4 rounded-xl border text-left transition-all duration-200',
              riskBg[level],
              selectedLevel === level ? 'ring-2 ring-offset-1 shadow-md' : 'hover:shadow-sm'
            )}
          >
            <div className="flex items-center justify-between mb-2">
              <Flame className="w-5 h-5" style={{ color: riskColors[level] }} />
              <span className="text-2xl font-bold text-neutral-900 dark:text-white">{levelCounts[level]}</span>
            </div>
            <p className="text-sm font-medium text-neutral-700 dark:text-neutral-300">{level} Risk</p>
            <p className="text-xs text-neutral-500 mt-0.5">{Math.round(levelCounts[level] / total * 100)}% of students</p>
          </button>
        ))}
      </div>

      {selectedLevel && (
        <div className="flex items-center gap-2 px-4 py-2 rounded-lg bg-neutral-100 dark:bg-neutral-800 text-sm text-neutral-600 dark:text-neutral-400">
          <Info className="w-4 h-4 shrink-0" />
          Showing only <strong className="text-neutral-900 dark:text-white ml-1 mr-1">{selectedLevel}</strong> risk students.
          <button onClick={() => setSelectedLevel(null)} className="ml-auto text-red-600 hover:text-red-700 font-medium">Clear filter</button>
        </div>
      )}

      {/* Scatter Chart */}
      <Card title="Risk Distribution Matrix" subtitle="Grades vs Attendance impact — bubble size = overall risk probability">
        <div className="h-72">
          {scatterData.length === 0 ? (
            <div className="flex items-center justify-center h-full text-sm text-neutral-500">No risk data available</div>
          ) : (
            <ResponsiveContainer width="100%" height="100%">
              <ScatterChart margin={{ top: 10, right: 20, bottom: 10, left: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e5e5" />
                <XAxis type="number" dataKey="x" name="Attendance Impact" stroke="#737373" fontSize={12}
                  label={{ value: 'Attendance Impact (%)', position: 'insideBottom', offset: -5, fontSize: 11, fill: '#737373' }} />
                <YAxis type="number" dataKey="y" name="Grades Impact" stroke="#737373" fontSize={12}
                  label={{ value: 'Grades Impact (%)', angle: -90, position: 'insideLeft', offset: 10, fontSize: 11, fill: '#737373' }} />
                <Tooltip
                  cursor={{ strokeDasharray: '3 3' }}
                  content={({ active, payload }) => {
                    if (active && payload && payload.length) {
                      const d = payload[0].payload;
                      return (
                        <div className="bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-700 rounded-lg p-3 shadow-lg">
                          <p className="font-semibold text-sm text-neutral-900 dark:text-white">{d.name}</p>
                          <p className="text-xs text-neutral-500">Attendance: {d.x}%</p>
                          <p className="text-xs text-neutral-500">Grades: {d.y}%</p>
                          <p className="text-xs font-medium mt-1" style={{ color: riskColors[d.level] }}>{d.level} ({d.z.toFixed(0)}%)</p>
                        </div>
                      );
                    }
                    return null;
                  }}
                />
                <Scatter data={scatterData} name="Students">
                  {scatterData.map((entry, i) => (
                    <Cell key={i} fill={riskColors[entry.level]} fillOpacity={0.8} />
                  ))}
                </Scatter>
              </ScatterChart>
            </ResponsiveContainer>
          )}
        </div>
      </Card>

      {/* Student Heatmap Grid */}
      <Card title="Student Risk Grid" subtitle="All students sorted by risk level — live from database">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          {filtered.length === 0 ? (
            <p className="text-sm text-neutral-500 col-span-2 text-center py-8">No students found</p>
          ) : filtered
            .sort((a, b) => b.probability - a.probability)
            .map(student => {
              const riskLevel = student.risk_level;
              return (
                <div
                  key={student.id}
                  className={cn('flex items-center gap-3 p-3 rounded-lg border transition-colors', riskBg[riskLevel])}
                >
                  <div
                    className="w-10 h-10 rounded-lg flex items-center justify-center shrink-0 text-white font-bold text-sm"
                    style={{ backgroundColor: riskColors[riskLevel] }}
                  >
                    {student.name.charAt(0)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2">
                      <p className="text-sm font-medium text-neutral-900 dark:text-white truncate">{student.name}</p>
                      <Badge variant={(riskLevel.toLowerCase() as 'normal' | 'low' | 'high' | 'critical')}>
                        {riskLevel}
                      </Badge>
                    </div>
                    <p className="text-xs text-neutral-500 mt-0.5 truncate">{student.major} · GPA {student.gpa.toFixed(2)}</p>
                    <div className="flex items-center gap-2 mt-1.5">
                      <ProgressBar value={student.probability} size="sm" className="flex-1" />
                      <span className="text-xs font-medium shrink-0" style={{ color: riskColors[riskLevel] }}>
                        {student.probability.toFixed(0)}%
                      </span>
                    </div>
                  </div>
                </div>
              );
            })}
        </div>
      </Card>

      {/* Risk breakdown alert */}
      {students.filter(s => s.risk_level === 'Critical').length > 0 && (
        <div className="flex items-start gap-3 p-4 rounded-xl bg-red-50 dark:bg-red-900/10 border border-red-200 dark:border-red-900/30">
          <AlertTriangle className="w-5 h-5 text-red-600 shrink-0 mt-0.5" />
          <div>
            <p className="text-sm font-semibold text-red-800 dark:text-red-300">Critical Risk Alert</p>
            <p className="text-xs text-red-600 dark:text-red-400 mt-0.5">
              {students.filter(s => s.risk_level === 'Critical').length} student(s) are at critical risk level and require immediate intervention.
              {students.filter(s => s.risk_level === 'Critical').map(s => ` ${s.name}`).join(',')}
            </p>
          </div>
        </div>
      )}
    </div>
  );
}
