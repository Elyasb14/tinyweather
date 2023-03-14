from sensors import Rg15
import argparse
import datetime

# adds cli flags
parser = argparse.ArgumentParser()
parser.add_argument("--device", default="/dev/tty.usbserial-0001", help="serial device to use")
args = parser.parse_args()

# timestamp method


sensor = Rg15(args.device)


def main():
    sensor.reset_values()
    print(sensor.get_data())
    print(sensor.save_data(sensor.parse_data()))

if __name__ == "__main__":
    main()
