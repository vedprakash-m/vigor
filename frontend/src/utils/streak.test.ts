import { computeStreakUtc } from './streak'

describe('streak utilities', () => {
  beforeEach(() => {
    // Mock current date to 2024-12-15
    jest.useFakeTimers()
    jest.setSystemTime(new Date('2024-12-15T10:00:00Z'))
  })

  afterEach(() => {
    jest.useRealTimers()
  })

  describe('computeStreakUtc', () => {
    it('calculates streak for consecutive days', () => {
      const workoutDates = [
        '2024-12-15T10:00:00Z', // Today
        '2024-12-14T10:00:00Z', // Yesterday
        '2024-12-13T10:00:00Z', // 2 days ago
        '2024-12-12T10:00:00Z', // 3 days ago
      ]

      const streak = computeStreakUtc(workoutDates)
      expect(streak).toBe(4)
    })

    it('returns 0 for no workouts', () => {
      const workoutDates: string[] = []
      const streak = computeStreakUtc(workoutDates)
      expect(streak).toBe(0)
    })

    it('returns 1 for single workout today', () => {
      const workoutDates = ['2024-12-15T10:00:00Z']
      const streak = computeStreakUtc(workoutDates)
      expect(streak).toBe(1)
    })

    it('breaks streak on missing day', () => {
      const workoutDates = [
        '2024-12-15T10:00:00Z', // Today
        '2024-12-13T10:00:00Z', // 2 days ago (missing yesterday)
        '2024-12-12T10:00:00Z', // 3 days ago
      ]

      const streak = computeStreakUtc(workoutDates)
      expect(streak).toBe(1) // Only counts today
    })

    it('handles future dates', () => {
      const workoutDates = [
        '2024-12-16T10:00:00Z', // Tomorrow
        '2024-12-15T10:00:00Z', // Today
        '2024-12-14T10:00:00Z', // Yesterday
      ]

      const streak = computeStreakUtc(workoutDates)
      expect(streak).toBe(2) // Counts today and yesterday, ignores future
    })

    it('handles multiple workouts on same day', () => {
      const workoutDates = [
        '2024-12-15T10:00:00Z', // Today morning
        '2024-12-15T18:00:00Z', // Today evening
        '2024-12-14T10:00:00Z', // Yesterday
      ]

      const streak = computeStreakUtc(workoutDates)
      expect(streak).toBe(2) // Counts as 2 days, not 3
    })

    it('handles different time zones correctly', () => {
      const workoutDates = [
        '2024-12-15T23:59:59Z', // Today late
        '2024-12-14T00:00:00Z', // Yesterday early
        '2024-12-13T12:00:00Z', // 2 days ago
      ]

      const streak = computeStreakUtc(workoutDates)
      expect(streak).toBe(3) // Should count as 3 consecutive days
    })

    it('handles leap year dates', () => {
      // Mock to February 29, 2024 (leap year)
      jest.setSystemTime(new Date('2024-02-29T10:00:00Z'))

      const workoutDates = [
        '2024-02-29T10:00:00Z', // Today (leap day)
        '2024-02-28T10:00:00Z', // Yesterday
        '2024-02-27T10:00:00Z', // 2 days ago
      ]

      const streak = computeStreakUtc(workoutDates)
      expect(streak).toBe(3)
    })
  })
})
