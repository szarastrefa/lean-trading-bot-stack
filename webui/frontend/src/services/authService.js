import api from './apiService';

export const authService = {
  login: async (credentials) => {
    const response = await api.post('/api/auth/login', credentials);
    return response;
  },

  logout: () => {
    localStorage.removeItem('token');
    window.location.href = '/login';
  },

  getCurrentUser: async () => {
    const response = await api.get('/api/auth/me');
    return response.data;
  },

  isAuthenticated: () => {
    return localStorage.getItem('token') !== null;
  },

  getToken: () => {
    return localStorage.getItem('token');
  }
};