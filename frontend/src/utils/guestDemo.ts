export function getDemoPlan() {
  const stored = localStorage.getItem('demoPlan')
  if (stored) return JSON.parse(stored)
  const plan = {
    name: 'Full Body Starter',
    exercises: [
      { name: 'Push Ups', sets: 3, reps: 12 },
      { name: 'Bodyweight Squats', sets: 3, reps: 15 },
    ],
  }
  localStorage.setItem('demoPlan', JSON.stringify(plan))
  return plan
}

export function saveDemoPlan(plan: Record<string, unknown>) {
  localStorage.setItem('demoPlan', JSON.stringify(plan))
}

export function getDemoProgress() {
  const days: string[] = []
  for (let i = 6; i >= 0; i--) {
    const d = new Date(Date.now() - i*86400_000)
    days.push(d.toISOString())
  }
  return days
}
