import serial
import datetime
# from smbus import SMBus
# import bme280

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
    
    def save_data(self, data: dict) -> dict: 
        """saves data to a csv with timestamp"""
        def get_timestamp() -> dict:
            x = datetime.datetime.now()
            keys = ["date", "time"]
            values = x.strftime("%m/%d/%Y, %H:%M:%S").replace(",", "").split(" ")
            return {value[0]: value[1] for value in zip(keys, values)}
        timestamp = get_timestamp()
        return timestamp | data

        

    
# class Bme280(bme280.BME280):
#     def __init__(self) -> None:
#         super().__init__()
    
#     def parse_data(self): return {"temp": self.get_temperature(), "pressure": self.get_pressure(), "hummidity": self.get_humidity()}
    
#     def altitude(self): return self.get_altitude()