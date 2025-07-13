from flask import Flask, request, jsonify
import vertexai
from vertexai.preview.generative_models import GenerativeModel
import os

app = Flask(__name__)

# Initialize Vertex AI
vertexai.init(project="peregrine-465516", location="us-central1")

@app.route('/generate_workout', methods=['POST'])
def generate_workout():
    try:
        data = request.json
        user_prompt = data.get('prompt', '')
        model = GenerativeModel('gemini-1.5-pro')
        response = model.generate_content(user_prompt)
        return jsonify({'result': response.text})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080) 