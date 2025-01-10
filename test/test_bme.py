import board
import adafruit_bme680

i2c = board.I2C()
sensor = adafruit_bme680.Adafruit_BME680_I2C(i2c)
print(sensor.temperature, sensor.pressure, sensor.humidity, sensor.gas)
