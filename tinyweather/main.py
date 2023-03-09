from sensors import Rg15
import time
import argparse

# adds cli flags
parser = argparse.ArgumentParser()
parser.add_argument("--device", default="/dev/tty.usbserial-0001", help="serial device to use")
args = parser.parse_args()


def main():
    sensor = Rg15(args.device)
    data = sensor.parse_data()
    print(type(data))
    print(data)

if __name__ == "__main__":
    main()