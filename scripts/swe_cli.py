import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os
import argparse
import time
from datetime import date
startTime = time.time()


today = date.today()
day = "-".join(["0" + str(today.month), str(today.day)])

print(day)

os.system("rm -r data/*")
os.system("rm -r plots/*")

parser = argparse.ArgumentParser(description="This program plots SWE for a given year and basin and comares it to the 91-20 mean")

parser.add_argument(
    "-b",
    "--basin",
    required=True,
    type=str,
    nargs='+',
    help="water basin",
)
parser.add_argument(
    "-y",
    "--year",
    type=str,
    required=False,
    nargs='+',
    help="which years would you like to plot?)",
)

# argument variables
args = parser.parse_args()
basins = pd.DataFrame(args.basin)
years = args.year

#saves csv for every basin chosen
basins[0].apply(lambda basin: pd.read_csv(f"https://www.nrcs.usda.gov/Internet/WCIS/AWS_PLOTS/basinCharts/POR/WTEQ/assocHUCor_8/{basin}.csv").to_csv(f"data/{basin}.csv"))
data_dir_len = len([f for f in os.listdir("data") if os.path.isfile(os.path.join("data", f))])

# plot algo
# creates plots/swe_plot_new.png
fig, axes = plt.subplots(nrows=len([f for f in os.listdir("data") if os.path.isfile(os.path.join("data", f))]), ncols=1, figsize = (5 * len([f for f in os.listdir("data") if os.path.isfile(os.path.join("data", f))]), 5 * len([f for f in os.listdir("data") if os.path.isfile(os.path.join("data", f))])))
for idx, ax in enumerate(fig.axes):
    df = pd.read_csv(f"data/{os.listdir('data')[idx]}")
    # axes[idx].plot(df.loc[:, "date"], get_average(f"data/{os.listdir('data')[idx]}"), label="Average('81-'22)")
    ax.plot(df.loc[:, "date"], df.loc[:, f"Median ('91-'20)"], label="Median ('91-'20)")
    ax.plot(df.loc[:, "date"], df.loc[:, f"{today.year}"], label=f"{today.year}")
    ax.plot(df.loc[:, "date"], df.loc[:, "Max"], label = "Max")
    ax.plot(df.loc[:, "date"], df.loc[:, "Median (POR)"], label = "Median (POR)")
    df.loc[df['date'] == day][str(today.year)]
    df.loc[df['date'] == day]["Median ('91-'20)"]
    try:
        # df.loc[df['date'] == day][str(today.year)]
        # df.loc[df['date'] == day]["Median ('91-'20)"]
        normal = ((df.loc[df['date'] == day][str(today.year)] / df.loc[df['date'] == day]["Median ('91-'20)"]) * 100).values
        print(normal[0])
    except KeyError:
        day = "-".join([str(today.month), str(today.day)])
        normal = ((df.loc[df['date'] == day][str(today.year)] / df.loc[df['date'] == day]["Median ('91-'20)"]) * 100).values
        print(f"{normal[0]}%")
    # might want a way to work around loop here for performance
    if not years:
        pass
    else:
        for year in years:
            try:
                df = pd.read_csv(f"data/{os.listdir('data')[idx]}")
                ax.plot(df.loc[:, "date"], df.loc[:, year], label = year)
            except KeyError:
                print(f"{year} is not a valid year")
            else:
                continue
    ax.set_xlabel('date')
    ax.set_xticks(np.arange(0, 365, 60))
    ax.set_ylabel('Snow Water Equivalent (in.)`')
    ax.set_title(f'{os.listdir("data")[idx]}'.strip(".csv"))
    ax.text("05-29", 35, f"PCT. Normal: {normal[0].round(2)}%", size="small")
    ax.legend()
    fig.savefig('plots/swe_plot.png')
    
# test execution time
executionTime = (time.time() - startTime)
print(f'Execution time in seconds: {executionTime}')

os.system("open plots/swe_plot.png")
