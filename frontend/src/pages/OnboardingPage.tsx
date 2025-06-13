import { Box, Button, CloseButton, Heading, HStack, Input, Text, VStack } from '@chakra-ui/react'
import { useState } from 'react'

const GOAL_OPTIONS = ['Weight Loss', 'Muscle Gain', 'Endurance', 'Flexibility', 'General Fitness']

export const OnboardingPage = () => {
  const [query, setQuery] = useState('')
  const [suggestions, setSuggestions] = useState<string[]>(GOAL_OPTIONS)
  const [selected, setSelected] = useState<string[]>([])
  const [showConsent, setShowConsent] = useState(false)

  const onChange = (val: string) => {
    setQuery(val)
    setSuggestions(GOAL_OPTIONS.filter(g => g.toLowerCase().includes(val.toLowerCase()) && !selected.includes(g)))
  }

  const addGoal = (goal: string) => {
    if (!selected.includes(goal)) setSelected([...selected, goal])
    setQuery('')
    setSuggestions(GOAL_OPTIONS.filter(g => !selected.includes(g)))
  }

  const removeGoal = (goal: string) => {
    setSelected(selected.filter(g => g !== goal))
  }

  const handleAcceptConsent = () => {
    // TODO submit onboarding to backend
    setShowConsent(false)
  }

  return (
    <Box p={8} maxW="lg" mx="auto">
      <Heading mb={4}>Step 1: Select Your Primary Goal</Heading>
      <Text mb={4}>Choose one or more fitness goals. Start typing to search.</Text>
      <Input placeholder="e.g., Weight Loss" value={query} onChange={e=>onChange(e.target.value)} mb={4} />

      <VStack align="start" mb={4}>
        {suggestions.slice(0,5).map(s => (
          <Button key={s} size="sm" variant="ghost" onClick={() => addGoal(s)}>{s}</Button>
        ))}
      </VStack>

      <VStack align="start" mb={6}>
        {selected.map(goal => (
          <HStack key={goal} bg="blue.100" borderRadius="md" px={2} py={1}>
            <Text fontSize="sm">{goal}</Text>
            <CloseButton size="sm" onClick={() => removeGoal(goal)} />
          </HStack>
        ))}
      </VStack>

      <Button colorScheme="blue" disabled={selected.length===0} onClick={()=>setShowConsent(true)}>Continue</Button>

      {showConsent && (
        <Box position="fixed" top={0} left={0} right={0} bottom={0} bg="blackAlpha.600" zIndex={1000} display="flex" alignItems="center" justifyContent="center">
          <Box bg="white" p={6} borderRadius="md" maxW="sm" w="90%">
            <Heading size="md" mb={4}>Data Consent</Heading>
            <Text fontSize="sm" mb={6}>We use your data to personalise your workout plans in accordance with GDPR Article 13. Do you consent?</Text>
            <HStack justifyContent="flex-end">
              <Button variant="ghost" onClick={()=>setShowConsent(false)}>Decline</Button>
              <Button colorScheme="blue" onClick={handleAcceptConsent}>Accept & Continue</Button>
            </HStack>
          </Box>
        </Box>
      )}
    </Box>
  )
}
