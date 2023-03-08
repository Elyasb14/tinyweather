import serial
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--device", "-d", default="/dev/ttyUSB0", help="serial device to use")
parser.add_argument("--baudrate", "-b", default=9600, type=int, help="baudrate to use")
args = parser.parse_args()

class Rg15:
    def __init__(self) -> None:
        self.temp = "20c"
        self.rain = "40in"
        # self.device = serial.Serial(args.device, baudrate=args.baudrate)
        # line format
        # Acc  0.00 mm, EventAcc  0.00 mm, TotalAcc  1.11 mm, RInt  0.00 mmph
        # TODO:
        #   -add self.acc (mm)
        #   -add self.eventacc (mm)
        #   -add self.totalacc (mm)
        #   -add self.rint(mmph)

    def get_values(self):
        # print(self.device)
        print(self.temp)
    
    def parse_values(self):
        print(self.rain)
        print(self.rain + "hi")


class BME680:
    def __init__(self) -> None:
        pass