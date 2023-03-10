import serial
while True:
    device = serial.Serial("/dev/tty.usbserial-0001")
    device.write(b"o\n")
    data = device.write(b"r\n")
    print(device.readline())