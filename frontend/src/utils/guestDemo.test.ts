import { getDemoProgress } from './guestDemo'

describe('guestDemo utilities', () => {
  beforeEach(() => {
    // Mock current date to 2024-12-15
    jest.useFakeTimers()
    jest.setSystemTime(new Date('2024-12-15T10:00:00Z'))
  })

  afterEach(() => {
    jest.useRealTimers()
  })

  describe('getDemoProgress', () => {
    it('returns array of 7 days ending today', () => {
      const progress = getDemoProgress()

      expect(progress).toHaveLength(7)
      expect(progress[0]).toBe('2024-12-09T10:00:00.000Z') // 6 days ago
      expect(progress[1]).toBe('2024-12-10T10:00:00.000Z') // 5 days ago
      expect(progress[2]).toBe('2024-12-11T10:00:00.000Z') // 4 days ago
      expect(progress[3]).toBe('2024-12-12T10:00:00.000Z') // 3 days ago
      expect(progress[4]).toBe('2024-12-13T10:00:00.000Z') // 2 days ago
      expect(progress[5]).toBe('2024-12-14T10:00:00.000Z') // 1 day ago
      expect(progress[6]).toBe('2024-12-15T10:00:00.000Z') // today
    })

    it('returns consecutive days in chronological order', () => {
      const progress = getDemoProgress()

      // Check that each day is one day after the previous
      for (let i = 1; i < progress.length; i++) {
        const currentDay = new Date(progress[i])
        const previousDay = new Date(progress[i - 1])
        const diffInDays = (currentDay.getTime() - previousDay.getTime()) / (1000 * 60 * 60 * 24)

        expect(diffInDays).toBe(1)
      }
    })

    it('handles different current dates correctly', () => {
      // Mock to a different date
      jest.setSystemTime(new Date('2024-01-01T12:00:00Z'))

      const progress = getDemoProgress()

      expect(progress).toHaveLength(7)
      expect(progress[0]).toBe('2023-12-26T12:00:00.000Z') // 6 days ago
      expect(progress[6]).toBe('2024-01-01T12:00:00.000Z') // today
    })

    it('handles leap year correctly', () => {
      // Mock to March 1, 2024 (after leap day)
      jest.setSystemTime(new Date('2024-03-01T10:00:00Z'))

      const progress = getDemoProgress()

      expect(progress).toHaveLength(7)
      expect(progress[0]).toBe('2024-02-24T10:00:00.000Z') // 6 days ago (includes leap day)
      expect(progress[6]).toBe('2024-03-01T10:00:00.000Z') // today
    })

    it('handles month boundary correctly', () => {
      // Mock to January 1, 2024
      jest.setSystemTime(new Date('2024-01-01T10:00:00Z'))

      const progress = getDemoProgress()

      expect(progress).toHaveLength(7)
      expect(progress[0]).toBe('2023-12-26T10:00:00.000Z') // 6 days ago (previous year)
      expect(progress[6]).toBe('2024-01-01T10:00:00.000Z') // today
    })

    it('handles year boundary correctly', () => {
      // Mock to January 1, 2024
      jest.setSystemTime(new Date('2024-01-01T10:00:00Z'))

      const progress = getDemoProgress()

      expect(progress).toHaveLength(7)
      expect(progress[0]).toBe('2023-12-26T10:00:00.000Z') // 6 days ago (2023)
      expect(progress[6]).toBe('2024-01-01T10:00:00.000Z') // today (2024)
    })

    it('maintains consistent time of day', () => {
      const progress = getDemoProgress()

      // All dates should have the same time component
      const expectedTime = '10:00:00.000Z'

      progress.forEach(dateString => {
        expect(dateString).toContain(expectedTime)
      })
    })
  })
})
