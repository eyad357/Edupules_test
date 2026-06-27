// Shared hook: fetches TA students from /analytics/ta-full-dashboard
import { useState, useEffect } from 'react';

const BASE = (import.meta as any).env?.VITE_FASTAPI_URL ?? 'http://localhost:8000/api/v1';
const TOKEN_KEY = 'eduguard_token';

export interface TAStudentLive {
  id: number;
  name: string;
  studentId: string;
  section: string;
  absences: number;
  absencePct: number;
  labGrade: number;
  quiz1: number;
  quiz2: number;
  status: 'good' | 'warning' | 'ban';
  notes: string;
}

export interface TASectionLive {
  id: string;
  name: string;
  course: string;
  enrolled: number;
  avg_grade: number;
  at_risk: number;
}

export function useTAStudents() {
  const [students, setStudents] = useState<TAStudentLive[]>([]);
  const [sections, setSections] = useState<TASectionLive[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const headers = { Authorization: `Bearer ${localStorage.getItem(TOKEN_KEY)}` };
    Promise.all([
      fetch(`${BASE}/analytics/ta-full-dashboard`, { headers }),
      fetch(`${BASE}/analytics/ta-sections`, { headers }),
    ])
      .then(async ([dashRes, secRes]) => {
        if (!dashRes.ok) throw new Error(`Dashboard ${dashRes.status}`);
        const dashData = await dashRes.json();
        setStudents((dashData.students ?? []).map((s: any) => ({
          id:         s.id,
          name:       s.name,
          studentId:  s.studentId ?? s.student_number ?? `STU-${s.id}`,
          section:    s.section ?? 'Sec 1',
          absences:   s.absences ?? 0,
          absencePct: s.absencePct ?? 0,
          labGrade:   s.labGrade ?? 0,
          quiz1:      s.quiz1 ?? 0,
          quiz2:      s.quiz2 ?? 0,
          status:     s.status ?? 'good',
          notes:      s.notes ?? '',
        })));

        if (secRes.ok) {
          const secData = await secRes.json();
          setSections((secData.sections ?? []).map((s: any) => ({
            id: String(s.id ?? s.name),
            name: s.name ?? s.section_name ?? 'Sec 1',
            course: s.course_name ?? s.course ?? 'CS201',
            enrolled: s.enrolled ?? 0,
            avg_grade: s.avg_grade ?? 0,
            at_risk: s.at_risk ?? 0,
          })));
        }
      })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  return { students, sections, loading, error };
}