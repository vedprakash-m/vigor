/**
 * Gamification Service
 * Handles streaks, badges, achievements, and motivational features
 * Aligned with PRD gamification requirements
 */

export interface Streak {
  type: 'daily' | 'weekly' | 'monthly'
  current: number
  best: number
  lastUpdated: string
  isActive: boolean
}

export interface Badge {
  id: string
  name: string
  description: string
  icon: string
  category: 'streak' | 'achievement' | 'milestone' | 'exploration'
  unlockedAt?: string
  progress?: {
    current: number
    target: number
  }
}

export interface Achievement {
  id: string
  title: string
  description: string
  points: number
  unlockedAt?: string
  requirements: {
    type: 'workout_count' | 'streak_days' | 'ai_interactions' | 'equipment_types' | 'consistency'
    target: number
    timeframe?: string
  }
}

export interface UserGamificationStats {
  totalPoints: number
  level: number
  streaks: {
    daily: Streak
    weekly: Streak
    monthly: Streak
  }
  badges: Badge[]
  achievements: Achievement[]
  weeklyConsistency: number
  aiInteractions: number
  workoutCount: number
  equipmentTypesUsed: string[]
}

// PRD-specified badge definitions
const BADGE_DEFINITIONS: Omit<Badge, 'unlockedAt' | 'progress'>[] = [
  {
    id: 'form_master',
    name: 'Form Master',
    description: 'Complete 50 workouts with AI form feedback',
    icon: '🎯',
    category: 'achievement',
  },
  {
    id: 'equipment_adapter',
    name: 'Equipment Adapter',
    description: 'Use 5+ different equipment types',
    icon: '🏋️',
    category: 'exploration',
  },
  {
    id: 'coach_conversationalist',
    name: 'Coach Conversationalist',
    description: '100+ meaningful AI coaching interactions',
    icon: '💬',
    category: 'achievement',
  },
  {
    id: 'plateau_buster',
    name: 'Plateau Buster',
    description: 'Achieve 3+ personal records in a month',
    icon: '📈',
    category: 'milestone',
  },
  {
    id: 'early_bird',
    name: 'Early Bird',
    description: 'Complete 20 morning workouts (before 9 AM)',
    icon: '🌅',
    category: 'achievement',
  },
  {
    id: 'consistency_king',
    name: 'Consistency King',
    description: 'Maintain 30+ day streaks',
    icon: '👑',
    category: 'streak',
  },
  {
    id: 'ai_explorer',
    name: 'AI Explorer',
    description: 'Use all 3 AI providers (OpenAI, Gemini, Perplexity)',
    icon: '🤖',
    category: 'exploration',
  },
  {
    id: 'week_warrior',
    name: 'Week Warrior',
    description: 'Complete 7 consecutive days of workouts',
    icon: '⚔️',
    category: 'streak',
  },
  {
    id: 'fitness_freshman',
    name: 'Fitness Freshman',
    description: 'Complete your first workout',
    icon: '🎓',
    category: 'milestone',
  },
  {
    id: 'month_champion',
    name: 'Month Champion',
    description: 'Maintain weekly consistency for a full month',
    icon: '🏆',
    category: 'streak',
  },
]

class GamificationService {
  private readonly API_BASE = import.meta.env.VITE_API_BASE_URL || '/api'

  /**
   * Calculate streak based on workout history
   */
  calculateStreak(workoutDates: string[], type: 'daily' | 'weekly' | 'monthly'): Streak {
    if (!workoutDates.length) {
      return {
        type,
        current: 0,
        best: 0,
        lastUpdated: new Date().toISOString(),
        isActive: false,
      }
    }

    const dates = workoutDates.map(d => new Date(d)).sort((a, b) => b.getTime() - a.getTime())
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    let current = 0
    let best = 0
    let tempStreak = 0

    if (type === 'daily') {
      // Daily streak calculation
      const dayMs = 24 * 60 * 60 * 1000

      for (let i = 0; i < dates.length; i++) {
        const workoutDate = new Date(dates[i])
        workoutDate.setHours(0, 0, 0, 0)

        const daysDiff = Math.floor((today.getTime() - workoutDate.getTime()) / dayMs)

        if (i === 0 && daysDiff <= 1) {
          // Current streak calculation
          current = 1
          for (let j = 1; j < dates.length; j++) {
            const prevDate = new Date(dates[j])
            prevDate.setHours(0, 0, 0, 0)
            const prevDiff = Math.floor((dates[j-1].getTime() - prevDate.getTime()) / dayMs)

            if (prevDiff === 1) {
              current++
            } else {
              break
            }
          }
        }

        // Calculate best streak
        tempStreak = 1
        for (let j = i + 1; j < dates.length; j++) {
          const currDate = new Date(dates[j-1])
          const nextDate = new Date(dates[j])
          currDate.setHours(0, 0, 0, 0)
          nextDate.setHours(0, 0, 0, 0)

          const diff = Math.floor((currDate.getTime() - nextDate.getTime()) / dayMs)
          if (diff === 1) {
            tempStreak++
          } else {
            break
          }
        }

        best = Math.max(best, tempStreak)
      }
    }

    return {
      type,
      current,
      best,
      lastUpdated: new Date().toISOString(),
      isActive: current > 0 && current >= best * 0.5, // Active if current is decent
    }
  }

  /**
   * Check and unlock new badges based on user activity
   */
  checkBadgeUnlocks(stats: UserGamificationStats): Badge[] {
    const newBadges: Badge[] = []
    const existingBadgeIds = stats.badges.map(b => b.id)

    for (const badgeDef of BADGE_DEFINITIONS) {
      if (existingBadgeIds.includes(badgeDef.id)) continue

      let shouldUnlock = false
      let progress = { current: 0, target: 0 }

      switch (badgeDef.id) {
        case 'form_master':
          progress = { current: stats.workoutCount, target: 50 }
          shouldUnlock = stats.workoutCount >= 50
          break

        case 'equipment_adapter':
          progress = { current: stats.equipmentTypesUsed.length, target: 5 }
          shouldUnlock = stats.equipmentTypesUsed.length >= 5
          break

        case 'coach_conversationalist':
          progress = { current: stats.aiInteractions, target: 100 }
          shouldUnlock = stats.aiInteractions >= 100
          break

        case 'early_bird':
          // This would need additional data tracking
          progress = { current: 0, target: 20 }
          break

        case 'consistency_king':
          progress = { current: stats.streaks.daily.best, target: 30 }
          shouldUnlock = stats.streaks.daily.best >= 30
          break

        case 'ai_explorer':
          // Would need tracking of AI providers used
          progress = { current: 1, target: 3 }
          break

        case 'week_warrior':
          progress = { current: stats.streaks.daily.current, target: 7 }
          shouldUnlock = stats.streaks.daily.current >= 7
          break

        case 'fitness_freshman':
          progress = { current: stats.workoutCount, target: 1 }
          shouldUnlock = stats.workoutCount >= 1
          break

        case 'month_champion':
          progress = { current: stats.weeklyConsistency, target: 4 }
          shouldUnlock = stats.weeklyConsistency >= 4
          break
      }

      const badge: Badge = {
        ...badgeDef,
        progress,
        ...(shouldUnlock && { unlockedAt: new Date().toISOString() })
      }

      if (shouldUnlock) {
        newBadges.push(badge)
      }
    }

    return newBadges
  }

  /**
   * Calculate user level based on total points
   */
  calculateLevel(totalPoints: number): number {
    // Progressive leveling: 100 points for level 1, 200 for level 2, etc.
    if (totalPoints < 100) return 1
    return Math.floor(Math.sqrt(totalPoints / 100)) + 1
  }

  /**
   * Generate motivational messages based on progress
   */
  getMotivationalMessage(stats: UserGamificationStats): string {
    const { streaks, workoutCount, level } = stats

    if (streaks.daily.current >= 7) {
      return `🔥 Amazing! You're on a ${streaks.daily.current}-day streak!`
    }

    if (streaks.daily.current >= 3) {
      return `💪 Great momentum! ${streaks.daily.current} days strong!`
    }

    if (workoutCount === 1) {
      return `🎉 Congratulations on your first workout!`
    }

    if (level >= 5) {
      return `⭐ Level ${level} achieved! You're becoming a fitness expert!`
    }

    return `🌟 Keep going! Every workout counts towards your goals!`
  }

  /**
   * Get user's gamification stats from backend
   */
  async getUserStats(): Promise<UserGamificationStats> {
    try {
      const response = await fetch(`${this.API_BASE}/gamification/stats`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
      })

      if (!response.ok) {
        throw new Error('Failed to fetch gamification stats')
      }

      return await response.json()
    } catch (error) {
      console.error('Error fetching gamification stats:', error)

      // Return default stats if API fails
      return {
        totalPoints: 0,
        level: 1,
        streaks: {
          daily: { type: 'daily', current: 0, best: 0, lastUpdated: new Date().toISOString(), isActive: false },
          weekly: { type: 'weekly', current: 0, best: 0, lastUpdated: new Date().toISOString(), isActive: false },
          monthly: { type: 'monthly', current: 0, best: 0, lastUpdated: new Date().toISOString(), isActive: false },
        },
        badges: [],
        achievements: [],
        weeklyConsistency: 0,
        aiInteractions: 0,
        workoutCount: 0,
        equipmentTypesUsed: [],
      }
    }
  }

  /**
   * Update stats after workout completion
   */
  async updateStatsAfterWorkout(): Promise<void> {
    try {
      await fetch(`${this.API_BASE}/gamification/workout-completed`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          completedAt: new Date().toISOString(),
        }),
      })
    } catch (error) {
      console.error('Error updating gamification stats:', error)
    }
  }

  /**
   * Get available badges with progress
   */
  getAllBadges(): Badge[] {
    return BADGE_DEFINITIONS.map(badge => ({
      ...badge,
      progress: { current: 0, target: 0 }, // Will be populated by checkBadgeUnlocks
    }))
  }
}

export const gamificationService = new GamificationService()
export default GamificationService
