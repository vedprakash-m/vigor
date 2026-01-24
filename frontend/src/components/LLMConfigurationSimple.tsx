/**
 * LLM Configuration Simple Component
 * Simple configuration interface for AI/LLM settings
 */

import {
    Box,
    Button,
    Card,
    Grid,
    GridItem,
    Heading,
    HStack,
    Input,
    Text,
    VStack,
} from '@chakra-ui/react'
import { useState } from 'react'

interface LLMSettings {
    maxTokens: number
    temperature: number
    topP: number
    frequencyPenalty: number
    presencePenalty: number
    timeout: number
}

const LLMConfigurationManagement = () => {
    const [settings, setSettings] = useState<LLMSettings>({
        maxTokens: 4096,
        temperature: 0.7,
        topP: 1.0,
        frequencyPenalty: 0.0,
        presencePenalty: 0.0,
        timeout: 30000,
    })
    const [isSaving, setIsSaving] = useState(false)

    const handleSave = async () => {
        setIsSaving(true)
        try {
            // In production, this would save to the backend
            await new Promise((resolve) => setTimeout(resolve, 1000))
            alert('Settings saved successfully!')
        } catch (error) {
            console.error('Failed to save settings:', error)
            alert('Failed to save settings')
        } finally {
            setIsSaving(false)
        }
    }

    const handleReset = () => {
        setSettings({
            maxTokens: 4096,
            temperature: 0.7,
            topP: 1.0,
            frequencyPenalty: 0.0,
            presencePenalty: 0.0,
            timeout: 30000,
        })
    }

    return (
        <Box p={6}>
            <VStack align="start" mb={8} gap={2}>
                <Heading size="xl">LLM Configuration</Heading>
                <Text color="gray.600">
                    Configure AI model parameters
                </Text>
            </VStack>

            {/* Current Model */}
            <Card.Root bg="blue.50" borderColor="blue.200" border="1px" borderRadius="lg" mb={6}>
                <Card.Body p={4}>
                    <HStack justify="space-between">
                        <VStack align="start" gap={0}>
                            <Text fontWeight="bold" color="blue.700">
                                Active Model
                            </Text>
                            <Text color="blue.600">
                                OpenAI gpt-5-mini
                            </Text>
                        </VStack>
                        <Box
                            w="12px"
                            h="12px"
                            borderRadius="full"
                            bg="green.400"
                            title="Connected"
                        />
                    </HStack>
                </Card.Body>
            </Card.Root>

            <Grid templateColumns={{ base: '1fr', lg: 'repeat(2, 1fr)' }} gap={6}>
                {/* Generation Parameters */}
                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={6}>
                            <Heading size="md" mb={6}>
                                Generation Parameters
                            </Heading>
                            <VStack align="stretch" gap={4}>
                                <Box>
                                    <HStack justify="space-between" mb={2}>
                                        <Text fontWeight="medium">Max Tokens</Text>
                                        <Text color="gray.500" fontSize="sm">
                                            {settings.maxTokens}
                                        </Text>
                                    </HStack>
                                    <Input
                                        type="number"
                                        value={settings.maxTokens}
                                        onChange={(e) =>
                                            setSettings({
                                                ...settings,
                                                maxTokens: parseInt(e.target.value) || 0,
                                            })
                                        }
                                        min={1}
                                        max={8192}
                                    />
                                    <Text fontSize="xs" color="gray.500" mt={1}>
                                        Maximum number of tokens to generate (1-8192)
                                    </Text>
                                </Box>

                                <Box>
                                    <HStack justify="space-between" mb={2}>
                                        <Text fontWeight="medium">Temperature</Text>
                                        <Text color="gray.500" fontSize="sm">
                                            {settings.temperature}
                                        </Text>
                                    </HStack>
                                    <Input
                                        type="number"
                                        step="0.1"
                                        value={settings.temperature}
                                        onChange={(e) =>
                                            setSettings({
                                                ...settings,
                                                temperature: parseFloat(e.target.value) || 0,
                                            })
                                        }
                                        min={0}
                                        max={2}
                                    />
                                    <Text fontSize="xs" color="gray.500" mt={1}>
                                        Controls randomness. Lower = more focused (0-2)
                                    </Text>
                                </Box>

                                <Box>
                                    <HStack justify="space-between" mb={2}>
                                        <Text fontWeight="medium">Top P</Text>
                                        <Text color="gray.500" fontSize="sm">
                                            {settings.topP}
                                        </Text>
                                    </HStack>
                                    <Input
                                        type="number"
                                        step="0.1"
                                        value={settings.topP}
                                        onChange={(e) =>
                                            setSettings({
                                                ...settings,
                                                topP: parseFloat(e.target.value) || 0,
                                            })
                                        }
                                        min={0}
                                        max={1}
                                    />
                                    <Text fontSize="xs" color="gray.500" mt={1}>
                                        Nucleus sampling threshold (0-1)
                                    </Text>
                                </Box>
                            </VStack>
                        </Card.Body>
                    </Card.Root>
                </GridItem>

                {/* Advanced Parameters */}
                <GridItem>
                    <Card.Root bg="white" shadow="sm" borderRadius="lg">
                        <Card.Body p={6}>
                            <Heading size="md" mb={6}>
                                Advanced Parameters
                            </Heading>
                            <VStack align="stretch" gap={4}>
                                <Box>
                                    <HStack justify="space-between" mb={2}>
                                        <Text fontWeight="medium">Frequency Penalty</Text>
                                        <Text color="gray.500" fontSize="sm">
                                            {settings.frequencyPenalty}
                                        </Text>
                                    </HStack>
                                    <Input
                                        type="number"
                                        step="0.1"
                                        value={settings.frequencyPenalty}
                                        onChange={(e) =>
                                            setSettings({
                                                ...settings,
                                                frequencyPenalty: parseFloat(e.target.value) || 0,
                                            })
                                        }
                                        min={-2}
                                        max={2}
                                    />
                                    <Text fontSize="xs" color="gray.500" mt={1}>
                                        Penalize repeated tokens (-2 to 2)
                                    </Text>
                                </Box>

                                <Box>
                                    <HStack justify="space-between" mb={2}>
                                        <Text fontWeight="medium">Presence Penalty</Text>
                                        <Text color="gray.500" fontSize="sm">
                                            {settings.presencePenalty}
                                        </Text>
                                    </HStack>
                                    <Input
                                        type="number"
                                        step="0.1"
                                        value={settings.presencePenalty}
                                        onChange={(e) =>
                                            setSettings({
                                                ...settings,
                                                presencePenalty: parseFloat(e.target.value) || 0,
                                            })
                                        }
                                        min={-2}
                                        max={2}
                                    />
                                    <Text fontSize="xs" color="gray.500" mt={1}>
                                        Encourage new topics (-2 to 2)
                                    </Text>
                                </Box>

                                <Box>
                                    <HStack justify="space-between" mb={2}>
                                        <Text fontWeight="medium">Timeout (ms)</Text>
                                        <Text color="gray.500" fontSize="sm">
                                            {settings.timeout}
                                        </Text>
                                    </HStack>
                                    <Input
                                        type="number"
                                        value={settings.timeout}
                                        onChange={(e) =>
                                            setSettings({
                                                ...settings,
                                                timeout: parseInt(e.target.value) || 0,
                                            })
                                        }
                                        min={1000}
                                        max={120000}
                                    />
                                    <Text fontSize="xs" color="gray.500" mt={1}>
                                        Request timeout in milliseconds
                                    </Text>
                                </Box>
                            </VStack>
                        </Card.Body>
                    </Card.Root>
                </GridItem>
            </Grid>

            {/* Actions */}
            <HStack mt={6} gap={4}>
                <Button colorScheme="blue" onClick={handleSave} disabled={isSaving}>
                    {isSaving ? 'Saving...' : 'Save Configuration'}
                </Button>
                <Button variant="outline" onClick={handleReset}>
                    Reset to Defaults
                </Button>
            </HStack>

            {/* Info Card */}
            <Card.Root bg="gray.50" borderRadius="lg" mt={8}>
                <Card.Body p={4}>
                    <Text fontSize="sm" color="gray.600">
                        <strong>Note:</strong> Changes to these settings will affect all AI-generated
                        content including workout plans and coach responses. Test changes carefully
                        before deploying to production.
                    </Text>
                </Card.Body>
            </Card.Root>
        </Box>
    )
}

export default LLMConfigurationManagement
