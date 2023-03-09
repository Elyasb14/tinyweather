from sensors import Rg15

rain_gauge = Rg15()
rain_data = rain_gauge.get_data()
print(rain_data)