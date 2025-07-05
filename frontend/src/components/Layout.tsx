import { Box, Flex, Heading, HStack, Text } from '@chakra-ui/react'
import { Outlet, Link as RouterLink, useLocation } from 'react-router-dom'
import { useVedAuth } from '../contexts/useVedAuth'
import AccessibilityPanel from './AccessibilityPanel'
import PushNotificationSetup from './PushNotificationSetup'

const Links = [
  { name: 'Dashboard', path: '/' },
  { name: 'Analytics', path: '/app/analytics' },
  { name: 'Progress', path: '/app/progress' },
  { name: 'Community', path: '/app/community' },
  { name: 'Workouts', path: '/workouts' },
  { name: 'AI Coach', path: '/coach' },
  { name: 'Premium', path: '/app/premium' },
  { name: 'Profile', path: '/profile' },
]

export const Layout = () => {
  const { user, logout } = useVedAuth()
  const location = useLocation()

  return (
    <Flex minH="100vh" bg="gray.50">
      {/* Sidebar */}
      <Box
        bg="white"
        w="250px"
        p={6}
        borderRight="1px"
        borderRightColor="gray.200"
        display={{ base: 'none', md: 'block' }}
      >
        <Heading size="lg" color="blue.500" mb={8}>
          Vigor
        </Heading>

        <Box>
          {Links.map((link) => (
            <Box key={link.name} mb={2}>
              <RouterLink
                to={link.path}
                style={{
                  display: 'block',
                  padding: '12px',
                  borderRadius: '8px',
                  backgroundColor: location.pathname === link.path ? '#3182CE' : 'transparent',
                  color: location.pathname === link.path ? 'white' : '#2D3748',
                  textDecoration: 'none',
                }}
              >
                {link.name}
              </RouterLink>
            </Box>
          ))}
        </Box>

        <Box mt={8} pt={4} borderTop="1px" borderTopColor="gray.200">
          <Text
            as="button"
            p={3}
            w="100%"
            textAlign="left"
            rounded="md"
            _hover={{ bg: 'gray.100' }}
            onClick={logout}
            cursor="pointer"
          >
            Logout
          </Text>
        </Box>
      </Box>

      {/* Main content */}
      <Box flex="1">
        {/* Header */}
        <Flex
          bg="white"
          px={6}
          py={4}
          align="center"
          justify="space-between"
          borderBottom="1px"
          borderBottomColor="gray.200"
        >
          <Heading size="md" display={{ base: 'block', md: 'none' }}>
            Vigor
          </Heading>

          <HStack gap={4}>
            <AccessibilityPanel />
            <Text>Welcome, {user?.name || user?.email}</Text>
          </HStack>
        </Flex>

        {/* Page content */}
        <Box p={6}>
          <PushNotificationSetup />
          <Outlet />
        </Box>
      </Box>
    </Flex>
  )
}
