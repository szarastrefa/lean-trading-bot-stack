import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Container } from 'react-bootstrap';
import { ToastContainer } from 'react-toastify';

// Components
import NavigationBar from './components/NavigationBar';
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import Brokers from './components/Brokers';
import Strategies from './components/Strategies';
import Models from './components/Models';
import Backtests from './components/Backtests';
import LiveTrading from './components/LiveTrading';
import Settings from './components/Settings';

// Services
import { authService } from './services/authService';

// Styles
import 'bootstrap/dist/css/bootstrap.min.css';
import '@fortawesome/fontawesome-free/css/all.min.css';
import 'react-toastify/dist/ReactToastify.css';
import './App.css';

function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check if user is already logged in
    const token = localStorage.getItem('token');
    if (token) {
      authService.getCurrentUser()
        .then(userData => {
          setUser(userData);
        })
        .catch(() => {
          localStorage.removeItem('token');
        })
        .finally(() => {
          setLoading(false);
        });
    } else {
      setLoading(false);
    }
  }, []);

  const handleLogin = (userData) => {
    setUser(userData);
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    setUser(null);
  };

  if (loading) {
    return (
      <div className="d-flex justify-content-center align-items-center" style={{height: '100vh'}}>
        <div className="spinner-border" role="status">
          <span className="visually-hidden">Ładowanie...</span>
        </div>
      </div>
    );
  }

  return (
    <Router>
      <div className="App">
        {user ? (
          <>
            <NavigationBar user={user} onLogout={handleLogout} />
            <Container fluid className="mt-4">
              <Routes>
                <Route path="/" element={<Dashboard />} />
                <Route path="/brokers" element={<Brokers />} />
                <Route path="/strategies" element={<Strategies />} />
                <Route path="/models" element={<Models />} />
                <Route path="/backtests" element={<Backtests />} />
                <Route path="/live" element={<LiveTrading />} />
                <Route path="/settings" element={<Settings />} />
                <Route path="*" element={<Navigate to="/" replace />} />
              </Routes>
            </Container>
          </>
        ) : (
          <Routes>
            <Route path="/login" element={<Login onLogin={handleLogin} />} />
            <Route path="*" element={<Navigate to="/login" replace />} />
          </Routes>
        )}
        <ToastContainer
          position="top-right"
          autoClose={5000}
          hideProgressBar={false}
          newestOnTop={false}
          closeOnClick
          rtl={false}
          pauseOnFocusLoss
          draggable
          pauseOnHover
        />
      </div>
    </Router>
  );
}

export default App;