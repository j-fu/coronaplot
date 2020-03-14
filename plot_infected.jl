using PyPlot
using Dates
using CSV



# Number of column containing country name
c_country=2

# Number of start column of time series
c_timeseries_start=5

# Source file for data (for download)
datasource="https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv"

# Data URL (for data source in plot)
dataurl="https://github.com/CSSEGISandData/COVID-19/"

# Download and read data for confirmed infection cases
# This creates a dataframe
function read_download_infected()
    download(datasource,"infected.dat")
    CSV.read("infected.dat")
end

# Create a new dataframe wich contains only data for given countries
# For US and China, data are given state/province/county-wise
# For former colonial powers with overseas territories etc. there are multiple rows as well
function select_countries_rows(df,countries)
    clists=BitArray(undef,length(countries),size(df,1))
    for i=1:length(countries)
        clists[i,:].=df[:,c_country].==countries[i]
    end
    clist=vec(reduce(|,clists,dims=1))
    df[clist,:]
end

# Create shifted timeseries for each countries by cutting of the first `-shift` entries
function create_countries_timeseries(df,countries,shift)
    if shift>0
        error("positive shift not allowed here")
    end
    crows=select_countries_rows(df,countries)
    if countries===["US"]
        # For the US we sum up only the 52 state data, luckily they are stored
        # contiguously
        sum(convert(Array,crows[1:52,c_timeseries_start-shift:end]),dims=1)'
    else
        # For all other countries we sum up all the rows
        sum(convert(Array,crows[:,c_timeseries_start-shift:end]),dims=1)'
    end
end

# Plot data for countries
function plotcountries(df,countries;
                       label="", # label
                       shift=0, # time series shift
                       lw=2, # plot line width
                       lt="-", # plot line type
                       scale="log" # scaling of y axis: "log" or "abs"
                       )
    if label===""
        label=countries[1]
    end
    
    # Add 1 to data for logscale plot
    if scale=="log"
        logscale_correction=1.0e-10
    else
        logscale_correction=0
    end

    # Create shifted time series
    if shift<=0
        # Shift timeseries to the left by cutting of the first `shift` entries
        plus=""
        data=create_countries_timeseries(df,countries,shift).+logscale_correction
        days=collect(0:length(data)-1)
    else
        # Shift timeseries to the right by increasing the entries in `days`
        plus="+"
        data=create_countries_timeseries(df,countries,0).+logscale_correction
        days=collect(shift:shift+length(data)-1)
    end
    # print for debugging purposes
    #println(data)
    println("$(label), $(maximum(data))")
    # if maximum(data)==1
    #     error("$(label) not found")
    # end

    # Add to plot
    if scale=="abs"
        plot(days,data,label="$(label) $(plus)$(shift)",lt,linewidth=lw,markersize=6)
    else
        semilogy(days,data,label="$(label) $(plus)$(shift)",lt,linewidth=lw,markersize=6)
    end
    
end



# Create the plots
# use shift_multiplyer=0 to plot without shifts
function create_plots(;shift_multiplier=1)

    Europe=[
        "Austria",
        "Belgium",
        "Bulgaria",
        "Croatia",
        "Cyprus",
        "Czechia",
        "Denmark",
        "Estonia",
        "Finland",
        "France",
        "Germany",
        "Greece",
        "Hungary",
        "Ireland",
        "Italy",
        "Latvia",
        "Lithuania",
        "Luxembourg",
        "Malta",
        "Netherlands",
        "Poland",
        "Portugal",
        "Romania",
        "Slovakia",
        "Slovenia",
        "Spain",
        "Sweden",
        "Norway",
        "Switzerland",
        "United Kingdom",
    ]
    
    rawdata=read_download_infected()
    
    fig = PyPlot.figure(1)
    fig = PyPlot.gcf()
    fig.set_size_inches(10,5)

    # Plot absolute values to show exponential behavior
    clf()
    title("Comparison of Corona Virus Development\nData source: $(dataurl)\n$(Dates.now())")
    plotcountries(rawdata,["Italy"],shift=0*shift_multiplier,scale="abs")
    plotcountries(rawdata,["France"],shift=-9*shift_multiplier,scale="abs")
    plotcountries(rawdata,["Spain"],shift=-9*shift_multiplier,scale="abs")
    plotcountries(rawdata,["Iran"],shift=-3*shift_multiplier,scale="abs")
    plotcountries(rawdata,["Korea, South"],shift=4*shift_multiplier,scale="abs")
    plotcountries(rawdata,["China"],shift=35*shift_multiplier,scale="abs")
    plotcountries(rawdata,["Germany"],shift=-9*shift_multiplier,lw=3,lt="r-o",scale="abs")
#    plotcountries(rawdata,Europe,label="Europe",shift=2*shift_multiplier,scale="abs",lt="b-")
    plotcountries(rawdata,["US"],shift=-11*shift_multiplier,scale="abs",lt="k-")
    PyPlot.ylim(1,15_000)
    PyPlot.grid()
    PyPlot.xlabel("Days")
    PyPlot.ylabel("Infections")
    PyPlot.legend(loc="upper left")
    PyPlot.savefig("infected-exp.png")

    # Log plot
    fig = PyPlot.figure(2)
    fig = PyPlot.gcf()
    fig.set_size_inches(10,5)
    clf()
    title("Comparison of Corona Virus Development\nData source: $(dataurl)\n$(Dates.now())")
    plotcountries(rawdata,["Italy"],shift=0*shift_multiplier)
    plotcountries(rawdata,["France"],shift=-9*shift_multiplier)
    plotcountries(rawdata,["Spain"],shift=-9*shift_multiplier)
    plotcountries(rawdata,["Iran"],shift=-3*shift_multiplier)
    plotcountries(rawdata,["Korea, South"],shift=4*shift_multiplier)
    plotcountries(rawdata,["China"],shift=35*shift_multiplier)
    plotcountries(rawdata,["Germany"],shift=-9*shift_multiplier,lw=3,lt="r-o")
    plotcountries(rawdata,Europe,label="Europe",shift=2*shift_multiplier,lt="b-")
    plotcountries(rawdata,["US"],shift=-11*shift_multiplier,lt="k-")
    PyPlot.ylim(1,100_000)
    PyPlot.grid()
    PyPlot.xlabel("Days")
    PyPlot.ylabel("Infections (logarithmic scale)")
    PyPlot.legend(loc="upper left")
    PyPlot.savefig("infected.png")
end

# publish on github
function publish(;msg="data update")
    run(`git commit -a -m $(msg)`)
    run(`git push`)
end
