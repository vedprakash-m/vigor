/**
 * Admin Protected Route Component
 *
 * Per UX Spec Part V §5.3: Admin access is explicitly granted, never inferred.
 * This component checks if the authenticated user is in the admin whitelist.
 */

import { Box, Center, Heading, Spinner, Text, VStack } from '@chakra-ui/react';
import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { ACCESS_DENIED_MESSAGE, isAdmin } from '../config/adminConfig';
import { useAuth } from '../contexts/useAuth';

interface AdminProtectedRouteProps {
  children: React.ReactNode;
}

/**
 * Access Denied component shown to non-admin users
 */
const AccessDenied: React.FC = () => {
  return (
    <Center h="100vh" bg="gray.50">
      <VStack gap={4} textAlign="center" p={8}>
        <Box fontSize="4xl">🔒</Box>
        <Heading size="lg" color="gray.700">
          {ACCESS_DENIED_MESSAGE.title}
        </Heading>
        <Text color="gray.500" maxW="400px">
          {ACCESS_DENIED_MESSAGE.description}
        </Text>
      </VStack>
    </Center>
  );
};

/**
 * AdminProtectedRoute wraps admin pages and enforces admin access.
 *
 * Flow:
 * 1. If loading, show spinner
 * 2. If not authenticated, redirect to login
 * 3. If authenticated but not admin, show access denied
 * 4. If admin, render children
 */
export const AdminProtectedRoute: React.FC<AdminProtectedRouteProps> = ({ children }) => {
  const { isAuthenticated, isLoading, user } = useAuth();
  const location = useLocation();

  // Show loading state
  if (isLoading) {
    return (
      <Center h="100vh">
        <Spinner size="xl" color="blue.500" />
      </Center>
    );
  }

  // Redirect to login if not authenticated
  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  // Check admin status
  const userIsAdmin = isAdmin(user?.email);

  if (!userIsAdmin) {
    return <AccessDenied />;
  }

  return <>{children}</>;
};

export default AdminProtectedRoute;
