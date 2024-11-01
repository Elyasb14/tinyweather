import serial
import sys

class Rg15(serial.Serial):
    def __init__(self, dev: str = '/dev/ttyUSB0') -> None:
        if sys.platform == "darwin": dev = "/dev/tty.usbserial-0001"
        super().__init__(dev, timeout=3)

    def reset_values(self): self.write(b"o\n")

    def set_mode(self, mode: str): 
      self.write(f"{mode}\n".encode())

    def get_data(self) -> str:
        self.write(b"r\n")
        return self.readline().decode().strip("\r\n")

    def parse_data(self) -> dict:
        groups = [group.strip().split(" ") for group in (' '.join(self.get_data().split())).split(",")]
        values = [group[1] for group in groups]
        keys = [group[0] for group in groups]
        return {value[0]: value[1] for value in zip(keys, values)}
        

if __name__ == "__main__":
    dev = Rg15()
    print(dev.get_data())
