import React, { useState, useRef, useEffect } from 'react';
import api from '../config/api';
import './Chatbot.css';

const Chatbot = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState([
    { id: 1, sender: 'bot', text: 'Hello! I am your Smart Agriculture Assistant. How can I help you today?' }
  ]);
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef(null);

  const toggleChat = () => setIsOpen(!isOpen);

  // Auto-scroll to latest message
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSendMessage = async (e) => {
    e.preventDefault();
    if (!inputValue.trim()) return;

    const userMessage = { id: Date.now(), sender: 'user', text: inputValue };
    setMessages((prev) => [...prev, userMessage]);
    setInputValue('');
    setIsLoading(true);

    try {
      const response = await api.post('/chat', { message: userMessage.text });
      const data = response.data;
      
      const botMessage = {
        id: Date.now() + 1,
        sender: 'bot',
        text: data.reply || data.error || 'Sorry, something went wrong.'
      };
      
      setMessages((prev) => [...prev, botMessage]);
    } catch (error) {
      console.error('Error sending message:', error);
      setMessages((prev) => [
        ...prev,
        { id: Date.now() + 1, sender: 'bot', text: 'Network error. Please try again later.' }
      ]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="chatbot-container">
      {isOpen && (
        <div className="chatbot-window">
          <div className="chatbot-header">
            <h3>🌱 Smart Assistant</h3>
            <button onClick={toggleChat} className="close-btn">&times;</button>
          </div>
          
          <div className="chatbot-messages">
            {messages.map((msg) => (
              <div key={msg.id} className={`message-wrapper ${msg.sender}`}>
                <div className={`message-bubble ${msg.sender}`}>
                  {msg.text}
                </div>
              </div>
            ))}
            {isLoading && (
              <div className="message-wrapper bot">
                <div className="message-bubble bot typing">
                  <div className="dot"></div>
                  <div className="dot"></div>
                  <div className="dot"></div>
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>

          <form className="chatbot-input-form" onSubmit={handleSendMessage}>
            <input
              type="text"
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              placeholder="Ask about crops, weather, etc..."
              disabled={isLoading}
            />
            <button type="submit" disabled={isLoading || !inputValue.trim()}>
              Send
            </button>
          </form>
        </div>
      )}

      {!isOpen && (
        <button className="chatbot-toggle-btn" onClick={toggleChat}>
          💬
        </button>
      )}
    </div>
  );
};

export default Chatbot;
