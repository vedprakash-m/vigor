// Dark mode color tokens with AA contrast compliance
export const darkModeColors = {
  gray: {
    50: '#f7fafc',
    100: '#edf2f7',
    200: '#e2e8f0',
    300: '#cbd5e0',
    400: '#a0aec0',
    500: '#718096',
    600: '#4a5568',
    700: '#2d3748',
    800: '#1a202c',
    900: '#171923',
  },
  // Dark mode specific overrides
  dark: {
    bg: {
      primary: '#1a202c',
      secondary: '#2d3748',
      tertiary: '#4a5568',
      card: '#2d3748',
      modal: '#1a202c',
    },
    text: {
      primary: '#f7fafc',
      secondary: '#e2e8f0',
      tertiary: '#a0aec0',
      inverse: '#1a202c',
    },
    border: {
      primary: '#4a5568',
      secondary: '#2d3748',
      accent: '#3182ce',
    },
    accent: {
      primary: '#3182ce',
      secondary: '#38b2ac',
      success: '#38a169',
      warning: '#d69e2e',
      error: '#e53e3e',
    }
  }
}

// Dark mode component styles
export const darkModeComponents = {
  Button: {
    variants: {
      solid: {
        _dark: {
          bg: 'dark.accent.primary',
          color: 'dark.text.primary',
          _hover: {
            bg: 'blue.600',
          },
        },
      },
      outline: {
        _dark: {
          borderColor: 'dark.border.primary',
          color: 'dark.text.primary',
          _hover: {
            bg: 'dark.bg.secondary',
          },
        },
      },
    },
  },
  Card: {
    baseStyle: {
      _dark: {
        bg: 'dark.bg.card',
        borderColor: 'dark.border.primary',
      },
    },
  },
  Input: {
    variants: {
      outline: {
        _dark: {
          bg: 'dark.bg.secondary',
          borderColor: 'dark.border.primary',
          color: 'dark.text.primary',
          _placeholder: {
            color: 'dark.text.tertiary',
          },
        },
      },
    },
  },
  Textarea: {
    variants: {
      outline: {
        _dark: {
          bg: 'dark.bg.secondary',
          borderColor: 'dark.border.primary',
          color: 'dark.text.primary',
          _placeholder: {
            color: 'dark.text.tertiary',
          },
        },
      },
    },
  },
  Select: {
    variants: {
      outline: {
        _dark: {
          bg: 'dark.bg.secondary',
          borderColor: 'dark.border.primary',
          color: 'dark.text.primary',
        },
      },
    },
  },
  Modal: {
    baseStyle: {
      dialog: {
        _dark: {
          bg: 'dark.bg.modal',
        },
      },
    },
  },
  Drawer: {
    baseStyle: {
      dialog: {
        _dark: {
          bg: 'dark.bg.modal',
        },
      },
    },
  },
}

// Global dark mode styles
export const darkModeStyles = {
  global: {
    body: {
      _dark: {
        bg: 'dark.bg.primary',
        color: 'dark.text.primary',
      },
    },
  },
}

// Dark mode configuration
export const darkModeConfig = {
  initialColorMode: 'light',
  useSystemColorMode: false,
}

export default {
  colors: darkModeColors,
  components: darkModeComponents,
  styles: darkModeStyles,
  config: darkModeConfig,
}
