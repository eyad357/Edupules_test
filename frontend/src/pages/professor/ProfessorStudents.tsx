import { useState, useEffect, useCallback } from 'react';
import { Search, TrendingUp, TrendingDown, Minus, UserCheck } from 'lucide-react';
import { Card } from '../../components/ui/Card';
import { Badge } from '../../components/ui/Badge';
import { ProgressBar } from '../../components/ui/ProgressBar';
import { cn } from '../../lib/utils';

const BASE = (import.meta as any).env?.VITE_FASTAPI_URL ?? 'http://localhost:8000/api/v1';
const TOKEN_KEY = 'eduguard_token';
const authHeader = () => ({ Authorization: `Bearer ${localStorage.getItem(TOKEN_KEY)}` });

type SortKey = 'name' | 'gpa' | 'risk' | 'year';
type RiskFilter = 'all' | 'Normal' | 'Low' | 'High' | 'Critical';

interface LiveStudent {
  id: number; name: string; student_number: string; major: string; year: number; gpa: number;
  risk_level: string; probability: number; trend: string;
  grades_impact: number; attendance_impact: number; activity_impact: number;
  dropout_probability: number; graduation_delay_likelihood: number; scholarship_eligibility: number;
  explanation: string;
}

export function ProfessorStudents() {
  const [rawStudents, setRawStudents] = useState<LiveStudent[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [sortKey, setSortKey] = useState<SortKey>('risk');
  const [riskFilter, setRiskFilter] = useState<RiskFilter>('all');
  const [selectedStudent, setSelectedStudent] = useState<number | null>(null);

  const fetchStudents = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch(`${BASE}/analytics/students?limit=100`, { headers: authHeader() });
      if (!res.ok) throw new Error(`${res.status}`);
      const data = await res.json();
      setRawStudents((data.students ?? data ?? []).map((s: any) => ({
        id: s.id, name: s.name, student_number: s.student_number,
        major: s.major, year: s.year ?? 1, gpa: s.gpa,
        risk_level: s.risk_level ?? 'Normal',
        probability: s.risk_probability ?? s.probability ?? 0,
        trend: s.trend ?? 'stable',
        grades_impact: s.grades_impact ?? 0,
        attendance_impact: s.attendance_impact ?? 0,
        activity_impact: s.activity_impact ?? 0,
        dropout_probability: s.dropout_probability ?? 0,
        graduation_delay_likelihood: s.graduation_delay_likelihood ?? 0,
        scholarship_eligibility: s.scholarship_eligibility ?? 0,
        explanation: s.explanation ?? '',
      })));
    } catch { /* silently fallback to empty */ }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { fetchStudents(); }, [fetchStudents]);

  const riskRank: Record<string, number> = { Critical: 3, High: 2, Low: 1, Normal: 0 };

  const students = rawStudents.map(s => ({
    ...s,
    risk: {
      risk_level: s.risk_level, probability: s.probability,
      grades_impact: s.grades_impact, attendance_impact: s.attendance_impact,
      activity_impact: s.activity_impact, dropout_probability: s.dropout_probability,
      graduation_delay_likelihood: s.graduation_delay_likelihood,
      scholarship_eligibility: s.scholarship_eligibility,
      explanation: s.explanation, trend: s.trend,
    },
  }));

  const filtered = students
    .filter(s =>
      (riskFilter === 'all' || s.risk?.risk_level === riskFilter) &&
      (s.name.toLowerCase().includes(search.toLowerCase()) ||
        s.major.toLowerCase().includes(search.toLowerCase()))
    )
    .sort((a, b) => {
      if (sortKey === 'name') return a.name.localeCompare(b.name);
      if (sortKey === 'gpa') return b.gpa - a.gpa;
      if (sortKey === 'risk') return (b.risk?.probability || 0) - (a.risk?.probability || 0);
      if (sortKey === 'year') return a.year - b.year;
      return 0;
    });

  const selectedData = selectedStudent ? students.find(s => s.id === selectedStudent) : null;

  const riskBadgeVariant = (level?: string): 'normal' | 'low' | 'high' | 'critical' => {
    const map: Record<string, 'normal' | 'low' | 'high' | 'critical'> = {
      Normal: 'normal', Low: 'low', High: 'high', Critical: 'critical'
    };
    return map[level || 'Normal'] || 'normal';
  };

  const filterCounts: Record<string, number> = {
    all: students.length,
    Normal: students.filter(s => s.risk?.risk_level === 'Normal').length,
    Low: students.filter(s => s.risk?.risk_level === 'Low').length,
    High: students.filter(s => s.risk?.risk_level === 'High').length,
    Critical: students.filter(s => s.risk?.risk_level === 'Critical').length,
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900 dark:text-white">Students</h1>
        <p className="text-neutral-500 dark:text-neutral-400 mt-0.5">{rawStudents.length} students enrolled across your courses</p>
      </div>

      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
          <input
            type="text"
            placeholder="Search by name or major..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 rounded-lg border border-neutral-200 dark:border-neutral-700 bg-white dark:bg-neutral-900 text-sm text-neutral-900 dark:text-white placeholder-neutral-400 focus:outline-none focus:ring-2 focus:ring-red-500/20 focus:border-red-500"
          />
        </div>
        <div className="flex items-center gap-2">
          <select
            value={sortKey}
            onChange={e => setSortKey(e.target.value as SortKey)}
            className="px-3 py-2 rounded-lg border border-neutral-200 dark:border-neutral-700 bg-white dark:bg-neutral-900 text-sm text-neutral-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-red-500/20"
          >
            <option value="risk">Sort: Risk Level</option>
            <option value="name">Sort: Name</option>
            <option value="gpa">Sort: GPA</option>
            <option value="year">Sort: Year</option>
          </select>
        </div>
      </div>

      <div className="flex flex-wrap gap-2">
        {(['all', 'Normal', 'Low', 'High', 'Critical'] as const).map(f => (
          <button
            key={f}
            onClick={() => setRiskFilter(f)}
            className={cn(
              "px-3 py-1.5 rounded-lg text-xs font-medium transition-all border",
              riskFilter === f
                ? f === 'Critical' ? "bg-red-600 text-white border-red-600"
                  : f === 'High' ? "bg-orange-500 text-white border-orange-500"
                  : f === 'Low' ? "bg-yellow-500 text-white border-yellow-500"
                  : f === 'Normal' ? "bg-emerald-500 text-white border-emerald-500"
                  : "bg-neutral-900 dark:bg-white text-white dark:text-neutral-900 border-neutral-900 dark:border-white"
                : "bg-white dark:bg-neutral-900 text-neutral-600 dark:text-neutral-400 border-neutral-200 dark:border-neutral-700 hover:border-red-300"
            )}
          >
            {f === 'all' ? 'All' : f} ({filterCounts[f]})
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <div className="bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 rounded-xl overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-neutral-100 dark:border-neutral-800">
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-500 dark:text-neutral-400 uppercase tracking-wider">Student</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-500 dark:text-neutral-400 uppercase tracking-wider">Major</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-500 dark:text-neutral-400 uppercase tracking-wider">GPA</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-500 dark:text-neutral-400 uppercase tracking-wider">Risk</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-neutral-500 dark:text-neutral-400 uppercase tracking-wider">Trend</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-neutral-50 dark:divide-neutral-800">
                  {filtered.map(student => (
                    <tr
                      key={student.id}
                      onClick={() => setSelectedStudent(selectedStudent === student.id ? null : student.id)}
                      className={cn(
                        "cursor-pointer transition-colors",
                        selectedStudent === student.id
                          ? "bg-red-50 dark:bg-red-900/10"
                          : "hover:bg-neutral-50 dark:hover:bg-neutral-800/50"
                      )}
                    >
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-red-100 dark:bg-red-900/20 flex items-center justify-center shrink-0">
                            <span className="text-xs font-semibold text-red-700 dark:text-red-400">{student.name.charAt(0)}</span>
                          </div>
                          <div>
                            <p className="text-sm font-medium text-neutral-900 dark:text-white">{student.name}</p>
                            <p className="text-xs text-neutral-500">Year {student.year}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-sm text-neutral-600 dark:text-neutral-400">{student.major}</td>
                      <td className="px-4 py-3">
                        <span className={cn(
                          "text-sm font-semibold",
                          student.gpa >= 3.5 ? "text-emerald-600" :
                          student.gpa >= 2.5 ? "text-neutral-900 dark:text-white" :
                          "text-red-600"
                        )}>
                          {student.gpa.toFixed(2)}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        <div className="space-y-1">
                          <Badge variant={riskBadgeVariant(student.risk?.risk_level)}>
                            {student.risk?.risk_level}
                          </Badge>
                          <ProgressBar value={student.risk?.probability || 0} size="sm" className="w-16" />
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        {student.risk?.trend === 'improving'
                          ? <TrendingUp className="w-4 h-4 text-emerald-500" />
                          : student.risk?.trend === 'declining' || student.risk?.trend === 'sudden_drop'
                          ? <TrendingDown className="w-4 h-4 text-red-500" />
                          : <Minus className="w-4 h-4 text-neutral-400" />
                        }
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div>
          {selectedData ? (
            <Card title="Student Detail">
              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <div className="w-14 h-14 rounded-xl bg-red-100 dark:bg-red-900/20 flex items-center justify-center">
                    <span className="text-2xl font-bold text-red-700 dark:text-red-400">{selectedData.name.charAt(0)}</span>
                  </div>
                  <div>
                    <p className="font-semibold text-neutral-900 dark:text-white">{selectedData.name}</p>
                    <p className="text-sm text-neutral-500">{selectedData.major}</p>
                    <Badge variant={riskBadgeVariant(selectedData.risk?.risk_level)} className="mt-1">
                      {selectedData.risk?.risk_level}
                    </Badge>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  {[
                    { label: 'GPA', value: selectedData.gpa.toFixed(2), color: selectedData.gpa >= 3 ? 'text-emerald-600' : 'text-red-600' },
                    { label: 'Year', value: `Year ${selectedData.year}`, color: 'text-neutral-900 dark:text-white' },
                    { label: 'Risk Score', value: `${selectedData.risk?.probability}%`, color: 'text-orange-600' },
                    { label: 'Dropout Risk', value: `${selectedData.risk?.dropout_probability}%`, color: 'text-red-600' },
                  ].map(item => (
                    <div key={item.label} className="p-3 bg-neutral-50 dark:bg-neutral-800 rounded-lg">
                      <p className="text-xs text-neutral-500 mb-1">{item.label}</p>
                      <p className={cn("text-lg font-bold", item.color)}>{item.value}</p>
                    </div>
                  ))}
                </div>

                <div className="space-y-2">
                  <p className="text-xs font-semibold text-neutral-500 dark:text-neutral-400 uppercase tracking-wider">Risk Factors</p>
                  {[
                    { label: 'Grades Impact', value: selectedData.risk?.grades_impact || 0 },
                    { label: 'Attendance Impact', value: selectedData.risk?.attendance_impact || 0 },
                    { label: 'Activity Impact', value: selectedData.risk?.activity_impact || 0 },
                  ].map(item => (
                    <div key={item.label} className="flex items-center gap-2">
                      <span className="text-xs text-neutral-600 dark:text-neutral-400 w-32 shrink-0">{item.label}</span>
                      <ProgressBar value={item.value} size="sm" className="flex-1" />
                      <span className="text-xs font-medium text-neutral-700 dark:text-neutral-300 w-8 text-right">{item.value}%</span>
                    </div>
                  ))}
                </div>

                <button className="w-full flex items-center justify-center gap-2 py-2 rounded-lg border border-neutral-200 dark:border-neutral-700 text-sm font-medium text-neutral-700 dark:text-neutral-300 hover:bg-neutral-50 dark:hover:bg-neutral-800 transition-colors">
                  ✉ Contact Student
                </button>
              </div>
            </Card>
          ) : (
            <div className="bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 rounded-xl p-8 text-center">
              <UserCheck className="w-10 h-10 text-neutral-300 dark:text-neutral-600 mx-auto mb-3" />
              <p className="text-sm text-neutral-500 dark:text-neutral-400">Click a student row to see detailed information</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
