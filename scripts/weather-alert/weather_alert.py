#!/usr/bin/env python3

import requests
import json
import logging
from datetime import datetime
from pathlib import Path

CONFIG_FILE = Path(__file__).parent / "config.json"
LOG_FILE = Path(__file__).parent / "weather_alert.log"


def load_config():
    try:
        with open(CONFIG_FILE) as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        logging.error(f"Invalid config.json: {e}")
        raise
    except FileNotFoundError:
        logging.error("Missing config.json")
        raise


def fetch_weather(api_key, location, units):
    url = "https://api.openweathermap.org/data/2.5/weather"
    params = {
            "q": location,
            "appid": api_key,
            "units": units
            }
    response = requests.get(url, params=params)
    response.raise_for_status()
    return response.json()

def check_alert_conditions(weather_data, keywords):
    description = weather_data['weather'][0]['description'].lower()
    for keyword in keywords:
        if keyword.lower() in description:
            return True, description
    return False, description

def send_alert(message):
    print(f"⚠️ {message}")
    # Desktop alert (Linux only)
    try:
        import subprocess
        subprocess.run(["notify-send", "Weather Alert", message], check=False)
    except Exception:
        pass
    logging.warning(message)

def setup_logging():
    logging.basicConfig(filename=LOG_FILE, level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s')


def main():
    setup_logging()
    config = load_config()
    try:
        weather_data = fetch_weather(
                config['api_key'], config['location'], config['units'])
        triggered, description = check_alert_conditions(
                weather_data, config['alert_keywords'])
        if triggered:
            send_alert(f"Severe weather detected: {description}")
        else:
            logging.info(f"Weather normal: {description}")
    except Exception as e:
        logging.error(f"Failed to check weather: {e}")


if __name__ == "__main__":
    main()
