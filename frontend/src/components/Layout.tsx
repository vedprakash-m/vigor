import { Box, Drawer, Flex, Heading, HStack, IconButton, Portal, Text } from '@chakra-ui/react'
import { useState } from 'react'
import { Outlet, Link as RouterLink, useLocation } from 'react-router-dom'
import { useVedAuth } from '../contexts/useVedAuth'
import PushNotificationSetup from './PushNotificationSetup'

// Navigation links with icons for visual hierarchy
const Links = [
  { name: 'Home', path: '/app/dashboard', icon: '🏠' },
  { name: 'Workouts', path: '/app/workouts', icon: '💪' },
  { name: 'Coach', path: '/app/coach', icon: '🤖' },
  { name: 'Progress', path: '/app/progress', icon: '📊' },
  { name: 'Settings', path: '/app/profile', icon: '⚙️' },
]

export const Layout = () => {
  const { user, logout } = useVedAuth()
  const location = useLocation()
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)

  const NavContent = ({ onClose }: { onClose?: () => void }) => (
    <>
      <Box>
        {Links.map((link) => (
          <Box key={link.name} mb={2}>
            <RouterLink
              to={link.path}
              onClick={onClose}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                padding: '12px',
                borderRadius: '8px',
                backgroundColor: location.pathname === link.path ? '#3182CE' : 'transparent',
                color: location.pathname === link.path ? 'white' : '#2D3748',
                textDecoration: 'none',
                transition: 'all 0.2s',
              }}
            >
              <span style={{ fontSize: '1.2em' }}>{link.icon}</span>
              <span>{link.name}</span>
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
          display="flex"
          alignItems="center"
          gap={3}
          _hover={{ bg: 'gray.100' }}
          onClick={() => {
            onClose?.()
            logout()
          }}
          cursor="pointer"
        >
          <span>🚪</span>
          <span>Logout</span>
        </Text>
      </Box>
    </>
  )

  return (
    <Flex minH="100vh" bg="gray.50">
      {/* Desktop Sidebar */}
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
        <NavContent />
      </Box>

      {/* Mobile Drawer */}
      <Drawer.Root
        open={isMobileMenuOpen}
        onOpenChange={(e) => setIsMobileMenuOpen(e.open)}
        placement="start"
      >
        <Portal>
          <Drawer.Backdrop />
          <Drawer.Positioner>
            <Drawer.Content bg="white" maxW="280px">
              <Drawer.Header borderBottomWidth="1px">
                <Heading size="lg" color="blue.500">Vigor</Heading>
                <Drawer.CloseTrigger asChild>
                  <IconButton
                    aria-label="Close menu"
                    variant="ghost"
                    position="absolute"
                    right={4}
                    top={4}
                  >
                    ✕
                  </IconButton>
                </Drawer.CloseTrigger>
              </Drawer.Header>
              <Drawer.Body p={4}>
                <NavContent onClose={() => setIsMobileMenuOpen(false)} />
              </Drawer.Body>
            </Drawer.Content>
          </Drawer.Positioner>
        </Portal>
      </Drawer.Root>

      {/* Main content */}
      <Box flex="1">
        {/* Header - Simplified, accessibility moved to Settings */}
        <Flex
          bg="white"
          px={6}
          py={4}
          align="center"
          justify="space-between"
          borderBottom="1px"
          borderBottomColor="gray.200"
        >
          <HStack gap={2}>
            {/* Mobile menu button */}
            <IconButton
              aria-label="Open menu"
              variant="ghost"
              display={{ base: 'flex', md: 'none' }}
              onClick={() => setIsMobileMenuOpen(true)}
            >
              ☰
            </IconButton>
            <Heading size="md" display={{ base: 'block', md: 'none' }}>
              Vigor
            </Heading>
          </HStack>

          <HStack gap={4}>
            <Text display={{ base: 'none', sm: 'block' }} color="gray.600">
              {user?.name || user?.email}
            </Text>
          </HStack>
        </Flex>

        {/* Page content */}
        <Box p={{ base: 3, md: 6 }}>
          <PushNotificationSetup />
          <Outlet />
        </Box>
      </Box>
    </Flex>
  )
}
