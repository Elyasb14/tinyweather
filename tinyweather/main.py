from sensors import Rg15
import time

rain_gauge = Rg15()
rain_data = rain_gauge.get_data(self=rain_gauge)
for i in range(20):
    time.sleep(1)
    print(rain_data)