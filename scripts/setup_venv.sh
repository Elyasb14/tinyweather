#! /bin/bash

python3 -m venv .venv
source .venv/bin/activate
pip install adafruit-circuitpython-bme680 adafruit-blinka RPi.GPIO
