import serial
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--device", default="/dev/ttyUSB0", help="serial device to use")
parser.add_argument("--baudrate", default=9600, type=int, help="baudrate to use")
args = parser.parse_args()

class Rg15:
    def __init__(self) -> None:
        self.device = serial.Serial(args.device, baudrate=args.baudrate)
        self.device.write(b"p\n")
        self.device.write(b"h\n")
        self.device.write(b"m\n")
        self.acc = 0.0
        self.eventacc = 0.0
        self.totalacc = 0.0
        self.mmph = 0.0 # millimeters per hour
    
    def get_data(self): return device.readline().decode()
    
    def parse_values(self, data: str):
        pass
        


class BME680:
    def __init__(self) -> None:
        pass