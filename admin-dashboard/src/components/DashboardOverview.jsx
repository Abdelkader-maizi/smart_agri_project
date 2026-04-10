import React, { useEffect, useState } from 'react';
import { Users, Trees, Activity, BellRing } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts';
import api from '../config/api';

const DashboardOverview = () => {
  const [stats, setStats] = useState({ total_users: 0, total_farms: 0, total_logs: 0 });
  const [loading, setLoading] = useState(true);

  // Mock data for crops chart if API is empty
  const [cropData, setCropData] = useState([
    { name: 'Wheat', count: 120 },
    { name: 'Potato', count: 85 },
    { name: 'Tomato', count: 65 },
    { name: 'Corn', count: 40 },
  ]);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const res = await api.get('/admin/stats');
        if (res.data.success) {
          setStats(res.data.stats);
          if (res.data.stats.top_crops && res.data.stats.top_crops.length > 0) {
            setCropData(res.data.stats.top_crops);
          }
        }
      } catch (err) {
        console.error('Failed to fetch stats', err);
      } finally {
        setLoading(false);
      }
    };
    fetchStats();
  }, []);

  const StatCard = ({ title, value, icon, color }) => (
    <div className="glass-card" style={{ padding: '24px', display: 'flex', alignItems: 'center', gap: '20px', flex: '1', minWidth: '200px' }}>
      <div style={{ background: `rgba(${color}, 0.15)`, padding: '16px', borderRadius: '16px', display: 'flex' }}>
        {icon}
      </div>
      <div>
        <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '4px', textTransform: 'uppercase', letterSpacing: '1px' }}>{title}</p>
        <h3 style={{ fontSize: '28px', fontWeight: '700' }}>{loading ? '...' : value}</h3>
      </div>
    </div>
  );

  return (
    <div>
      <h1 className="page-title">System Overview</h1>
      
      <div style={{ display: 'flex', gap: '24px', marginBottom: '40px', flexWrap: 'wrap' }}>
        <StatCard title="Total Farmers" value={stats.total_users} icon={<Users color="#3b82f6" size={28} />} color="59, 130, 246" />
        <StatCard title="Active Farms" value={stats.total_farms} icon={<Trees color="#10b981" size={28} />} color="16, 185, 129" />
        <StatCard title="AI Activities Logs" value={stats.total_logs} icon={<Activity color="#8b5cf6" size={28} />} color="139, 92, 246" />
        <StatCard title="Weather Alerts" value={34} icon={<BellRing color="#f59e0b" size={28} />} color="245, 158, 11" />
      </div>

      <div style={{ display: 'flex', gap: '24px' }}>
        <div className="glass-card" style={{ flex: 2, padding: '24px' }}>
          <h3 style={{ marginBottom: '24px', fontWeight: '600' }}>Crop Distribution</h3>
          <div style={{ height: '300px', width: '100%' }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={cropData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <XAxis dataKey="name" stroke="var(--text-secondary)" tickLine={false} axisLine={false} />
                <YAxis stroke="var(--text-secondary)" tickLine={false} axisLine={false} />
                <Tooltip 
                  cursor={{fill: 'rgba(255,255,255,0.05)'}}
                  contentStyle={{ background: 'var(--bg-secondary)', border: 'none', borderRadius: '8px', color: 'white' }} 
                />
                <Bar dataKey="count" radius={[6, 6, 0, 0]}>
                  {cropData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={index % 2 === 0 ? 'var(--accent-primary)' : '#0ea5e9'} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="glass-card" style={{ flex: 1, padding: '24px' }}>
          <h3 style={{ marginBottom: '24px', fontWeight: '600' }}>System Health</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '16px', background: 'rgba(255,255,255,0.02)', borderRadius: '12px' }}>
              <span style={{ color: 'var(--text-secondary)' }}>AI Server (FastAPI)</span>
              <span style={{ color: 'var(--accent-primary)', fontWeight: '500', display: 'flex', alignItems: 'center', gap:'6px' }}><div style={{width:'8px',height:'8px',background:'var(--accent-primary)',borderRadius:'50%'}}></div> Online</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '16px', background: 'rgba(255,255,255,0.02)', borderRadius: '12px' }}>
              <span style={{ color: 'var(--text-secondary)' }}>PostgreSQL</span>
              <span style={{ color: 'var(--accent-primary)', fontWeight: '500', display: 'flex', alignItems: 'center', gap:'6px' }}><div style={{width:'8px',height:'8px',background:'var(--accent-primary)',borderRadius:'50%'}}></div> Stable</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashboardOverview;
