import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Users, Sprout, CloudRain, Settings, LogOut } from 'lucide-react';

const Sidebar = () => {
  const navigate = useNavigate();

  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    navigate('/login');
  };

  const navItems = [
    { name: 'Overview', path: '/', icon: <LayoutDashboard size={20} /> },
    { name: 'Farmers', path: '/users', icon: <Users size={20} /> },
    { name: 'Farms & AI', path: '/farms', icon: <Sprout size={20} /> },
    { name: 'Alerts', path: '/alerts', icon: <CloudRain size={20} /> },
  ];

  const sidebarStyle = {
    width: 'var(--sidebar-width)',
    height: '100vh',
    background: 'var(--bg-secondary)',
    borderRight: '1px solid var(--glass-border)',
    display: 'flex',
    flexDirection: 'column',
    padding: '24px 0'
  };

  const brandStyle = {
    padding: '0 24px',
    marginBottom: '40px',
    display: 'flex',
    alignItems: 'center',
    gap: '12px'
  };

  const menuStyle = {
    flex: 1,
    display: 'flex',
    flexDirection: 'column',
    gap: '8px',
    padding: '0 16px'
  };

  const navItemStyle = (isActive) => ({
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
    padding: '12px 16px',
    borderRadius: '10px',
    color: isActive ? 'white' : 'var(--text-secondary)',
    background: isActive ? 'var(--accent-primary)' : 'transparent',
    textDecoration: 'none',
    fontWeight: isActive ? '500' : '400',
    transition: 'all 0.2s ease'
  });

  return (
    <div style={sidebarStyle} className="sidebar">
      <div style={brandStyle}>
        <div style={{ background: 'var(--accent-primary)', padding: '8px', borderRadius: '8px', display: 'flex' }}>
          <Sprout color="white" size={24} />
        </div>
        <h2 style={{ fontSize: '18px', fontWeight: '600', letterSpacing: '0.5px' }}>SmartAgri Admin</h2>
      </div>

      <div style={menuStyle}>
        {navItems.map((item) => (
          <NavLink 
            key={item.path}
            to={item.path}
            style={({ isActive }) => navItemStyle(isActive)}
          >
            {item.icon}
            {item.name}
          </NavLink>
        ))}
      </div>

      <div style={{ padding: '24px 16px', borderTop: '1px solid var(--glass-border)' }}>
        <button 
          onClick={handleLogout}
          style={{
            ...navItemStyle(false),
            background: 'transparent',
            border: 'none',
            width: '100%',
            cursor: 'pointer',
            color: 'var(--danger)',
            opacity: 0.8
          }}
        >
          <LogOut size={20} />
          Logout
        </button>
      </div>
    </div>
  );
};

export default Sidebar;
