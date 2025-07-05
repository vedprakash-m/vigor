import {
    Avatar,
    Badge,
    Box,
    Button,
    Container,
    Drawer,
    DrawerBody,
    DrawerCloseButton,
    DrawerContent,
    DrawerHeader,
    DrawerOverlay,
    Flex,
    HStack,
    IconButton,
    Menu,
    MenuButton,
    MenuDivider,
    MenuItem,
    MenuList,
    Text,
    useBreakpointValue,
    useDisclosure,
    VStack,
} from '@chakra-ui/react';
import React, { useState } from 'react';
import {
    FiActivity,
    FiBarChart3,
    FiBell,
    FiHome,
    FiLogOut,
    FiMenu,
    FiMessageSquare,
    FiPlus,
    FiSettings,
    FiUser,
    FiUsers,
} from 'react-icons/fi';
import { useLocation, useNavigate } from 'react-router-dom';
import { useVedAuth } from '../contexts/useVedAuth';
import { type UserGamificationStats } from '../services/gamificationService';

interface MobileLayoutProps {
  children: React.ReactNode;
  gamificationStats?: UserGamificationStats;
}

interface NavigationItem {
  id: string;
  label: string;
  icon: React.ElementType;
  path: string;
  badge?: string | number;
  mobileOnly?: boolean;
  desktopOnly?: boolean;
}

export const MobileLayout: React.FC<MobileLayoutProps> = ({ children, gamificationStats }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, logout } = useVedAuth();
  const { isOpen, onOpen, onClose } = useDisclosure();

  const isMobile = useBreakpointValue({ base: true, md: false });
  const [notifications] = useState(3); // Mock notification count

  const navigationItems: NavigationItem[] = [
    {
      id: 'dashboard',
      label: 'Dashboard',
      icon: FiHome,
      path: '/app/dashboard',
    },
    {
      id: 'workouts',
      label: 'Workouts',
      icon: FiActivity,
      path: '/app/workouts',
    },
    {
      id: 'coach',
      label: 'AI Coach',
      icon: FiMessageSquare,
      path: '/app/coach',
      badge: '2', // Mock unread messages
    },
    {
      id: 'community',
      label: 'Community',
      icon: FiUsers,
      path: '/app/community',
      mobileOnly: true,
    },
    {
      id: 'analytics',
      label: 'Analytics',
      icon: FiBarChart3,
      path: '/app/analytics',
      desktopOnly: true,
    },
    {
      id: 'profile',
      label: 'Profile',
      icon: FiUser,
      path: '/app/profile',
    },
  ];

  const filteredNavItems = navigationItems.filter(item => {
    if (isMobile && item.desktopOnly) return false;
    if (!isMobile && item.mobileOnly) return false;
    return true;
  });

  const handleNavigation = (path: string) => {
    navigate(path);
    if (isMobile) {
      onClose();
    }
  };

  const handleLogout = async () => {
    try {
      await logout();
      navigate('/auth/login');
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  const isActivePath = (path: string) => {
    return location.pathname === path || location.pathname.startsWith(path + '/');
  };

  const getLevelColor = (level: number): string => {
    if (level >= 15) return 'purple';
    if (level >= 10) return 'blue';
    if (level >= 5) return 'green';
    return 'gray';
  };

  // Mobile FAB for quick workout generation
  const QuickActionFAB = () => (
    <IconButton
      aria-label="Generate workout"
      icon={<FiPlus />}
      position="fixed"
      bottom="80px" // Above bottom navigation
      right="16px"
      colorScheme="blue"
      size="lg"
      borderRadius="full"
      onClick={() => navigate('/app/workouts/generate')}
      boxShadow="lg"
      zIndex={10}
      w="56px"
      h="56px"
    />
  );

  // Mobile Bottom Navigation
  const MobileBottomNav = () => (
    <Box
      position="fixed"
      bottom={0}
      left={0}
      right={0}
      bg="white"
      borderTop="1px solid"
      borderColor="gray.200"
      px={2}
      py={2}
      zIndex={20}
      boxShadow="0 -2px 10px rgba(0,0,0,0.1)"
    >
      <HStack justify="space-around" align="center">
        {filteredNavItems.slice(0, 4).map((item) => (
          <VStack
            key={item.id}
            gap={1}
            cursor="pointer"
            onClick={() => handleNavigation(item.path)}
            minW="60px"
            py={1}
            px={2}
            borderRadius="md"
            bg={isActivePath(item.path) ? 'blue.50' : 'transparent'}
            position="relative"
          >
            <Box position="relative">
              <item.icon
                size={20}
                color={isActivePath(item.path) ? '#4299e1' : '#718096'}
              />
              {item.badge && (
                <Badge
                  position="absolute"
                  top="-8px"
                  right="-8px"
                  colorScheme="red"
                  borderRadius="full"
                  fontSize="xs"
                  minW="18px"
                  h="18px"
                  display="flex"
                  alignItems="center"
                  justifyContent="center"
                >
                  {item.badge}
                </Badge>
              )}
            </Box>
            <Text
              fontSize="xs"
              color={isActivePath(item.path) ? 'blue.600' : 'gray.600'}
              fontWeight={isActivePath(item.path) ? 'semibold' : 'normal'}
              textAlign="center"
            >
              {item.label}
            </Text>
          </VStack>
        ))}
      </HStack>
    </Box>
  );

  // Desktop Sidebar
  const DesktopSidebar = () => (
    <Box
      w="240px"
      bg="white"
      borderRight="1px solid"
      borderColor="gray.200"
      h="100vh"
      position="fixed"
      left={0}
      top={0}
      zIndex={10}
      overflowY="auto"
    >
      <VStack gap={6} p={6} align="stretch">
        {/* Logo/Brand */}
        <Box>
          <Text fontSize="xl" fontWeight="bold" color="blue.600">
            Vigor
          </Text>
          {gamificationStats && (
            <HStack mt={2}>
              <Badge colorScheme={getLevelColor(gamificationStats.level)} variant="subtle">
                Level {gamificationStats.level}
              </Badge>
              <Text fontSize="sm" color="gray.600">
                {gamificationStats.totalPoints} pts
              </Text>
            </HStack>
          )}
        </Box>

        {/* Navigation */}
        <VStack gap={2} align="stretch">
          {filteredNavItems.map((item) => (
            <Button
              key={item.id}
              leftIcon={<item.icon />}
              variant={isActivePath(item.path) ? 'solid' : 'ghost'}
              colorScheme={isActivePath(item.path) ? 'blue' : 'gray'}
              justifyContent="flex-start"
              onClick={() => handleNavigation(item.path)}
              position="relative"
            >
              {item.label}
              {item.badge && (
                <Badge
                  position="absolute"
                  top="6px"
                  right="6px"
                  colorScheme="red"
                  borderRadius="full"
                  fontSize="xs"
                >
                  {item.badge}
                </Badge>
              )}
            </Button>
          ))}
        </VStack>

        {/* User Menu */}
        <Box mt="auto">
          <Menu>
            <MenuButton as={Button} variant="ghost" w="full" justifyContent="flex-start">
              <HStack>
                <Avatar size="sm" name={user?.username} />
                <VStack align="start" gap={0}>
                  <Text fontSize="sm" fontWeight="medium">
                    {user?.username}
                  </Text>
                  <Text fontSize="xs" color="gray.500">
                    {user?.email}
                  </Text>
                </VStack>
              </HStack>
            </MenuButton>
            <MenuList>
              <MenuItem icon={<FiSettings />} onClick={() => navigate('/app/settings')}>
                Settings
              </MenuItem>
              <MenuItem icon={<FiBell />}>
                Notifications {notifications > 0 && (
                  <Badge ml={2} colorScheme="red" variant="subtle">{notifications}</Badge>
                )}
              </MenuItem>
              <MenuDivider />
              <MenuItem icon={<FiLogOut />} onClick={handleLogout}>
                Sign Out
              </MenuItem>
            </MenuList>
          </Menu>
        </Box>
      </VStack>
    </Box>
  );

  // Mobile Header
  const MobileHeader = () => (
    <Box
      bg="white"
      borderBottom="1px solid"
      borderColor="gray.200"
      px={4}
      py={3}
      position="sticky"
      top={0}
      zIndex={15}
      boxShadow="sm"
    >
      <Flex justify="space-between" align="center">
        <HStack>
          <IconButton
            aria-label="Open menu"
            icon={<FiMenu />}
            variant="ghost"
            onClick={onOpen}
          />
          <Text fontSize="lg" fontWeight="bold" color="blue.600">
            Vigor
          </Text>
        </HStack>

        <HStack>
          {gamificationStats && (
            <Badge colorScheme={getLevelColor(gamificationStats.level)} variant="subtle">
              Level {gamificationStats.level}
            </Badge>
          )}
          <IconButton
            aria-label="Notifications"
            icon={<FiBell />}
            variant="ghost"
            position="relative"
          >
            {notifications > 0 && (
              <Badge
                position="absolute"
                top="6px"
                right="6px"
                colorScheme="red"
                borderRadius="full"
                fontSize="xs"
                minW="18px"
                h="18px"
              >
                {notifications}
              </Badge>
            )}
          </IconButton>
          <Avatar size="sm" name={user?.username} />
        </HStack>
      </Flex>
    </Box>
  );

  // Mobile Navigation Drawer
  const MobileDrawer = () => (
    <Drawer isOpen={isOpen} placement="left" onClose={onClose}>
      <DrawerOverlay />
      <DrawerContent>
        <DrawerCloseButton />
        <DrawerHeader>
          <VStack align="start" gap={2}>
            <Text fontSize="xl" fontWeight="bold" color="blue.600">
              Vigor
            </Text>
            {user && (
              <HStack>
                <Avatar size="sm" name={user.username} />
                <VStack align="start" gap={0}>
                  <Text fontSize="sm" fontWeight="medium">
                    {user.username}
                  </Text>
                  {gamificationStats && (
                    <HStack>
                      <Badge colorScheme={getLevelColor(gamificationStats.level)} variant="subtle" size="sm">
                        Level {gamificationStats.level}
                      </Badge>
                      <Text fontSize="xs" color="gray.600">
                        {gamificationStats.totalPoints} pts
                      </Text>
                    </HStack>
                  )}
                </VStack>
              </HStack>
            )}
          </VStack>
        </DrawerHeader>

        <DrawerBody>
          <VStack gap={2} align="stretch">
            {navigationItems.map((item) => (
              <Button
                key={item.id}
                leftIcon={<item.icon />}
                variant={isActivePath(item.path) ? 'solid' : 'ghost'}
                colorScheme={isActivePath(item.path) ? 'blue' : 'gray'}
                justifyContent="flex-start"
                onClick={() => handleNavigation(item.path)}
                position="relative"
                w="full"
              >
                {item.label}
                {item.badge && (
                  <Badge
                    position="absolute"
                    top="6px"
                    right="6px"
                    colorScheme="red"
                    borderRadius="full"
                    fontSize="xs"
                  >
                    {item.badge}
                  </Badge>
                )}
              </Button>
            ))}

            <Box mt={6}>
              <Button
                leftIcon={<FiSettings />}
                variant="ghost"
                justifyContent="flex-start"
                onClick={() => handleNavigation('/app/settings')}
                w="full"
              >
                Settings
              </Button>

              <Button
                leftIcon={<FiBell />}
                variant="ghost"
                justifyContent="flex-start"
                w="full"
                position="relative"
              >
                Notifications
                {notifications > 0 && (
                  <Badge
                    position="absolute"
                    top="6px"
                    right="6px"
                    colorScheme="red"
                    borderRadius="full"
                    fontSize="xs"
                  >
                    {notifications}
                  </Badge>
                )}
              </Button>

              <Button
                leftIcon={<FiLogOut />}
                variant="ghost"
                justifyContent="flex-start"
                onClick={handleLogout}
                w="full"
                color="red.600"
              >
                Sign Out
              </Button>
            </Box>
          </VStack>
        </DrawerBody>
      </DrawerContent>
    </Drawer>
  );

  return (
    <Box>
      {/* Mobile Layout */}
      {isMobile ? (
        <>
          <MobileHeader />
          <MobileDrawer />
          <Box pb="80px" minH="calc(100vh - 60px)">
            <Container maxW="container.xl" px={4}>
              {children}
            </Container>
          </Box>
          <MobileBottomNav />
          <QuickActionFAB />
        </>
      ) : (
        /* Desktop Layout */
        <Flex>
          <DesktopSidebar />
          <Box flex={1} ml="240px" minH="100vh" bg="gray.50">
            <Container maxW="container.xl" py={6}>
              {children}
            </Container>
          </Box>
        </Flex>
      )}
    </Box>
  );
};

export default MobileLayout;
