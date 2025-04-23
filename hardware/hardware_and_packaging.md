# Hardware and Packaging

We really need to get serious about what the hardware aspect of this is going to look like. This doc will mainly focus on the node side of things, while the proxy will be run on whatever servers I can get my hands on.

Currently, the general idea is to use a Raspberry Pi Zero 2W. After undergoing some tests, I found that this device is plenty fast, drawing 1.3 watts at idle and occasionally spiking to 1.6 watts at 5V. Let's break down the power requirements:

### Power Calculations:
- **Current at 12V**: 1.3W / 12V = 0.108A
- **12hr battery requirement**: 0.108A × 24hrs = 2.592Ah
- **With 85% DC-DC converter efficiency**: 0.108A / 0.85 = 0.127A
- **Final 12hr battery requirement**: 0.127A × 24hrs = 3.048Ah at 12V

We’ll probably need a **10Ah 12V battery** to ensure we have enough power.

### Solar Panel Sizing:
- **Daily energy consumption**: 1.3W × 24hrs = 31.2 watt-hours per day
- **Solar panel considerations**: 4-6 hours of peak sunlight available per day (using 5 hours as average)
- **Account for inefficiencies**: roughly 75% efficiency in solar charging
- **Add margin for cloudy days**: 20-30% safety margin
- **Required solar panel capacity**: 31.2Wh ÷ 5hrs ÷ 0.75 efficiency × 1.25 safety margin ≈ 10.4 watts

We should likely go with a **15-watt solar panel** to be on the safe side, as power demands could increase at times.

So the solar controller will be something like [this](https://www.amazon.com/dp/B075NQH3QW?ref_=ppx_hzsearch_conn_dt_b_fed_asin_title_1). Inside the power distribution box we will have a fuse for the main solar and battery inputs. For the solar panels, we can probably use like a 2-3A fuse. For the battery we could use like a 1A fuse or something. Then we will use a 1A circuit breaker for the device itself. Also we need a 12v-5v voltage converter like [this](https://www.amazon.com/DROK-Converter-5-3V-32V-Regulator-Transformer/dp/B078Q1624B/ref=sr_1_3_pp?dib=eyJ2IjoiMSJ9.XY9uGiTaz5fdKvfbmGO5vkNmR-oPPXF2n8V6dS83RhXQFEimYVdrZf-ffny1bM8fysH1vl5iMyUm5JExsVD5oalPugkkDP-9UM0ByEaJmfUL3xzyTHUXFsQC8I89BpMMf6LlnGhDNcMlhLcChpvZcTQdobg2GRQtptzpCy1r7tnV1YTjDi27x80XoPcu2iAS5neloO5D5Ekt6Cap63kFIUJasKXI5_89huCgMlp4H3c.WilOZ2vwJ-dgDV9wT127ervuGGX6rgVOdWRB5s0JAEI&dib_tag=se&keywords=dc-dc%2Bconverter&qid=1745446732&sr=8-3&th=1) maybe 


