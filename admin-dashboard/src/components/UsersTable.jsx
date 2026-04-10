import React, { useEffect, useState } from 'react';
import api from '../config/api';

const UsersTable = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const res = await api.get('/admin/users');
        if (res.data.success) {
          setUsers(res.data.users);
        }
      } catch (err) {
        console.error('Failed to fetch users', err);
      } finally {
        setLoading(false);
      }
    };
    fetchUsers();
  }, []);

  const theadStyle = {
    background: 'rgba(255, 255, 255, 0.03)',
    color: 'var(--text-secondary)',
    textTransform: 'uppercase',
    fontSize: '12px',
    letterSpacing: '1px'
  };

  const thStyle = { padding: '16px 24px', textAlign: 'left', fontWeight: '500' };
  const tdStyle = { padding: '16px 24px', borderBottom: '1px solid rgba(255,255,255,0.05)', color: 'var(--text-primary)' };

  return (
    <div>
      <h1 className="page-title">Registered Farmers</h1>
      
      <div className="glass-card" style={{ overflow: 'hidden' }}>
        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>Loading farmers...</div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead style={theadStyle}>
              <tr>
                <th style={thStyle}>ID</th>
                <th style={thStyle}>Name</th>
                <th style={thStyle}>Contact</th>
                <th style={thStyle}>Language</th>
                <th style={thStyle}>Farms Owned</th>
                <th style={thStyle}>Joined</th>
              </tr>
            </thead>
            <tbody>
              {users.map(user => (
                <tr key={user.id} style={{ transition: 'background 0.2s' }} onMouseOver={(e) => e.currentTarget.style.background = 'rgba(255,255,255,0.02)'} onMouseOut={(e) => e.currentTarget.style.background = 'transparent'}>
                  <td style={tdStyle}>#{user.id}</td>
                  <td style={tdStyle}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                      <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: 'linear-gradient(135deg, var(--accent-primary), #0ea5e9)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold', fontSize: '14px' }}>
                        {user.name.charAt(0).toUpperCase()}
                      </div>
                      {user.name}
                    </div>
                  </td>
                  <td style={{...tdStyle, color: 'var(--text-secondary)'}}>
                    <div style={{ fontSize: '14px' }}>{user.email || 'No email'}</div>
                    <div style={{ fontSize: '13px', opacity: 0.7 }}>{user.phone}</div>
                  </td>
                  <td style={tdStyle}>
                    <span style={{ padding: '4px 8px', background: 'rgba(255,255,255,0.1)', borderRadius: '4px', fontSize: '12px', textTransform: 'uppercase' }}>
                      {user.language || 'AR'}
                    </span>
                  </td>
                  <td style={tdStyle}>
                    <div style={{ display: 'inline-flex', padding: '4px 12px', background: user.farms_count > 0 ? 'rgba(16, 185, 129, 0.15)' : 'rgba(245, 158, 11, 0.15)', color: user.farms_count > 0 ? 'var(--accent-primary)' : 'var(--warning)', borderRadius: '20px', fontWeight: '500', fontSize: '13px' }}>
                      {user.farms_count} Farms
                    </div>
                  </td>
                  <td style={{...tdStyle, color: 'var(--text-secondary)', fontSize: '14px'}}>
                    {new Date(user.created_at).toLocaleDateString()}
                  </td>
                </tr>
              ))}
              {users.length === 0 && (
                <tr>
                  <td colSpan="6" style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>No farmers found.</td>
                </tr>
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default UsersTable;
