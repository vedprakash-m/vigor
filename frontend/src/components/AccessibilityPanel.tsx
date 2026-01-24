/**
 * Accessibility Panel Component
 * UI panel for adjusting accessibility settings
 */

import {
    Box,
    Button,
    Switch as ChakraSwitch,
    Heading,
    HStack,
    Text,
    VStack,
} from '@chakra-ui/react'
import { useAccessibility } from './AccessibilityFeatures'

const AccessibilityPanel = () => {
    const { settings, updateSettings, resetSettings } = useAccessibility()

    return (
        <Box
            bg="white"
            p={4}
            borderRadius="lg"
            shadow="sm"
            border="1px"
            borderColor="gray.200"
        >
            <Heading size="sm" mb={4}>
                Accessibility Settings
            </Heading>
            <VStack align="stretch" gap={3}>
                <HStack justify="space-between">
                    <Text fontSize="sm">High Contrast</Text>
                    <ChakraSwitch.Root
                        checked={settings.highContrast}
                        onCheckedChange={() =>
                            updateSettings({ highContrast: !settings.highContrast })
                        }
                    >
                        <ChakraSwitch.HiddenInput />
                        <ChakraSwitch.Control>
                            <ChakraSwitch.Thumb />
                        </ChakraSwitch.Control>
                    </ChakraSwitch.Root>
                </HStack>

                <HStack justify="space-between">
                    <Text fontSize="sm">Reduce Motion</Text>
                    <ChakraSwitch.Root
                        checked={settings.reducedMotion}
                        onCheckedChange={() =>
                            updateSettings({ reducedMotion: !settings.reducedMotion })
                        }
                    >
                        <ChakraSwitch.HiddenInput />
                        <ChakraSwitch.Control>
                            <ChakraSwitch.Thumb />
                        </ChakraSwitch.Control>
                    </ChakraSwitch.Root>
                </HStack>

                <HStack justify="space-between">
                    <Text fontSize="sm">Screen Reader Optimized</Text>
                    <ChakraSwitch.Root
                        checked={settings.screenReaderOptimized}
                        onCheckedChange={() =>
                            updateSettings({
                                screenReaderOptimized: !settings.screenReaderOptimized,
                            })
                        }
                    >
                        <ChakraSwitch.HiddenInput />
                        <ChakraSwitch.Control>
                            <ChakraSwitch.Thumb />
                        </ChakraSwitch.Control>
                    </ChakraSwitch.Root>
                </HStack>

                <Box>
                    <Text fontSize="sm" mb={2}>
                        Font Size
                    </Text>
                    <HStack gap={2}>
                        {(['normal', 'large', 'x-large'] as const).map((size) => (
                            <Button
                                key={size}
                                size="sm"
                                variant={settings.fontSize === size ? 'solid' : 'outline'}
                                colorScheme={settings.fontSize === size ? 'blue' : 'gray'}
                                onClick={() => updateSettings({ fontSize: size })}
                            >
                                {size === 'normal' ? 'A' : size === 'large' ? 'A+' : 'A++'}
                            </Button>
                        ))}
                    </HStack>
                </Box>

                <Button size="sm" variant="ghost" onClick={resetSettings}>
                    Reset to Defaults
                </Button>
            </VStack>
        </Box>
    )
}

export default AccessibilityPanel
