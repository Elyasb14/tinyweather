from sensors import Rg15
import time
import argparse

# adds cli flags
parser = argparse.ArgumentParser()
parser.add_argument("--device", default="/dev/tty.usbserial-0001", help="serial device to use")
args = parser.parse_args()

sensor = Rg15(args.device)

def main():
    sensor.save_data(sensor.parse_data())
    
if __name__ == "__main__":
    main()