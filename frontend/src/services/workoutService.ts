export const workoutService = {
  async getWorkoutDays(): Promise<string[]> {
    try {
      const resp = await fetch('/api/workouts/days', {
        credentials: 'include'
      })
      if (!resp.ok) {
        console.warn('Failed to fetch workout days', resp.status)
        return []
      }
      return (await resp.json()) as string[]
    } catch (err) {
      console.error('Error fetching workout days', err)
      return []
    }
  }
}
