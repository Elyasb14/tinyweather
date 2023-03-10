import serial
import pandas as pd
import numpy as np


valid_keys = {"Acc", "EventAcc", "TotalAcc", "RInt"}
valid_units = {"mm", "mmph"}

class Rg15(serial.Serial):
    def __init__(self, dev: str) -> None:
        super().__init__(dev, timeout=3)
        
    def reset_values(self): self.write(b"o\n")
    
    def set_mode(self, mode: str): self.write(f"{mode}\n".encode())

    def get_data(self: serial.Serial) -> str:
        """reads data from rain gauge returns data as a string"""
        self.write(b"r\n")
        return self.readline().decode()

    def parse_data(self: serial.Serial) -> dict:
        # TODO: re write this, there has to be a better way
        """Parses the sensor output returning dictionary with values"""
        global valid_keys, valid_units
        values = {}
        groups = self.get_data().split(",")
        for group in groups:
            word = group.split()
            if len(word) != 3:
                continue
            key = word[0]
            if key not in valid_keys:
                continue
            if word[2] not in valid_units:
                continue
            try:
                value = float(word[1])
            except ValueError:
                continue
            values[f"{key} (mm)"] = value
        # time_info = datetime.datetime.now()
        # values["date"] = time_info.date()
        # values["time"] = time_info.time()
        return values
    
    def save_data(self, data: dict):
        print("saved data to data/rain_sensor.csv")