import js from '@eslint/js'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import globals from 'globals'
import tseslint from 'typescript-eslint'

export default tseslint.config(
  {
    ignores: [
      'dist',
      'coverage',
      // Compatibility layers that intentionally use 'any' for Chakra UI v2->v3 migration
      'src/components/chakra-compat.tsx',
      'src/components/compat.tsx',
      // Test utilities that need flexible typing
      'src/__tests__/**',
      'src/test-utils.tsx',
    ]
  },
  {
    extends: [js.configs.recommended, ...tseslint.configs.recommended],
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      ecmaVersion: 2020,
      globals: globals.browser,
    },
    plugins: {
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      'react-refresh/only-export-components': [
        'warn',
        { allowConstantExport: true },
      ],
      // Allow explicit any in services that interface with dynamic API responses
      '@typescript-eslint/no-explicit-any': 'warn',
    },
  },
)
