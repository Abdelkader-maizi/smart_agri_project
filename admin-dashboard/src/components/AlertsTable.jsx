import React, { useEffect, useState } from 'react';
import api from '../config/api';
import { AlertTriangle, ThermometerSun, Snowflake, Wind, Droplets } from 'lucide-react';

const AlertsTable = () => {
  const [alerts, setAlerts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchAlerts = async () => {
      try {
        const res = await api.get('/admin/alerts');
        if (res.data.success) {
          setAlerts(res.data.alerts);
        }
      } catch (err) {
        console.error('Failed to fetch alerts', err);
      } finally {
        setLoading(false);
      }
    };
    fetchAlerts();
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

  const getAlertUI = (type) => {
    const t = (type || '').toLowerCase();
    if (t.includes('frost')) return { color: '#3b82f6', bg: 'rgba(59, 130, 246, 0.15)', icon: <Snowflake size={16} />, label: 'FROST' };
    if (t.includes('heat') || t.includes('hot')) return { color: '#ef4444', bg: 'rgba(239, 68, 68, 0.15)', icon: <ThermometerSun size={16} />, label: 'HEATWAVE' };
    if (t.includes('wind')) return { color: '#f59e0b', bg: 'rgba(245, 158, 11, 0.15)', icon: <Wind size={16} />, label: 'HIGH WIND' };
    if (t.includes('drought') || t.includes('dry')) return { color: '#d97706', bg: 'rgba(217, 119, 6, 0.15)', icon: <Droplets size={16} />, label: 'DROUGHT' };
    return { color: '#a855f7', bg: 'rgba(168, 85, 247, 0.15)', icon: <AlertTriangle size={16} />, label: (type || 'GENERAL').toUpperCase() };
  };

  return (
    <div className="animate-fade-in">
      <h1 className="page-title">Weather Intelligence & Alerts Log</h1>
      
      <div className="glass-card" style={{ overflow: 'hidden' }}>
        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>Loading alerts data...</div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead style={theadStyle}>
              <tr>
                <th style={thStyle}>Date & Time</th>
                <th style={thStyle}>Farm Affected</th>
                <th style={thStyle}>Risk Level / Type</th>
                <th style={thStyle}>AI Notification Message</th>
              </tr>
            </thead>
            <tbody>
              {alerts.map(alert => {
                const ui = getAlertUI(alert.type);
                return (
                  <tr key={alert.id} style={{ transition: 'background 0.2s' }} onMouseOver={(e) => e.currentTarget.style.background = 'rgba(255,255,255,0.02)'} onMouseOut={(e) => e.currentTarget.style.background = 'transparent'}>
                    <td style={{...tdStyle, color: 'var(--text-secondary)', fontSize: '14px', whiteSpace: 'nowrap'}}>
                      {new Date(alert.alert_date).toLocaleString()}
                    </td>
                    <td style={{...tdStyle, fontWeight: '500'}}>{alert.farm_name || `Farm #${alert.farm_id}`}</td>
                    <td style={tdStyle}>
                      <div style={{ 
                        display: 'inline-flex', alignItems: 'center', gap: '6px', 
                        background: ui.bg, color: ui.color, 
                        padding: '6px 12px', borderRadius: '8px', fontSize: '13px', fontWeight: 'bold', letterSpacing: '0.5px' 
                      }}>
                        {ui.icon} {ui.label}
                      </div>
                    </td>
                    <td style={{...tdStyle, lineHeight: '1.5', fontSize: '14px', opacity: 0.9}}>
                      {alert.message}
                    </td>
                  </tr>
                );
              })}
              {alerts.length === 0 && (
                <tr>
                  <td colSpan="4" style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>No weather alerts have been recorded yet.</td>
                </tr>
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default AlertsTable;
