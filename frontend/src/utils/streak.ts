export function computeStreakUtc(dates: string[]): number {
  // Accept ISO date strings representing days user worked out.
  // Convert to UTC midnight and compute consecutive days ending at today (UTC).
  const uniqueDays = new Set(
    dates.map((d) => {
      const dt = new Date(d)
      return Date.UTC(dt.getUTCFullYear(), dt.getUTCMonth(), dt.getUTCDate())
    })
  )

  let streak = 0
  let current = new Date()
  // Set to UTC midnight today
  current = new Date(Date.UTC(current.getUTCFullYear(), current.getUTCMonth(), current.getUTCDate()))

  while (uniqueDays.has(current.getTime())) {
    streak += 1
    current = new Date(current.getTime() - 86400_000) // previous day
  }
  return streak
}
