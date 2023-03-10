from sensors import Rg15
import argparse

# adds cli flags
parser = argparse.ArgumentParser()
parser.add_argument("--device", default="/dev/tty.usbserial-0001", help="serial device to use")
args = parser.parse_args()

sensor = Rg15(args.device)

def main():
    print(sensor.parse_data())
    print("hello")
if __name__ == "__main__":
    main()
