import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Table, Badge } from 'react-bootstrap';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { apiService } from '../services/apiService';
import { toast } from 'react-toastify';

function Dashboard() {
  const [stats, setStats] = useState({
    totalReturn: 0,
    activeStrategies: 0,
    connectedBrokers: 0,
    backtests: 0
  });
  const [recentActivity, setRecentActivity] = useState([]);
  const [performanceData, setPerformanceData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
    
    // Refresh data every 30 seconds
    const interval = setInterval(loadDashboardData, 30000);
    return () => clearInterval(interval);
  }, []);

  const loadDashboardData = async () => {
    try {
      // Load various dashboard data
      const [brokersResponse, strategiesResponse, backtestsResponse] = await Promise.all([
        apiService.getBrokers(),
        apiService.getStrategies(),
        apiService.getBacktests()
      ]);

      // Calculate stats
      const connectedBrokers = brokersResponse.data.brokers?.filter(b => b.status === 'connected').length || 0;
      const activeStrategies = strategiesResponse.data.strategies?.filter(s => s.is_active).length || 0;
      const totalBacktests = backtestsResponse.data.backtests?.length || 0;

      setStats({
        totalReturn: 15.5, // Mock data - replace with real calculation
        activeStrategies,
        connectedBrokers,
        backtests: totalBacktests
      });

      // Mock performance data
      const mockPerformanceData = [
        { date: '2024-01', value: 10000 },
        { date: '2024-02', value: 10500 },
        { date: '2024-03', value: 10200 },
        { date: '2024-04', value: 11000 },
        { date: '2024-05', value: 11500 },
        { date: '2024-06', value: 11200 }
      ];
      setPerformanceData(mockPerformanceData);

      // Mock recent activity
      setRecentActivity([
        { id: 1, action: 'Backtest ukończony', strategy: 'Mean Reversion BTC', time: '2 min temu', status: 'success' },
        { id: 2, action: 'Nowe połączenie', broker: 'Binance', time: '15 min temu', status: 'info' },
        { id: 3, action: 'Strategia zatrzymana', strategy: 'Trend Following EUR/USD', time: '1 godz temu', status: 'warning' },
        { id: 4, action: 'Model ML wczytany', model: 'LSTM Price Predictor', time: '2 godz temu', status: 'success' }
      ]);

    } catch (error) {
      console.error('Error loading dashboard data:', error);
      toast.error('Błąd ładowania danych dashboard');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="d-flex justify-content-center">
        <div className="spinner-border" role="status">
          <span className="visually-hidden">Ładowanie...</span>
        </div>
      </div>
    );
  }

  return (
    <div>
      <h2 className="mb-4">
        <i className="fas fa-tachometer-alt me-2"></i>
        Dashboard
      </h2>

      {/* Statistics Cards */}
      <Row className="mb-4">
        <Col md={3}>
          <Card className="text-center">
            <Card.Body>
              <h3 className="text-success">{stats.totalReturn}%</h3>
              <p className="text-muted mb-0">Łączny zwrot</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center">
            <Card.Body>
              <h3 className="text-primary">{stats.activeStrategies}</h3>
              <p className="text-muted mb-0">Aktywne strategie</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center">
            <Card.Body>
              <h3 className="text-info">{stats.connectedBrokers}</h3>
              <p className="text-muted mb-0">Połączone brokerzy</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center">
            <Card.Body>
              <h3 className="text-warning">{stats.backtests}</h3>
              <p className="text-muted mb-0">Backtesty</p>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      <Row>
        {/* Performance Chart */}
        <Col lg={8}>
          <Card className="mb-4">
            <Card.Header>
              <h5 className="mb-0">
                <i className="fas fa-chart-line me-2"></i>
                Wydajność Portfolio
              </h5>
            </Card.Header>
            <Card.Body>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={performanceData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip 
                    formatter={(value) => [`$${value.toLocaleString()}`, 'Wartość']}
                    labelFormatter={(label) => `Data: ${label}`}
                  />
                  <Line 
                    type="monotone" 
                    dataKey="value" 
                    stroke="#0d6efd" 
                    strokeWidth={2}
                    dot={{ fill: '#0d6efd', strokeWidth: 2, r: 4 }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </Card.Body>
          </Card>
        </Col>

        {/* Recent Activity */}
        <Col lg={4}>
          <Card>
            <Card.Header>
              <h5 className="mb-0">
                <i className="fas fa-clock me-2"></i>
                Ostatnia aktywność
              </h5>
            </Card.Header>
            <Card.Body style={{maxHeight: '300px', overflowY: 'auto'}}>
              {recentActivity.length > 0 ? (
                <div>
                  {recentActivity.map((activity) => (
                    <div key={activity.id} className="d-flex justify-content-between align-items-center mb-3 pb-2 border-bottom">
                      <div>
                        <div className="fw-bold">{activity.action}</div>
                        <small className="text-muted">
                          {activity.strategy && `Strategia: ${activity.strategy}`}
                          {activity.broker && `Broker: ${activity.broker}`}
                          {activity.model && `Model: ${activity.model}`}
                        </small>
                      </div>
                      <div className="text-end">
                        <Badge bg={activity.status === 'success' ? 'success' : 
                                  activity.status === 'warning' ? 'warning' : 
                                  activity.status === 'error' ? 'danger' : 'info'}>
                          {activity.status}
                        </Badge>
                        <div><small className="text-muted">{activity.time}</small></div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-muted text-center">Brak ostatniej aktywności</p>
              )}
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Quick Actions */}
      <Row className="mt-4">
        <Col>
          <Card>
            <Card.Header>
              <h5 className="mb-0">
                <i className="fas fa-bolt me-2"></i>
                Szybkie akcje
              </h5>
            </Card.Header>
            <Card.Body>
              <Row>
                <Col md={3}>
                  <div className="d-grid">
                    <button className="btn btn-primary" onClick={() => window.location.href = '/strategies'}>
                      <i className="fas fa-plus me-2"></i>
                      Nowa strategia
                    </button>
                  </div>
                </Col>
                <Col md={3}>
                  <div className="d-grid">
                    <button className="btn btn-success" onClick={() => window.location.href = '/backtests'}>
                      <i className="fas fa-play me-2"></i>
                      Uruchom backtest
                    </button>
                  </div>
                </Col>
                <Col md={3}>
                  <div className="d-grid">
                    <button className="btn btn-info" onClick={() => window.location.href = '/brokers'}>
                      <i className="fas fa-link me-2"></i>
                      Dodaj brokera
                    </button>
                  </div>
                </Col>
                <Col md={3}>
                  <div className="d-grid">
                    <button className="btn btn-warning" onClick={() => window.location.href = '/models'}>
                      <i className="fas fa-brain me-2"></i>
                      Upload modelu ML
                    </button>
                  </div>
                </Col>
              </Row>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </div>
  );
}

export default Dashboard;