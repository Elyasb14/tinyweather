# ***tinyweather***

Tinyweather is a python library for interfacing with environmental sensors and analyzing the data received. Right now we support the [RG-15 rain gauge](https://rainsensors.com/products/rg-15/) and the [Bosch BME680](https://www.adafruit.com/product/3660). We will add many more. In the future, we will have predictive models.

## ***Installation***

```bash
pip install tinyweather
```

## ***Rain Gauge Example***

```python
from sensors import Rg15

sensor = Rg15(args.device)

print(sensor.get_data())
print(sensor.parse_data())
```

```bash
Acc  0.00 mm, EventAcc  0.58 mm, TotalAcc  0.58 mm, RInt  0.00 mmph

{'Acc (mm)': 0.0, 'EventAcc (mm)': 0.58, 'TotalAcc (mm)': 0.58, 'RInt (mm)': 0.0}
```

## ***BME680***

## ***Future Additions***

- We might use a raspi pico w to serve a basic webpage,   not sure on that quite yet, but seems like a cool idea
- 