/**
 * Accessibility Features Component
 * Provides accessibility settings and context for the application
 */

import React, { createContext, useCallback, useContext, useEffect, useState } from 'react'

interface AccessibilitySettings {
    highContrast: boolean
    reducedMotion: boolean
    fontSize: 'normal' | 'large' | 'x-large'
    screenReaderOptimized: boolean
}

interface AccessibilityContextType {
    settings: AccessibilitySettings
    updateSettings: (settings: Partial<AccessibilitySettings>) => void
    resetSettings: () => void
}

const defaultSettings: AccessibilitySettings = {
    highContrast: false,
    reducedMotion: false,
    fontSize: 'normal',
    screenReaderOptimized: false,
}

const AccessibilityContext = createContext<AccessibilityContextType | undefined>(undefined)

export const useAccessibility = () => {
    const context = useContext(AccessibilityContext)
    if (!context) {
        throw new Error('useAccessibility must be used within AccessibilityProvider')
    }
    return context
}

interface AccessibilityProviderProps {
    children: React.ReactNode
}

export const AccessibilityProvider: React.FC<AccessibilityProviderProps> = ({ children }) => {
    const [settings, setSettings] = useState<AccessibilitySettings>(() => {
        // Load from localStorage on init
        if (typeof window !== 'undefined') {
            const saved = localStorage.getItem('vigor-accessibility')
            if (saved) {
                try {
                    return { ...defaultSettings, ...JSON.parse(saved) }
                } catch {
                    return defaultSettings
                }
            }
        }
        return defaultSettings
    })

    // Detect system preferences
    useEffect(() => {
        if (typeof window === 'undefined') return

        const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)')
        if (mediaQuery.matches && !settings.reducedMotion) {
            setSettings((prev) => ({ ...prev, reducedMotion: true }))
        }

        const handleChange = (e: MediaQueryListEvent) => {
            setSettings((prev) => ({ ...prev, reducedMotion: e.matches }))
        }

        mediaQuery.addEventListener('change', handleChange)
        return () => mediaQuery.removeEventListener('change', handleChange)
    }, [])

    // Apply settings to document
    useEffect(() => {
        const root = document.documentElement

        // High contrast
        if (settings.highContrast) {
            root.classList.add('high-contrast')
        } else {
            root.classList.remove('high-contrast')
        }

        // Reduced motion
        if (settings.reducedMotion) {
            root.classList.add('reduced-motion')
        } else {
            root.classList.remove('reduced-motion')
        }

        // Font size
        root.classList.remove('font-normal', 'font-large', 'font-x-large')
        root.classList.add(`font-${settings.fontSize}`)

        // Screen reader optimizations
        if (settings.screenReaderOptimized) {
            root.setAttribute('aria-busy', 'false')
        }

        // Save to localStorage
        localStorage.setItem('vigor-accessibility', JSON.stringify(settings))
    }, [settings])

    const updateSettings = useCallback((newSettings: Partial<AccessibilitySettings>) => {
        setSettings((prev) => ({ ...prev, ...newSettings }))
    }, [])

    const resetSettings = useCallback(() => {
        setSettings(defaultSettings)
        localStorage.removeItem('vigor-accessibility')
    }, [])

    return (
        <AccessibilityContext.Provider value={{ settings, updateSettings, resetSettings }}>
            {children}
        </AccessibilityContext.Provider>
    )
}

export default AccessibilityProvider
