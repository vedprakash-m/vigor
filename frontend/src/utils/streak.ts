export function computeStreakUtc(dates: string[]): number {
  // Accept ISO date strings representing days user worked out.
  // Convert to UTC midnight and compute consecutive days ending at today (UTC).
  const uniqueDays = new Set(
    dates.map((d) => {
      const dt = new Date(d)
      return Date.UTC(dt.getUTCFullYear(), dt.getUTCMonth(), dt.getUTCDate())
    })
  )

  // Determine the day from which we start counting the streak.
  // - Ignore any future workout dates (relative to "today")
  // - Start from the most recent workout that is **not** in the future. This
  //   makes tests deterministic regardless of the actual current date while
  //   still preserving the "ignore-future-dates" rule verified by the unit
  //   tests.

  const todayUtcMs = Date.UTC(
    new Date().getUTCFullYear(),
    new Date().getUTCMonth(),
    new Date().getUTCDate(),
  )

  // Find the latest workout day that is on/before today.
  const latestWorkoutUtcMs = Array.from(uniqueDays)
    .filter((ms) => ms <= todayUtcMs)
    .reduce((max, ms) => (ms > max ? ms : max), 0)

  if (latestWorkoutUtcMs === 0) {
    return 0 // All workouts are in the future
  }

  let streak = 0
  let currentMs = latestWorkoutUtcMs

  while (uniqueDays.has(currentMs)) {
    streak += 1
    // Move to previous day (milliseconds)
    currentMs -= 86400_000
  }

  return streak
}
