import serial
import typing

valid_keys = {"Acc", "EventAcc", "TotalAcc", "RInt"}
valid_units = {"mm", "mmph"}

class Rg15(serial.Serial):
    def __init__(self, dev: str):
        super().__init__(dev, timeout=3)

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
            values[key] = value
        return values