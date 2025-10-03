import axios from 'axios';

// API Base URL
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000';

// Create axios instance
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle auth errors
api.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    if (error.response?.status === 401) {
      // Unauthorized - remove token and redirect to login
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export const apiService = {
  // Health check
  healthCheck: () => api.get('/api/health'),

  // Authentication
  login: (credentials) => api.post('/api/auth/login', credentials),
  getCurrentUser: () => api.get('/api/auth/me'),

  // Brokers
  getBrokers: () => api.get('/api/brokers'),
  addBroker: (brokerData) => api.post('/api/brokers', brokerData),
  updateBroker: (id, brokerData) => api.put(`/api/brokers/${id}`, brokerData),
  deleteBroker: (id) => api.delete(`/api/brokers/${id}`),
  testBrokerConnection: (id) => api.post(`/api/brokers/${id}/test`),

  // Strategies
  getStrategies: () => api.get('/api/strategies'),
  getStrategy: (id) => api.get(`/api/strategies/${id}`),
  createStrategy: (strategyData) => api.post('/api/strategies', strategyData),
  updateStrategy: (id, strategyData) => api.put(`/api/strategies/${id}`, strategyData),
  deleteStrategy: (id) => api.delete(`/api/strategies/${id}`),
  toggleStrategy: (id) => api.post(`/api/strategies/${id}/toggle`),

  // ML Models
  getMLModels: () => api.get('/api/models'),
  uploadMLModel: (formData) => api.post('/api/models/upload', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  }),
  deleteMLModel: (id) => api.delete(`/api/models/${id}`),
  testMLModel: (id, testData) => api.post(`/api/models/${id}/test`, testData),

  // Backtests
  getBacktests: () => api.get('/api/backtests'),
  getBacktest: (id) => api.get(`/api/backtests/${id}`),
  runBacktest: (backtestConfig) => api.post('/api/backtest', backtestConfig),
  deleteBacktest: (id) => api.delete(`/api/backtests/${id}`),

  // Live Trading
  startLiveTrading: (config) => api.post('/api/live/start', config),
  stopLiveTrading: (id) => api.post(`/api/live/${id}/stop`),
  getLiveStatus: () => api.get('/api/live/status'),
  getLiveTrades: () => api.get('/api/live/trades'),

  // Market Data
  getMarketData: (symbol) => api.get(`/api/market-data/${symbol}`),
  getHistoricalData: (symbol, timeframe, start, end) => 
    api.get(`/api/market-data/${symbol}/history`, {
      params: { timeframe, start, end }
    }),

  // System
  getSystemStatus: () => api.get('/api/system/status'),
  getLogs: (service, lines = 100) => api.get('/api/system/logs', {
    params: { service, lines }
  }),
  exportData: () => api.get('/api/system/export'),
  importData: (formData) => api.post('/api/system/import', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  }),
};

export default api;