/**
 * Admin Configuration
 *
 * Defines admin access control for the Vigor Admin Dashboard.
 * Per UX Spec Part V: Admin access is explicitly granted, never inferred.
 *
 * SECURITY NOTE: This is frontend gating only. Backend re-validates
 * on every admin API call via functions-modernized/shared/config.py
 */

/**
 * List of email addresses with admin access.
 * These users can access /admin/* routes and admin API endpoints.
 */
export const ADMIN_EMAILS: string[] = [
  'vedprakash.m@outlook.com',
  // Add additional admin emails below:
  // 'admin@vigor.app',
];

/**
 * Check if a user email has admin privileges.
 * @param email - The user's email address
 * @returns true if the user is an admin
 */
export function isAdmin(email: string | undefined | null): boolean {
  if (!email) return false;
  return ADMIN_EMAILS.some(
    (adminEmail) => adminEmail.toLowerCase() === email.toLowerCase()
  );
}

/**
 * Admin access denied message
 */
export const ACCESS_DENIED_MESSAGE = {
  title: 'Access Restricted',
  description: "You don't have permission to view this page. Contact an administrator if you need access.",
};

/**
 * Ghost operational modes per Tech Spec §2.4
 */
export type GhostMode = 'NORMAL' | 'SAFE_MODE' | 'DEGRADED' | 'PAUSED';

/**
 * Trust phases per PRD §1.3
 */
export const TRUST_PHASES = [
  { phase: 1, name: 'Observer', description: 'Ghost watches and suggests. All actions require explicit approval.' },
  { phase: 2, name: 'Scheduler', description: 'Ghost proposes calendar blocks with preview. User confirms before blocks appear.' },
  { phase: 3, name: 'Auto-Scheduler', description: 'Ghost adds calendar blocks automatically. User can undo.' },
  { phase: 4, name: 'Transformer', description: 'Ghost auto-adjusts blocks based on real-time data.' },
  { phase: 5, name: 'Full Ghost', description: 'Complete autonomy. Calendar transforms silently.' },
] as const;

export type TrustPhase = typeof TRUST_PHASES[number]['name'];

/**
 * Decision Receipt types per Tech Spec §2.4
 */
export const DecisionType = {
  SCHEDULE: 'SCHEDULE',
  TRANSFORM: 'TRANSFORM',
  REMOVE: 'REMOVE',
  RESCHEDULE: 'RESCHEDULE',
  SKIP_PREDICT: 'SKIP_PREDICT',
  SAFETY_BREAKER: 'SAFETY_BREAKER',
  WORKOUT_MUTATION: 'WORKOUT_MUTATION',
  SCHEDULE_CHANGE: 'SCHEDULE_CHANGE',
  REST_DAY: 'REST_DAY',
  INTENSITY_ADJUSTMENT: 'INTENSITY_ADJUSTMENT',
} as const;

export type DecisionType = (typeof DecisionType)[keyof typeof DecisionType];

export const DecisionOutcome = {
  ACCEPTED: 'ACCEPTED',
  REJECTED: 'REJECTED',
  MODIFIED: 'MODIFIED',
  OVERRIDDEN: 'OVERRIDDEN',
  PENDING: 'PENDING',
} as const;

export type DecisionOutcome = (typeof DecisionOutcome)[keyof typeof DecisionOutcome];

/**
 * Phenome store status per Tech Spec §2.4
 */
export type PhenomeStoreStatus = 'HEALTHY' | 'DEGRADED' | 'STALE' | 'MISSING';

/**
 * Watch connection status
 */
export type WatchStatus = 'CONNECTED' | 'DISCONNECTED' | 'DEGRADED' | 'NEVER_CONNECTED';

/**
 * Tier pricing per PRD §2.4:
 * "If you charge $49/month, users treat it like an executive assistant"
 */
export const TIER_PRICING = {
  free: {
    price: 0,
    interval: 'month',
    features: [
      'Observer phase only',
      'Manual workout logging',
      'Basic Phenome insights',
      'Apple Watch required',
    ],
  },
  premium: {
    price: 49,
    yearlyPrice: 499,
    interval: 'month',
    features: [
      'All Ghost phases unlocked',
      'Full calendar autonomy',
      'Auto-scheduling',
      'Block transformation',
      'Priority support',
      'Advanced Phenome insights',
    ],
  },
  enterprise: {
    price: null, // Custom pricing
    interval: 'month',
    features: [
      'Everything in Premium',
      'API access',
      'Team management',
      'Custom branding',
      'Dedicated support',
      'SLA guarantees',
    ],
  },
} as const;
