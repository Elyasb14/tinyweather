from http.server import HTTPServer, BaseHTTPRequestHandler
import threading
from typing import Dict

class Gauge:
    def __init__(self, name: str, help_text: str):
        self.name = name
        self.help_text = help_text
        self.value = 0.0
        self._lock = threading.Lock()
    
    def inc(self, amount: float = 1.0):
        with self._lock:
            self.value += amount
    
    def dec(self, amount: float = 1.0):
        with self._lock:
            self.value -= amount
    
    def set(self, value: float):
        with self._lock:
            self.value = value
    
    def get(self) -> float:
        with self._lock:
            return self.value
            
    def to_prometheus(self) -> str:
        return f"""# HELP {self.name} {self.help_text}
# TYPE {self.name} gauge
{self.name} {self.get()}"""

class MetricsHandler(BaseHTTPRequestHandler):
    gauges: Dict[str, Gauge] = {}
    
    def do_GET(self):
        if self.path == '/metrics':
            metrics = '\n\n'.join(gauge.to_prometheus() 
                                for gauge in self.gauges.values())
            
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            self.wfile.write(metrics.encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass  # Disable logging

def start_metrics_server(port: int = 8000):
    server = HTTPServer(('', port), MetricsHandler)
    thread = threading.Thread(target=server.serve_forever)
    thread.daemon = True
    thread.start()
    return server

# Example usage
if __name__ == "__main__":
    # Create a gauge
    temperature = Gauge("room_temperature_celsius", 
                       "Current room temperature in Celsius")
    
    # Register the gauge
    MetricsHandler.gauges["temperature"] = temperature
    
    # Start the metrics server
    server = start_metrics_server(8000)
    print("Metrics server started on port 8000")
    
    # Example of updating the gauge
    import time
    import random
    
    try:
        while True:
            # Simulate temperature changes
            temperature.set(round(random.uniform(20, 25), 1))
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.shutdown()
