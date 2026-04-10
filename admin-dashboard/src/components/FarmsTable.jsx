import React, { useEffect, useState } from 'react';
import api from '../config/api';
import { MapPin } from 'lucide-react';

const FarmsTable = () => {
  const [farms, setFarms] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchFarms = async () => {
      try {
        const res = await api.get('/admin/farms');
        if (res.data.success) {
          setFarms(res.data.farms);
        }
      } catch (err) {
        console.error('Failed to fetch farms', err);
      } finally {
        setLoading(false);
      }
    };
    fetchFarms();
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
    <div className="animate-fade-in">
      <h1 className="page-title">Registered Farms & Locations</h1>
      
      <div className="glass-card" style={{ overflow: 'hidden' }}>
        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>Loading farms data...</div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead style={theadStyle}>
              <tr>
                <th style={thStyle}>Farm ID</th>
                <th style={thStyle}>Farm Name</th>
                <th style={thStyle}>Owner</th>
                <th style={thStyle}>Location Coordinates</th>
                <th style={thStyle}>Registration Date</th>
              </tr>
            </thead>
            <tbody>
              {farms.map(farm => (
                <tr key={farm.id} style={{ transition: 'background 0.2s' }} onMouseOver={(e) => e.currentTarget.style.background = 'rgba(255,255,255,0.02)'} onMouseOut={(e) => e.currentTarget.style.background = 'transparent'}>
                  <td style={tdStyle}>
                    <span style={{ color: 'var(--text-secondary)', fontWeight: 'bold' }}>#{farm.id}</span>
                  </td>
                  <td style={tdStyle}>
                    <div style={{ fontWeight: 500, color: 'var(--accent-primary)' }}>{farm.name || 'Unnamed Farm'}</div>
                  </td>
                  <td style={tdStyle}>{farm.owner_name || 'Unknown'}</td>
                  <td style={tdStyle}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <MapPin size={16} color="var(--info)" />
                      {farm.latitude ? `${farm.latitude.toFixed(4)}, ${farm.longitude.toFixed(4)}` : (farm.location || 'Not Provided')}
                    </div>
                  </td>
                  <td style={{...tdStyle, color: 'var(--text-secondary)', fontSize: '14px'}}>
                    {new Date(farm.created_at).toLocaleDateString()}
                  </td>
                </tr>
              ))}
              {farms.length === 0 && (
                <tr>
                  <td colSpan="5" style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>No farms registered yet.</td>
                </tr>
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default FarmsTable;
