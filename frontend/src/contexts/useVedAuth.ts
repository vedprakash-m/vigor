/**
 * VedAuth Hook for Microsoft Entra ID Authentication
 * Separated for Fast Refresh compatibility
 */

import { useContext } from 'react';
import { VedAuthContext } from './VedAuthContext';

export const useVedAuth = () => {
  const context = useContext(VedAuthContext);
  if (context === undefined) {
    throw new Error('useVedAuth must be used within a VedAuthProvider');
  }
  return context;
};
