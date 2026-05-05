# backend/app.py

from flask import Flask, request, jsonify
from flask_cors import CORS
import yfinance as yf
import openai
from dotenv import load_dotenv
import os

load_dotenv()

app = Flask(__name__)
CORS(app)  # This allows your Flutter app to talk to this backend

openai.api_key = os.getenv("DEEPSEEK_API_KEY")
# DeepSeek uses OpenAI-compatible API, so we set the base URL
openai.base_url = "https://api.deepseek.com/"

def calculate_indicators(data):
    """Calculates RSI, SMA, etc. from a list of stock data."""
    closes = [item['Close'] for item in data]
    
    # Simple Moving Averages
    sma_20 = sum(closes[-20:]) / 20 if len(closes) >= 20 else None
    sma_50 = sum(closes[-50:]) / 50 if len(closes) >= 50 else None

    # Calculate RSI (14-day)
    rsi = None
    if len(closes) >= 15:
        gains, losses = [], []
        for i in range(1, 15):
            diff = closes[-i] - closes[-i-1]
            if diff > 0:
                gains.append(diff)
            else:
                losses.append(abs(diff))
        avg_gain = sum(gains) / 14 if gains else 0
        avg_loss = sum(losses) / 14 if losses else 0
        if avg_loss == 0:
            rsi = 100
        else:
            rs = avg_gain / avg_loss
            rsi = 100 - (100 / (1 + rs))

    return {
        "current_price": closes[-1],
        "sma_20": sma_20,
        "sma_50": sma_50,
        "rsi": rsi,
    }

@app.route('/analyze', methods=['GET'])
def analyze_stock():
    symbol = request.args.get('symbol', '').upper()
    if not symbol:
        return jsonify({"error": "Please provide a stock symbol"}), 400

    try:
        # 1. Fetch data from Yahoo Finance
        ticker = yf.Ticker(symbol)
        hist = ticker.history(period="3mo")
        
        if hist.empty:
            return jsonify({"error": f"No data found for symbol '{symbol}'"}), 404

        # Convert the historical data to a list of dictionaries
        data = hist[['Open', 'High', 'Low', 'Close', 'Volume']].reset_index().to_dict(orient='records')
        for point in data:
            point['Date'] = point['Date'].isoformat()

        # 2. Calculate technical indicators
        indicators = calculate_indicators(data)

        # 3. Get analysis from DeepSeek AI
        prompt = f"""
        Analyze the stock {symbol}. 
        Current Price: ${indicators['current_price']:.2f}
        20-Day SMA: ${indicators['sma_20']:.2f}
        50-Day SMA: ${indicators['sma_50']:.2f}
        14-Day RSI: {indicators['rsi']:.2f}

        Provide a very brief analysis and a recommendation (Buy/Sell/Hold).
        """
        
        response = openai.chat.completions.create(
            model="deepseek-chat",
            messages=[
                {"role": "system", "content": "You are a helpful stock market analyst. Keep answers concise."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.5,
        )
        ai_analysis = response.choices[0].message.content

        # 4. Send everything back to the Flutter app
        return jsonify({
            "symbol": symbol,
            "data": data,
            "indicators": indicators,
            "analysis": ai_analysis,
        })

    except Exception as e:
        return jsonify({"error": f"An internal error occurred: {str(e)}"}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000)