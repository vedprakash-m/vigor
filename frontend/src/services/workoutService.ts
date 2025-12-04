const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '';

export const workoutService = {
  async getWorkoutDays(): Promise<string[]> {
    try {
      const resp = await fetch(`${API_BASE_URL}/workouts/days`, {
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
