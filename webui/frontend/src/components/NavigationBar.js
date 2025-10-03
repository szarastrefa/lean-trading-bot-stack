import React from 'react';
import { Navbar, Nav, NavDropdown, Container } from 'react-bootstrap';
import { LinkContainer } from 'react-router-bootstrap';

function NavigationBar({ user, onLogout }) {
  return (
    <Navbar bg="dark" variant="dark" expand="lg" className="shadow">
      <Container>
        <Navbar.Brand href="/">
          <i className="fas fa-robot me-2"></i>
          LEAN Trading Bot
        </Navbar.Brand>
        
        <Navbar.Toggle aria-controls="basic-navbar-nav" />
        
        <Navbar.Collapse id="basic-navbar-nav">
          <Nav className="me-auto">
            <LinkContainer to="/">
              <Nav.Link>
                <i className="fas fa-tachometer-alt me-1"></i>
                Dashboard
              </Nav.Link>
            </LinkContainer>
            
            <LinkContainer to="/strategies">
              <Nav.Link>
                <i className="fas fa-code me-1"></i>
                Strategie
              </Nav.Link>
            </LinkContainer>
            
            <LinkContainer to="/brokers">
              <Nav.Link>
                <i className="fas fa-building me-1"></i>
                Brokerzy
              </Nav.Link>
            </LinkContainer>
            
            <NavDropdown title={<><i className="fas fa-chart-bar me-1"></i>Trading</>} id="trading-dropdown">
              <LinkContainer to="/backtests">
                <NavDropdown.Item>
                  <i className="fas fa-history me-2"></i>
                  Backtesty
                </NavDropdown.Item>
              </LinkContainer>
              <LinkContainer to="/live">
                <NavDropdown.Item>
                  <i className="fas fa-play-circle me-2"></i>
                  Live Trading
                </NavDropdown.Item>
              </LinkContainer>
            </NavDropdown>
            
            <LinkContainer to="/models">
              <Nav.Link>
                <i className="fas fa-brain me-1"></i>
                Modele ML
              </Nav.Link>
            </LinkContainer>
          </Nav>
          
          <Nav>
            <NavDropdown 
              title={<><i className="fas fa-user me-1"></i>{user.username}</>} 
              id="user-dropdown"
              align="end"
            >
              <LinkContainer to="/settings">
                <NavDropdown.Item>
                  <i className="fas fa-cog me-2"></i>
                  Ustawienia
                </NavDropdown.Item>
              </LinkContainer>
              <NavDropdown.Divider />
              <NavDropdown.Item onClick={onLogout}>
                <i className="fas fa-sign-out-alt me-2"></i>
                Wyloguj
              </NavDropdown.Item>
            </NavDropdown>
          </Nav>
        </Navbar.Collapse>
      </Container>
    </Navbar>
  );
}

export default NavigationBar;