# Hardware and Packaging

We really need to get serious about what the hardware aspect of this is going to look like. This doc will mainly focus on the node side of things, proxy will just be run on whatever servers I can get my hands on. 

Currently, the general idea is to use a raspberry pi zero 2w. After undergoing some tests, I found that this device is plenty fast, and only draws 1.3 watts at idle, spiking to 1.6 watts on occasion at 5V. Let's do some math:

- Current at 24V: 1.3W / 24V = 0.054A
- 24hr battery requirement: 0.054A × 24hrs = 1.3Ah
- With 85% DC-DC converter efficiency: 0.054A / 0.85 = 0.064A
- Final 24hr battery requirement: 0.064A × 24hrs = 1.536Ah at 24V

We probably want to get like a 5AH 24V battery. Now, how big of a solar panel do we want to get? ChatGPT gave me the following, seems reasonable

Daily energy consumption:
- 1.3W × 24 hours = 31.2 watt-hours per day
- Solar panel considerations:

Only about 4-6 hours of peak sunlight available per day (using 5 as average)
Need to account for inefficiencies in solar charging (roughly 75% efficiency)
Should add a 20-30% margin for cloudy days and system losses

Required solar panel capacity:
- 31.2Wh ÷ 5 hours ÷ 0.75 efficiency × 1.25 safety margin ≈ 10.4 watts

So we probably want 15 watts just to be safe. There might be higher power draw at some point.
