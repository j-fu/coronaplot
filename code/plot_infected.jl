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
    if countries[1]=="US"
        # For the US we sum up only the 52 state data, luckily they are stored
        # contiguously
        sum(convert(Array,crows[1:52,c_timeseries_start-shift:end]),dims=1)'
    else
        # For all other countries we sum up all the rows
        sum(convert(Array,crows[:,c_timeseries_start-shift:end]),dims=1)'
    end
end

# Plot data for countries
function plotcountries(df,
                       countries,
                       shifts,
                       kind;
                       label="", # label
                       lw=2, # plot line width
                       lt="-", # plot line type
                       delta=7, # average mask: delta days befor and after
                       )
    if label===""
        label=countries[1]
    end
    shift=shifts[label]
    
    # Add 1 to data for logkind plot
    if kind=="log"
        logkind_correction=1.0e-10
    else
        logkind_correction=0
    end

    # Create shifted time series
    if shift<=0
        # Shift timeseries to the left by cutting of the first `shift` entries
        reldays="days behind"
        data=create_countries_timeseries(df,countries,shift).+logkind_correction
        days=collect(0:length(data)-1)
    else
        # Shift timeseries to the right by increasing the entries in `days`
        reldays="days ahead"
        data=create_countries_timeseries(df,countries,0).+logkind_correction
        days=collect(shift:shift+length(data)-1)
    end
    # print for debugging purposes
    #println(data)
    println("$(label), $(maximum(data))")
    # if maximum(data)==1
    #     error("$(label) not found")
    # end

    # Add to plot
    if kind=="abs"
        plot(days,data,label="$(label) $(abs(shift)) $(reldays)",lt,linewidth=lw,markersize=6)
    end
    if kind=="log"
        semilogy(days,data,label="$(label) $(abs(shift)) $(reldays)",lt,linewidth=lw,markersize=6)
    end
    if kind=="growthrate"
        xshift=1
        if shift >0
            xshift=shift
        end
        grate0=data[2:end]./data[1:end-1]
        delta=delta
        grate=ones(length(grate0)-2*delta+xshift-1)
        j=xshift
        for i=1+delta:length(grate0)-delta
            fac=1.0/(1+2*delta)
            grate[j]=fac*grate0[i]
            for d=1:delta
                grate[j]+=fac*(grate0[i-d]+grate0[i+d])
            end
            j=j+1
        end
        grate.=(grate.-1).*100
        plot(grate[xshift:end],label="$(label) $(abs(shift)) $(reldays)",lt,linewidth=lw,markersize=6)
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
    trailer="\nData source: $(dataurl) $(Dates.today())\nData processing:https://github.com/j-fu/coronaplot"
    fig = PyPlot.figure(1)
    fig = PyPlot.gcf()
    fig.set_size_inches(10,5)

    shifts=Dict(
        "Italy" => 0,
        "France" => -7,
        "Spain" => -6,
        "Iran" => 0,
        "Korea, South" => 4,
        "China" => 40,
        "Switzerland" => -12,
        "Europe" => +3,
        "Germany" => -7,
        "US" => -9
    )
    
    # Plot absolute values to show exponential behavior
    clf()
    title("Corona Virus Development in countries with more than 3000 infections$(trailer)")
    plotcountries(rawdata,["Italy"],shifts,"abs")
    plotcountries(rawdata,["France"],shifts,"abs")
    plotcountries(rawdata,["Spain"],shifts,"abs")
    plotcountries(rawdata,["Iran"],shifts,"abs")
    plotcountries(rawdata,["Korea, South"],shifts,"abs")
    plotcountries(rawdata,["China"],shifts,"abs")
    plotcountries(rawdata,["Switzerland"],shifts,"abs")
    plotcountries(rawdata,Europe,label="Europe",shifts,"abs",lt="b-")
    plotcountries(rawdata,["Germany"],shifts,lw=3,lt="r-o","abs")
    plotcountries(rawdata,["US"],shifts,"abs",lt="k-")
    PyPlot.ylim(1,50_000)
    PyPlot.xlim(30,60)
    PyPlot.grid()
    PyPlot.xlabel("Days")
    PyPlot.ylabel("Infections")
    PyPlot.legend(loc="upper left")
    PyPlot.savefig("../docs/infected-exp.png")
    PyPlot.savefig("../infected-exp.png")

    # Log plot
    fig = PyPlot.figure(2)
    fig = PyPlot.gcf()
    fig.set_size_inches(10,5)
    clf()
    title("Corona Virus Development in countries with more than 3000 infections$(trailer)")
    plotcountries(rawdata,["Italy"],shifts,"log")
    plotcountries(rawdata,["France"],shifts,"log")
    plotcountries(rawdata,["Spain"],shifts,"log")
    plotcountries(rawdata,["Iran"],shifts,"log")
    plotcountries(rawdata,["Korea, South"],shifts,"log")
    plotcountries(rawdata,["China"],shifts,"log")
    plotcountries(rawdata,["Switzerland"],shifts,"log")
    plotcountries(rawdata,Europe,label="Europe",shifts,"log",lt="b-")
    plotcountries(rawdata,["Germany"],shifts,lw=3,lt="r-o","log")
    plotcountries(rawdata,["US"],shifts,"log",lt="k-")
    PyPlot.ylim(1000,100_000)
    PyPlot.xlim(20,100)
    PyPlot.grid()
    PyPlot.xlabel("Days")
    PyPlot.ylabel("Infections (logarithmic scale)")
    PyPlot.legend(loc="lower right")
    PyPlot.savefig("../docs/infected.png")
    PyPlot.savefig("../infected.png")

    # Plot absolute values to show exponential behavior
    fig = PyPlot.figure(3)
    fig = PyPlot.gcf()
    fig.set_size_inches(10,5)
    clf()
    title("15 day average of daily growth rate of COVID-19 infections in countries with >3000 infections$(trailer)")
    plotcountries(rawdata,["Italy"],shifts,"growthrate")
    plotcountries(rawdata,["France"],shifts,"growthrate")
    plotcountries(rawdata,["Spain"],shifts,"growthrate")
    plotcountries(rawdata,["Iran"],shifts,"growthrate")
    plotcountries(rawdata,["Korea, South"],shifts,"growthrate")
    plotcountries(rawdata,["China"],shifts,"growthrate")
    plotcountries(rawdata,["Switzerland"],shifts,"growthrate")
    plotcountries(rawdata,Europe,label="Europe",shifts,"growthrate",lt="b-")
    plotcountries(rawdata,["Germany"],shifts,lw=3,lt="r-o","growthrate")
    plotcountries(rawdata,["US"],shifts,"growthrate",lt="k-")
    PyPlot.ylim(0,120)
    PyPlot.xlim(15,50)
    PyPlot.grid()
    PyPlot.xlabel("Days")
    PyPlot.ylabel("Daily growth/%")
    PyPlot.legend(loc="upper right")
    PyPlot.savefig("../docs/infected-growthrate.png")
    PyPlot.savefig("../infected-growthrate.png")


end

# publish on github
function publish(;msg="data update")
    run(`git commit -a -m $(msg)`)
    run(`git push`)
end
