from sensors import Rg15, Bme280
import argparse
import datetime

# adds cli flags
parser = argparse.ArgumentParser()
parser.add_argument("--device", default="/dev/tty.usbserial-0001", help="serial device to use")
parser.add_argument("--reset", type=bool, help="reset all sensors that have the ability to be reset")
args = parser.parse_args()

# timestamp method


rain = Rg15(args.device)
env = Bme280()


def main():
    print(rain.get_data())
    print(rain.save_data(sensor.parse_data()))

if __name__ == "__main__":
    main()
