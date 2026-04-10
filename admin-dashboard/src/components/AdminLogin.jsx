import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ShieldCheck, Leaf } from 'lucide-react';
import api from '../config/api';

const AdminLogin = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const res = await api.post('/admin/login', { username, password });
      if (res.data.success) {
        localStorage.setItem('adminToken', res.data.token);
        navigate('/');
      }
    } catch (err) {
      setError('Invalid admin credentials. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const loginStyle = {
    display: 'flex',
    height: '100vh',
    alignItems: 'center',
    justifyContent: 'center',
    background: 'radial-gradient(ellipse at bottom, #1b2735 0%, #090a0f 100%)',
    position: 'relative',
    overflow: 'hidden'
  };

  const cardStyle = {
    width: '400px',
    padding: '40px',
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    zIndex: 1
  };

  const inputStyle = {
    width: '100%',
    padding: '14px 16px',
    marginBottom: '20px',
    background: 'rgba(255, 255, 255, 0.05)',
    border: '1px solid rgba(255, 255, 255, 0.1)',
    borderRadius: '10px',
    color: 'white',
    fontSize: '15px',
    outline: 'none',
    transition: 'all 0.3s ease'
  };

  const buttonStyle = {
    width: '100%',
    padding: '14px',
    background: 'var(--accent-primary)',
    color: 'white',
    border: 'none',
    borderRadius: '10px',
    fontSize: '16px',
    fontWeight: '600',
    cursor: 'pointer',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    gap: '8px',
    transition: 'background 0.3s ease'
  };

  return (
    <div style={loginStyle}>
      <div className="glass-card animate-fade-in" style={cardStyle}>
        <div style={{ background: 'rgba(16, 185, 129, 0.2)', padding: '16px', borderRadius: '50%', marginBottom: '20px' }}>
          <Leaf color="var(--accent-primary)" size={40} />
        </div>
        <h2 style={{ marginBottom: '10px', fontSize: '24px', letterSpacing: '1px' }}>System Admin</h2>
        <p style={{ color: 'var(--text-secondary)', marginBottom: '30px', textAlign: 'center' }}>
          Smart Agriculture Management Dashboard
        </p>

        {error && (
          <div style={{ background: 'rgba(239, 68, 68, 0.1)', color: 'var(--danger)', padding: '12px', borderRadius: '8px', marginBottom: '20px', width: '100%', fontSize: '14px', border: '1px solid rgba(239, 68, 68, 0.2)' }}>
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} style={{ width: '100%' }}>
          <input 
            type="text" 
            placeholder="Username" 
            required 
            style={inputStyle}
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            onFocus={(e) => e.target.style.borderColor = 'var(--accent-primary)'}
            onBlur={(e) => e.target.style.borderColor = 'rgba(255, 255, 255, 0.1)'}
          />
          <input 
            type="password" 
            placeholder="Password" 
            required 
            style={inputStyle}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            onFocus={(e) => e.target.style.borderColor = 'var(--accent-primary)'}
            onBlur={(e) => e.target.style.borderColor = 'rgba(255, 255, 255, 0.1)'}
          />
          <button type="submit" style={buttonStyle} disabled={loading} onMouseOver={(e) => e.target.style.background = 'var(--accent-hover)'} onMouseOut={(e) => e.target.style.background = 'var(--accent-primary)'}>
            {loading ? 'Authenticating...' : (
              <>
                <ShieldCheck size={20} /> Secure Login
              </>
            )}
          </button>
        </form>
      </div>
    </div>
  );
};

export default AdminLogin;
