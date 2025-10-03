#!/usr/bin/env python3
"""
LEAN Trading Bot Stack - Flask Backend API
Autor: LEAN Trading Bot Stack Team
Licencja: Apache 2.0
"""

import os
import json
import logging
from datetime import datetime
from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import redis
import requests
from werkzeug.security import check_password_hash, generate_password_hash
from functools import wraps

# Inicjalizacja aplikacji
app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('FLASK_SECRET_KEY', 'dev-secret-key')
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', 'postgresql://postgres:password@localhost:5432/trading_bot')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Inicjalizacja rozszerzeń
CORS(app)
db = SQLAlchemy(app)
migrate = Migrate(app, db)

# Rate Limiting
limiter = Limiter(
    app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)

# Redis connection
redis_client = redis.Redis.from_url(
    os.getenv('REDIS_URL', 'redis://localhost:6379/0')
)

# Logging
logging.basicConfig(
    level=getattr(logging, os.getenv('LOG_LEVEL', 'INFO')),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Modele bazy danych
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    is_active = db.Column(db.Boolean, default=True)

class BrokerConnection(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    broker_name = db.Column(db.String(50), nullable=False)
    api_key_encrypted = db.Column(db.Text)
    is_active = db.Column(db.Boolean, default=True)
    environment = db.Column(db.String(20), default='demo')  # demo/live
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_used = db.Column(db.DateTime)

class TradingStrategy(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    code = db.Column(db.Text)
    parameters = db.Column(db.JSON)
    is_active = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow)

class MLModel(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    model_type = db.Column(db.String(50))  # onnx, tensorflow, sklearn
    file_path = db.Column(db.String(255))
    metadata = db.Column(db.JSON)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class BacktestResult(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    strategy_id = db.Column(db.Integer, db.ForeignKey('trading_strategy.id'), nullable=False)
    start_date = db.Column(db.DateTime)
    end_date = db.Column(db.DateTime)
    initial_capital = db.Column(db.Float)
    final_capital = db.Column(db.Float)
    total_return = db.Column(db.Float)
    sharpe_ratio = db.Column(db.Float)
    max_drawdown = db.Column(db.Float)
    results_json = db.Column(db.JSON)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# Utility functions
def require_auth(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'Authorization required'}), 401
        
        token = auth_header.split(' ')[1]
        user_id = redis_client.get(f'session:{token}')
        
        if not user_id:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        request.current_user_id = int(user_id)
        return f(*args, **kwargs)
    
    return decorated_function

# API Routes
@app.route('/api/health')
def health_check():
    """Health check endpoint"""
    try:
        # Test database
        db.session.execute('SELECT 1')
        db_status = 'ok'
    except:
        db_status = 'error'
    
    try:
        # Test Redis
        redis_client.ping()
        redis_status = 'ok'
    except:
        redis_status = 'error'
    
    return jsonify({
        'status': 'ok',
        'timestamp': datetime.utcnow().isoformat(),
        'services': {
            'database': db_status,
            'redis': redis_status,
            'version': '1.0.0'
        }
    })

@app.route('/api/auth/login', methods=['POST'])
@limiter.limit("5 per minute")
def login():
    """User authentication"""
    data = request.get_json()
    
    if not data or not data.get('username') or not data.get('password'):
        return jsonify({'error': 'Username and password required'}), 400
    
    user = User.query.filter_by(username=data['username']).first()
    
    if user and check_password_hash(user.password_hash, data['password']):
        # Create session token
        import uuid
        token = str(uuid.uuid4())
        redis_client.setex(f'session:{token}', 3600, user.id)  # 1 hour
        
        logger.info(f'User {user.username} logged in')
        
        return jsonify({
            'token': token,
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email
            }
        })
    
    logger.warning(f'Failed login attempt for {data["username"]}')
    return jsonify({'error': 'Invalid credentials'}), 401

@app.route('/api/brokers', methods=['GET'])
@require_auth
def get_brokers():
    """Get user's broker connections"""
    connections = BrokerConnection.query.filter_by(
        user_id=request.current_user_id,
        is_active=True
    ).all()
    
    return jsonify({
        'brokers': [{
            'id': conn.id,
            'broker_name': conn.broker_name,
            'environment': conn.environment,
            'last_used': conn.last_used.isoformat() if conn.last_used else None,
            'status': test_broker_connection(conn)
        } for conn in connections]
    })

@app.route('/api/brokers', methods=['POST'])
@require_auth
def add_broker():
    """Add new broker connection"""
    data = request.get_json()
    
    required_fields = ['broker_name', 'api_key', 'api_secret']
    if not all(field in data for field in required_fields):
        return jsonify({'error': 'Missing required fields'}), 400
    
    # Encrypt API keys (simplified - use proper encryption in production)
    from cryptography.fernet import Fernet
    key = os.getenv('ENCRYPTION_KEY', Fernet.generate_key()).encode()
    cipher = Fernet(key)
    
    encrypted_credentials = cipher.encrypt(json.dumps({
        'api_key': data['api_key'],
        'api_secret': data['api_secret'],
        'additional_params': data.get('additional_params', {})
    }).encode())
    
    connection = BrokerConnection(
        user_id=request.current_user_id,
        broker_name=data['broker_name'],
        api_key_encrypted=encrypted_credentials.decode(),
        environment=data.get('environment', 'demo')
    )
    
    db.session.add(connection)
    db.session.commit()
    
    logger.info(f'New broker connection added: {data["broker_name"]} for user {request.current_user_id}')
    
    return jsonify({
        'message': 'Broker connection added successfully',
        'id': connection.id
    })

@app.route('/api/strategies', methods=['GET'])
@require_auth
def get_strategies():
    """Get user's trading strategies"""
    strategies = TradingStrategy.query.filter_by(
        user_id=request.current_user_id
    ).all()
    
    return jsonify({
        'strategies': [{
            'id': strategy.id,
            'name': strategy.name,
            'is_active': strategy.is_active,
            'created_at': strategy.created_at.isoformat(),
            'updated_at': strategy.updated_at.isoformat()
        } for strategy in strategies]
    })

@app.route('/api/strategies', methods=['POST'])
@require_auth
def create_strategy():
    """Create new trading strategy"""
    data = request.get_json()
    
    if not data.get('name') or not data.get('code'):
        return jsonify({'error': 'Name and code are required'}), 400
    
    strategy = TradingStrategy(
        user_id=request.current_user_id,
        name=data['name'],
        code=data['code'],
        parameters=data.get('parameters', {})
    )
    
    db.session.add(strategy)
    db.session.commit()
    
    return jsonify({
        'message': 'Strategy created successfully',
        'id': strategy.id
    })

@app.route('/api/models', methods=['GET'])
@require_auth
def get_ml_models():
    """Get user's ML models"""
    models = MLModel.query.filter_by(
        user_id=request.current_user_id,
        is_active=True
    ).all()
    
    return jsonify({
        'models': [{
            'id': model.id,
            'name': model.name,
            'model_type': model.model_type,
            'metadata': model.metadata,
            'created_at': model.created_at.isoformat()
        } for model in models]
    })

@app.route('/api/models/upload', methods=['POST'])
@require_auth
def upload_ml_model():
    """Upload ML model file"""
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400
    
    # Validate file type
    allowed_extensions = {'.onnx', '.pkl', '.joblib', '.h5', '.pb'}
    if not any(file.filename.endswith(ext) for ext in allowed_extensions):
        return jsonify({'error': 'Invalid file type'}), 400
    
    # Save file
    import uuid
    filename = f"{uuid.uuid4()}_{file.filename}"
    filepath = os.path.join('models', filename)
    
    os.makedirs('models', exist_ok=True)
    file.save(filepath)
    
    # Determine model type
    model_type = 'unknown'
    if filename.endswith('.onnx'):
        model_type = 'onnx'
    elif filename.endswith(('.pkl', '.joblib')):
        model_type = 'sklearn'
    elif filename.endswith(('.h5', '.pb')):
        model_type = 'tensorflow'
    
    # Save to database
    model = MLModel(
        user_id=request.current_user_id,
        name=request.form.get('name', file.filename),
        model_type=model_type,
        file_path=filepath,
        metadata={
            'original_filename': file.filename,
            'file_size': os.path.getsize(filepath),
            'upload_date': datetime.utcnow().isoformat()
        }
    )
    
    db.session.add(model)
    db.session.commit()
    
    return jsonify({
        'message': 'Model uploaded successfully',
        'id': model.id,
        'model_type': model_type
    })

@app.route('/api/backtest', methods=['POST'])
@require_auth
def run_backtest():
    """Run backtest on strategy"""
    data = request.get_json()
    
    required_fields = ['strategy_id', 'start_date', 'end_date', 'initial_capital']
    if not all(field in data for field in required_fields):
        return jsonify({'error': 'Missing required fields'}), 400
    
    strategy = TradingStrategy.query.filter_by(
        id=data['strategy_id'],
        user_id=request.current_user_id
    ).first()
    
    if not strategy:
        return jsonify({'error': 'Strategy not found'}), 404
    
    # Simulate backtest (replace with actual LEAN integration)
    try:
        # This would integrate with LEAN engine
        backtest_config = {
            'algorithm-type-name': strategy.name,
            'algorithm-code': strategy.code,
            'start-date': data['start_date'],
            'end-date': data['end_date'],
            'cash': data['initial_capital']
        }
        
        # Mock results for now
        results = {
            'total_return': 0.15,  # 15%
            'sharpe_ratio': 1.2,
            'max_drawdown': -0.08,  # -8%
            'trades': 45,
            'winning_trades': 28,
            'losing_trades': 17
        }
        
        # Save results
        backtest_result = BacktestResult(
            strategy_id=strategy.id,
            start_date=datetime.fromisoformat(data['start_date']),
            end_date=datetime.fromisoformat(data['end_date']),
            initial_capital=data['initial_capital'],
            final_capital=data['initial_capital'] * (1 + results['total_return']),
            total_return=results['total_return'],
            sharpe_ratio=results['sharpe_ratio'],
            max_drawdown=results['max_drawdown'],
            results_json=results
        )
        
        db.session.add(backtest_result)
        db.session.commit()
        
        return jsonify({
            'message': 'Backtest completed successfully',
            'result_id': backtest_result.id,
            'results': results
        })
        
    except Exception as e:
        logger.error(f'Backtest error: {e}')
        return jsonify({'error': 'Backtest failed'}), 500

@app.route('/api/live/start', methods=['POST'])
@require_auth
def start_live_trading():
    """Start live trading with strategy"""
    data = request.get_json()
    
    if not data.get('strategy_id') or not data.get('broker_id'):
        return jsonify({'error': 'Strategy ID and Broker ID required'}), 400
    
    strategy = TradingStrategy.query.filter_by(
        id=data['strategy_id'],
        user_id=request.current_user_id
    ).first()
    
    broker = BrokerConnection.query.filter_by(
        id=data['broker_id'],
        user_id=request.current_user_id
    ).first()
    
    if not strategy or not broker:
        return jsonify({'error': 'Strategy or broker not found'}), 404
    
    # This would integrate with LEAN engine for live trading
    logger.info(f'Starting live trading: strategy {strategy.id}, broker {broker.broker_name}')
    
    return jsonify({
        'message': 'Live trading started successfully',
        'strategy_name': strategy.name,
        'broker_name': broker.broker_name
    })

@app.route('/api/market-data/<symbol>')
@limiter.limit("30 per minute")
def get_market_data(symbol):
    """Get real-time market data"""
    # Mock market data - replace with real data feed
    import random
    
    price = round(random.uniform(100, 200), 2)
    change = round(random.uniform(-5, 5), 2)
    
    return jsonify({
        'symbol': symbol.upper(),
        'price': price,
        'change': change,
        'change_percent': round(change / price * 100, 2),
        'timestamp': datetime.utcnow().isoformat()
    })

def test_broker_connection(connection):
    """Test broker API connection"""
    try:
        # This would test actual broker connection
        # For now, return mock status
        return 'connected' if connection.is_active else 'disconnected'
    except:
        return 'error'

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return jsonify({'error': 'Internal server error'}), 500

@app.errorhandler(429)
def rate_limit_exceeded(error):
    return jsonify({'error': 'Rate limit exceeded'}), 429

# Database initialization
@app.before_first_request
def create_tables():
    db.create_all()
    
    # Create default admin user if doesn't exist
    admin = User.query.filter_by(username='admin').first()
    if not admin:
        admin = User(
            username='admin',
            email='admin@localhost',
            password_hash=generate_password_hash('admin123')  # Change in production!
        )
        db.session.add(admin)
        db.session.commit()
        logger.info('Default admin user created')

if __name__ == '__main__':
    port = int(os.getenv('API_PORT', 5000))
    debug = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    
    app.run(
        host='0.0.0.0',
        port=port,
        debug=debug
    )