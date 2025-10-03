#!/usr/bin/env python3
"""
LEAN Trading Bot Stack - ML Runtime API
Obsługuje modele ONNX, TensorFlow i scikit-learn
"""

import os
import json
import logging
import traceback
from datetime import datetime
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import numpy as np

# ML Libraries
try:
    import onnxruntime as ort
except ImportError:
    ort = None

try:
    import tensorflow as tf
except ImportError:
    tf = None

try:
    import joblib
    from sklearn.base import BaseEstimator
except ImportError:
    joblib = None
    BaseEstimator = None

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global variables for loaded models
loaded_models = {}

class ModelManager:
    """Manager for loading and using different types of ML models"""
    
    def __init__(self):
        self.models = {}
        self.model_storage_path = os.getenv('MODEL_STORAGE_PATH', '/app/models')
        os.makedirs(self.model_storage_path, exist_ok=True)
    
    def load_onnx_model(self, model_path):
        """Load ONNX model"""
        if not ort:
            raise ImportError("ONNX Runtime is not installed")
        
        providers = ['CPUExecutionProvider']
        if os.getenv('ONNX_RUNTIME_PROVIDER') == 'CUDAExecutionProvider':
            providers = ['CUDAExecutionProvider', 'CPUExecutionProvider']
        
        session = ort.InferenceSession(model_path, providers=providers)
        return {
            'type': 'onnx',
            'session': session,
            'input_names': [inp.name for inp in session.get_inputs()],
            'output_names': [out.name for out in session.get_outputs()],
            'input_shapes': [inp.shape for inp in session.get_inputs()]
        }
    
    def load_tensorflow_model(self, model_path):
        """Load TensorFlow model"""
        if not tf:
            raise ImportError("TensorFlow is not installed")
        
        model = tf.keras.models.load_model(model_path)
        return {
            'type': 'tensorflow',
            'model': model,
            'input_shape': model.input_shape
        }
    
    def load_sklearn_model(self, model_path):
        """Load scikit-learn model"""
        if not joblib:
            raise ImportError("joblib is not installed")
        
        model = joblib.load(model_path)
        return {
            'type': 'sklearn',
            'model': model,
            'model_class': type(model).__name__
        }
    
    def load_model(self, model_id, model_path):
        """Load model based on file extension"""
        try:
            if model_path.endswith('.onnx'):
                model = self.load_onnx_model(model_path)
            elif model_path.endswith(('.h5', '.pb')):
                model = self.load_tensorflow_model(model_path)
            elif model_path.endswith(('.pkl', '.joblib')):
                model = self.load_sklearn_model(model_path)
            else:
                raise ValueError(f"Unsupported model format: {model_path}")
            
            model['loaded_at'] = datetime.now().isoformat()
            model['model_path'] = model_path
            self.models[model_id] = model
            
            logger.info(f"Model {model_id} loaded successfully: {model['type']}")
            return model
            
        except Exception as e:
            logger.error(f"Error loading model {model_id}: {e}")
            raise
    
    def predict(self, model_id, input_data):
        """Make prediction using loaded model"""
        if model_id not in self.models:
            raise ValueError(f"Model {model_id} not loaded")
        
        model_info = self.models[model_id]
        model_type = model_info['type']
        
        try:
            if model_type == 'onnx':
                session = model_info['session']
                input_name = model_info['input_names'][0]
                result = session.run(None, {input_name: input_data})
                return result[0]
            
            elif model_type == 'tensorflow':
                model = model_info['model']
                result = model.predict(input_data)
                return result
            
            elif model_type == 'sklearn':
                model = model_info['model']
                if hasattr(model, 'predict_proba'):
                    result = model.predict_proba(input_data)
                else:
                    result = model.predict(input_data)
                return result
            
            else:
                raise ValueError(f"Unknown model type: {model_type}")
                
        except Exception as e:
            logger.error(f"Prediction error for model {model_id}: {e}")
            raise

# Initialize model manager
model_manager = ModelManager()

# API Routes
@app.route('/health')
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'timestamp': datetime.now().isoformat(),
        'loaded_models': len(model_manager.models),
        'available_libraries': {
            'onnxruntime': ort is not None,
            'tensorflow': tf is not None,
            'scikit-learn': joblib is not None
        }
    })

@app.route('/models', methods=['GET'])
def list_models():
    """List all loaded models"""
    models_info = {}
    for model_id, model_info in model_manager.models.items():
        models_info[model_id] = {
            'type': model_info['type'],
            'loaded_at': model_info['loaded_at'],
            'model_path': model_info['model_path']
        }
        
        # Add type-specific info
        if model_info['type'] == 'onnx':
            models_info[model_id]['input_names'] = model_info['input_names']
            models_info[model_id]['output_names'] = model_info['output_names']
            models_info[model_id]['input_shapes'] = model_info['input_shapes']
        elif model_info['type'] == 'tensorflow':
            models_info[model_id]['input_shape'] = str(model_info['input_shape'])
        elif model_info['type'] == 'sklearn':
            models_info[model_id]['model_class'] = model_info['model_class']
    
    return jsonify({'models': models_info})

@app.route('/models/<model_id>/load', methods=['POST'])
def load_model(model_id):
    """Load a model from file"""
    data = request.get_json()
    
    if not data or 'model_path' not in data:
        return jsonify({'error': 'model_path is required'}), 400
    
    model_path = data['model_path']
    
    # Check if file exists
    full_path = os.path.join(model_manager.model_storage_path, model_path)
    if not os.path.exists(full_path):
        return jsonify({'error': f'Model file not found: {model_path}'}), 404
    
    try:
        model_info = model_manager.load_model(model_id, full_path)
        return jsonify({
            'message': f'Model {model_id} loaded successfully',
            'type': model_info['type']
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/models/<model_id>/predict', methods=['POST'])
def predict(model_id):
    """Make prediction using loaded model"""
    if model_id not in model_manager.models:
        return jsonify({'error': f'Model {model_id} not loaded'}), 404
    
    data = request.get_json()
    
    if not data or 'input' not in data:
        return jsonify({'error': 'input data is required'}), 400
    
    try:
        input_data = np.array(data['input'])
        
        # Make prediction
        prediction = model_manager.predict(model_id, input_data)
        
        # Convert numpy arrays to lists for JSON serialization
        if isinstance(prediction, np.ndarray):
            prediction = prediction.tolist()
        
        return jsonify({
            'model_id': model_id,
            'prediction': prediction,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Prediction error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/models/<model_id>/unload', methods=['POST'])
def unload_model(model_id):
    """Unload a model from memory"""
    if model_id in model_manager.models:
        del model_manager.models[model_id]
        return jsonify({'message': f'Model {model_id} unloaded successfully'})
    else:
        return jsonify({'error': f'Model {model_id} not found'}), 404

@app.route('/convert', methods=['POST'])
def convert_model():
    """Convert model between different formats"""
    data = request.get_json()
    
    required_fields = ['source_path', 'target_format']
    if not all(field in data for field in required_fields):
        return jsonify({'error': 'source_path and target_format are required'}), 400
    
    source_path = data['source_path']
    target_format = data['target_format']
    
    try:
        # Placeholder for model conversion logic
        # This would implement actual conversion between formats
        
        if target_format == 'onnx':
            # Convert to ONNX
            target_path = source_path.replace('.h5', '.onnx').replace('.pkl', '.onnx')
            # Actual conversion logic would go here
            
        elif target_format == 'tensorflow':
            # Convert to TensorFlow
            target_path = source_path.replace('.onnx', '.h5').replace('.pkl', '.h5')
            # Actual conversion logic would go here
            
        else:
            return jsonify({'error': f'Unsupported target format: {target_format}'}), 400
        
        return jsonify({
            'message': 'Model conversion completed',
            'source_path': source_path,
            'target_path': target_path,
            'target_format': target_format
        })
        
    except Exception as e:
        logger.error(f"Model conversion error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/analyze', methods=['POST'])
def analyze_data():
    """Analyze trading data using statistical methods"""
    data = request.get_json()
    
    if not data or 'data' not in data:
        return jsonify({'error': 'data is required'}), 400
    
    try:
        import pandas as pd
        
        # Convert to DataFrame
        df = pd.DataFrame(data['data'])
        
        # Basic statistical analysis
        analysis = {
            'shape': df.shape,
            'columns': df.columns.tolist(),
            'missing_values': df.isnull().sum().to_dict(),
            'basic_stats': df.describe().to_dict() if df.select_dtypes(include=[np.number]).shape[1] > 0 else {},
            'data_types': df.dtypes.astype(str).to_dict()
        }
        
        # Calculate correlations for numeric columns
        numeric_df = df.select_dtypes(include=[np.number])
        if numeric_df.shape[1] > 1:
            analysis['correlations'] = numeric_df.corr().to_dict()
        
        return jsonify({
            'analysis': analysis,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Data analysis error: {e}")
        return jsonify({'error': str(e)}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    port = int(os.getenv('ML_API_PORT', 5001))
    debug = os.getenv('ML_DEBUG', 'False').lower() == 'true'
    
    logger.info(f"Starting ML Runtime API on port {port}")
    logger.info(f"Available libraries: ONNX={ort is not None}, TensorFlow={tf is not None}, scikit-learn={joblib is not None}")
    
    app.run(
        host='0.0.0.0',
        port=port,
        debug=debug
    )