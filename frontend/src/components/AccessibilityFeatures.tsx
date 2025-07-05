import React, { createContext, useCallback, useContext, useState } from 'react'

// Accessibility context for managing accessibility features
interface AccessibilityContextType {
  highContrast: boolean
  fontSize: 'normal' | 'large' | 'extra-large'
  motionReduced: boolean
  toggleHighContrast: () => void
  setFontSize: (size: 'normal' | 'large' | 'extra-large') => void
  toggleMotionReduced: () => void
}

const AccessibilityContext = createContext<AccessibilityContextType | undefined>(undefined)

export const useAccessibility = () => {
  const context = useContext(AccessibilityContext)
  if (!context) {
    throw new Error('useAccessibility must be used within an AccessibilityProvider')
  }
  return context
}

interface AccessibilityProviderProps {
  children: React.ReactNode
}

export const AccessibilityProvider: React.FC<AccessibilityProviderProps> = ({ children }) => {
  const [highContrast, setHighContrast] = useState(false)
  const [fontSize, setFontSizeState] = useState<'normal' | 'large' | 'extra-large'>('normal')
  const [motionReduced, setMotionReduced] = useState(false)

  const toggleHighContrast = useCallback(() => {
    setHighContrast(prev => !prev)
  }, [])

  const setFontSize = useCallback((size: 'normal' | 'large' | 'extra-large') => {
    setFontSizeState(size)
  }, [])

  const toggleMotionReduced = useCallback(() => {
    setMotionReduced(prev => !prev)
  }, [])

  const contextValue: AccessibilityContextType = {
    highContrast,
    fontSize,
    motionReduced,
    toggleHighContrast,
    setFontSize,
    toggleMotionReduced
  }

  return (
    <AccessibilityContext.Provider value={contextValue}>
      {children}
    </AccessibilityContext.Provider>
  )
}
