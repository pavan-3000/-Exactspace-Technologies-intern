from flask import Flask, jsonify
import json

app = Flask(__name__)

@app.route('/')
def serve_data():
    try:
        with open('scraped_data.json', 'r') as file:
            data = json.load(file)
        return jsonify(data)
    except FileNotFoundError:
        return jsonify({"error": "Scraped data not found. Run the scraper first."}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
