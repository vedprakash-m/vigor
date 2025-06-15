import { useState } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { useChatStore } from '../../../store/chatStore';

export default function ChatWindow() {
  const { messages, addMessage } = useChatStore();
  const [input, setInput] = useState('');

  const handleSend = () => {
    if (!input.trim()) return;
    addMessage({ id: uuidv4(), role: 'user', content: input });
    setInput('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ flex: 1, overflowY: 'auto', padding: '1rem' }}>
        {messages.map((m) => (
          <div key={m.id} style={{ marginBottom: '0.5rem' }}>
            <strong>{m.role}: </strong>
            {m.content}
          </div>
        ))}
      </div>
      <div style={{ display: 'flex', padding: '1rem', borderTop: '1px solid #eee' }}>
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          style={{ flex: 1, marginRight: '0.5rem' }}
          placeholder="Type a message"
        />
        <button onClick={handleSend}>Send</button>
      </div>
    </div>
  );
}
