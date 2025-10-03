import React, { useState } from 'react';
import { Container, Row, Col, Card, Form, Button, Alert } from 'react-bootstrap';
import { authService } from '../services/authService';

function Login({ onLogin }) {
  const [credentials, setCredentials] = useState({
    username: '',
    password: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleChange = (e) => {
    setCredentials({
      ...credentials,
      [e.target.name]: e.target.value
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const response = await authService.login(credentials);
      localStorage.setItem('token', response.data.token);
      onLogin(response.data.user);
    } catch (error) {
      setError(error.response?.data?.error || 'Błąd logowania');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Container className="login-container">
      <Row className="justify-content-center align-items-center min-vh-100">
        <Col md={6} lg={4}>
          <Card className="shadow">
            <Card.Body className="p-5">
              <div className="text-center mb-4">
                <i className="fas fa-robot fa-3x text-primary mb-3"></i>
                <h2>LEAN Trading Bot</h2>
                <p className="text-muted">Zaloguj się do panelu zarządzania</p>
              </div>

              {error && <Alert variant="danger">{error}</Alert>}

              <Form onSubmit={handleSubmit}>
                <Form.Group className="mb-3">
                  <Form.Label>
                    <i className="fas fa-user me-2"></i>
                    Nazwa użytkownika
                  </Form.Label>
                  <Form.Control
                    type="text"
                    name="username"
                    value={credentials.username}
                    onChange={handleChange}
                    placeholder="Wprowadź nazwę użytkownika"
                    required
                  />
                </Form.Group>

                <Form.Group className="mb-4">
                  <Form.Label>
                    <i className="fas fa-lock me-2"></i>
                    Hasło
                  </Form.Label>
                  <Form.Control
                    type="password"
                    name="password"
                    value={credentials.password}
                    onChange={handleChange}
                    placeholder="Wprowadź hasło"
                    required
                  />
                </Form.Group>

                <div className="d-grid">
                  <Button 
                    type="submit" 
                    variant="primary" 
                    size="lg"
                    disabled={loading}
                  >
                    {loading ? (
                      <>
                        <span className="spinner-border spinner-border-sm me-2" role="status"></span>
                        Logowanie...
                      </>
                    ) : (
                      <>
                        <i className="fas fa-sign-in-alt me-2"></i>
                        Zaloguj się
                      </>
                    )}
                  </Button>
                </div>
              </Form>

              <hr className="my-4" />
              
              <div className="text-center">
                <small className="text-muted">
                  Domyślne logowanie: <strong>admin</strong> / <strong>admin123</strong>
                  <br />
                  <span className="text-warning">
                    <i className="fas fa-exclamation-triangle me-1"></i>
                    Zmień hasło po pierwszym logowaniu!
                  </span>
                </small>
              </div>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
}

export default Login;