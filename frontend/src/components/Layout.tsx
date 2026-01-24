import { Box, Drawer, Flex, Heading, HStack, IconButton, Portal, Text } from '@chakra-ui/react'
import { useState } from 'react'
import { Outlet, Link as RouterLink, useLocation } from 'react-router-dom'
import { useVedAuth } from '../contexts/useVedAuth'
import AccessibilityPanel from './AccessibilityPanel'
import PushNotificationSetup from './PushNotificationSetup'

const Links = [
  { name: 'Dashboard', path: '/app/dashboard' },
  { name: 'Workouts', path: '/app/workouts' },
  { name: 'AI Coach', path: '/app/coach' },
  { name: 'Progress', path: '/app/progress' },
  { name: 'Profile', path: '/app/profile' },
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
          onClick={() => {
            onClose?.()
            logout()
          }}
          cursor="pointer"
        >
          Logout
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
            <AccessibilityPanel />
            <Text display={{ base: 'none', sm: 'block' }}>{user?.name || user?.email}</Text>
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
