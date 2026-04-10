import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Sidebar from './components/Sidebar';
import DashboardOverview from './components/DashboardOverview';
import UsersTable from './components/UsersTable';
import AdminLogin from './components/AdminLogin';
import AlertsTable from './components/AlertsTable';
import FarmsTable from './components/FarmsTable';
import './index.css';

// Simple auth check
const PrivateRoute = ({ children }) => {
  const token = localStorage.getItem('adminToken');
  return token ? children : <Navigate to="/login" />;
};

// Layout wrapper
const DashboardLayout = ({ children }) => {
  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="main-content">
        <div className="page-wrapper animate-fade-in">
          {children}
        </div>
      </main>
    </div>
  );
};

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/login" element={<AdminLogin />} />
        
        <Route path="/" element={
          <PrivateRoute>
            <DashboardLayout>
              <DashboardOverview />
            </DashboardLayout>
          </PrivateRoute>
        } />
        
        <Route path="/users" element={
          <PrivateRoute>
            <DashboardLayout>
              <UsersTable />
            </DashboardLayout>
          </PrivateRoute>
        } />
        
        <Route path="/farms" element={
          <PrivateRoute>
            <DashboardLayout>
              <FarmsTable />
            </DashboardLayout>
          </PrivateRoute>
        } />
        
        <Route path="/alerts" element={
          <PrivateRoute>
            <DashboardLayout>
              <AlertsTable />
            </DashboardLayout>
          </PrivateRoute>
        } />
      </Routes>
    </Router>
  );
}

export default App;
