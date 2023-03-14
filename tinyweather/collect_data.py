from sensors import Rg15, Bme280
import argparse
import pandas as pd
import os

# adds cli flags
parser = argparse.ArgumentParser()
parser.add_argument("--device", default="/dev/tty.usbserial-0001", help="serial device to use")
parser.add_argument("--reset", type=bool, help="reset all sensors that have the ability to be reset")
parser.add_argument("--clean", type=bool, default=False, help="cleans data")

args = parser.parse_args()


# env = Bme280()
rain = Rg15(args.device)


def main():
    rain.save_data(rain.parse_data())
    # # env.parse_data()
    # time.sleep(1)
    # env.save_data(env.parse_data())

if __name__ == "__main__":
    main()
