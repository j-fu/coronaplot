using PyPlot
using Dates
using CSV
using Printf


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
    countries_mask=BitArray(undef,length(countries),size(df,1))
    for i=1:length(countries)
        countries_mask[i,:].=df[:,c_country].==countries[i]
    end
    mask=vec(reduce(|,countries_mask,dims=1))
    df[mask,:]
end

# Create timeseries for list of countries
function create_countries_timeseries(df,countries)
    crows=select_countries_rows(df,countries)
    if countries[1]=="US"
        # For the US we sum up only the 52 state data, luckily they are stored
        # contiguously
        data=sum(convert(Array,crows[1:52,c_timeseries_start:end]),dims=1)'
    else
        # For all other countries we sum up all the rows
        data=sum(convert(Array,crows[:,c_timeseries_start:end]),dims=1)'
    end
    data=convert(Vector{Float64},vec(data))
end

# Calculate growth factor from growth rate (in %)
growth_factor(growth_rate)=growth_rate/100.0+1

# Calculate doubling time from growth factor
doubling_time(gfactor)= log(2.0)/log(gfactor)

# Calculate growth rate (in %) from growth factor
growth_rate(gfactor)=(gfactor-1)*100

# Plot data for countries
function plotcountries(df,  
                       countries,  # Array of countries
                       kind;       # Kind of plot  
                       country="", # label
                       lw=2,       # plot line width
                       lt="-",     # plot line type
                       averaging_period=15,   # averaging period: averaging_period days
                       Nstart=500  # starting data for shifting curves
                       )

    # If country name is not given, take the first name from the array
    if country===""
        country=countries[1]
    end
    
    # Add 1 to data for allowing to  logarithm or division
    if kind=="log"
        logdiv_regularization=1.0e-10
    elseif  kind=="growthrate"
        logdiv_regularization=1.0
    else
        logdiv_regularization=0.0
    end

    # Create shifted time series

    # Shift timeseries to the left cutting of the days until Nstart infections occur
    basedata=create_countries_timeseries(df,countries).+logdiv_regularization
    shift=1
    while basedata[shift]<Nstart
        shift=shift+1
    end
    data=basedata[shift:end]
    days=collect(0:length(data)-1)
    # print for control purposes (to verify  with the numbers given in the map app)
    println("$(country), $(maximum(data))")

    # Perform plots
    if kind=="abs"
        plot(days,data,label="$(country)",lt,linewidth=lw,markersize=6)
    end
    
    if kind=="log"
        semilogy(days,data,label="$(country)",lt,linewidth=lw,markersize=6)
    end

    if kind=="growthrate"
        # Calculat daily growth factors
        gfactors=basedata[2:end]./basedata[1:end-1]

        # Calculate the average over averaging_period
        averaged_gfactors=ones(length(gfactors)-averaging_period)
        j=1
        for i=averaging_period+1:length(gfactors)
            for d=1:averaging_period
                averaged_gfactors[j]*=gfactors[i-d+1]
            end
            averaged_gfactors[j]=averaged_gfactors[j]^(1.0/averaging_period)
            j=j+1
        end

        # Calculate growh rates
        grates=growth_rate.(averaged_gfactors)

        # Adjust starting day due to change of reporting on US data
        day0=1
        if country=="US"
            day0=34
        end
        # Plot
        plot(day0:length(grates),grates[day0:end],label="$(country)",lt,linewidth=lw,markersize=6)
    end
end



# Create the plots
function create_plots(;averaging_period=15,Nstart=500)

    # List of countries belonging to Europa
    # (omitting those with less than 100 cases)
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
        "Serbia"
    ]
    
    rawdata=read_download_infected()


    trailer="\nData source: $(dataurl) $(Dates.today())\nData processing: https://github.com/j-fu/coronaplot"

    # Plot absolute values (linear Y scale) to show exponential behavior
    fig = PyPlot.figure(1)
    fig = PyPlot.gcf()
    fig.set_size_inches(10,5)
    clf()
    title("Corona Virus Development in countries with more than 3000 infections$(trailer)")
    plotcountries(rawdata,["Italy"],"abs",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["France"],"abs",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Spain"],"abs",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Iran"],"abs",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Korea, South"],"abs",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["China"],"abs",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Switzerland"],"abs",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Netherlands"],"abs",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,Europe,country="Europe","abs",lt="b-",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Germany"],lw=3,lt="r-o","abs",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["US"],"abs",lt="k-",averaging_period=averaging_period,Nstart=Nstart)
    PyPlot.ylim(1,80_000)
    PyPlot.xlim(0,30)
    PyPlot.grid()
    PyPlot.xlabel("Days since occurence of at least $(Nstart) infections")
    PyPlot.ylabel("Number of infections (linear scale)")
    PyPlot.legend(loc="upper left")
    PyPlot.savefig("../docs/infected-exp.png")
    PyPlot.savefig("../infected-exp.png")

    # Log plot
    fig = PyPlot.figure(2)
    fig = PyPlot.gcf()
    fig.set_size_inches(10,5)
    clf()
    title("Corona Virus Development in countries with more than 3000 infections$(trailer)")
    plotcountries(rawdata,["Italy"],"log",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["France"],"log",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Spain"],"log",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Iran"],"log",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Korea, South"],"log",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["China"],"log",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Switzerland"],"log",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Netherlands"],"log",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,Europe,country="Europe","log",lt="b-",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Germany"],lw=3,lt="r-o","log",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["US"],"log",lt="k-",averaging_period=averaging_period,Nstart=Nstart)
    PyPlot.xlim(0,40)
    PyPlot.grid()
    PyPlot.xlabel("Days since occurence of at least $(Nstart) infections")
    PyPlot.ylabel("Number of infections (logarithmic scale)")
    PyPlot.legend(loc="lower right")
    PyPlot.savefig("../docs/infected.png")
    PyPlot.savefig("../infected.png")

    # Plot evolution of growth rate average
    fig = PyPlot.figure(3)
    fig = PyPlot.gcf()
    fig.set_size_inches(10,5)
    clf()
    title("$(averaging_period) day average of daily growth rate of COVID-19 infections in countries with >3000 infections$(trailer)")
    plotcountries(rawdata,["Italy"],"growthrate",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["France"],"growthrate",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Spain"],"growthrate",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Iran"],"growthrate",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Korea, South"],"growthrate",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["China"],"growthrate",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Switzerland"],"growthrate",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Netherlands"],"growthrate",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,Europe,country="Europe","growthrate",lt="b-",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["Germany"],lw=3,lt="r-o","growthrate",averaging_period=averaging_period,Nstart=Nstart)
    plotcountries(rawdata,["US"],"growthrate",lt="k-",averaging_period=averaging_period,Nstart=Nstart)

    PyPlot.ylim(0,80)
    PyPlot.xlim(10,45)
    PyPlot.grid()
    PyPlot.xlabel("Days since February $(averaging_period-10), 2020")
    PyPlot.ylabel("$(averaging_period) day average of daily growth/%")
    PyPlot.legend(loc="upper left")

    # Add second y axis with doubling time
    # see  https://stackoverflow.com/a/10517481/8922290
    ax1 = PyPlot.gca()
    ax2 = ax1.twinx()
    ax2.set_ylim(ax1.get_ylim())
    growth_rates= collect(0:10:80)
    ax2.set_yticks(growth_rates)
    dtimes=doubling_time.(growth_factor.(growth_rates))
    ax2.set_yticklabels([ @sprintf("%.2f",dtimes[i]) for i=1:length(dtimes)])
    ax2.set_ylabel("Doubling time/days")
    PyPlot.savefig("../docs/infected-growthrate.png")
    PyPlot.savefig("../infected-growthrate.png")


end

# publish on github
function publish(;msg="data update")
    run(`git commit -a -m $(msg)`)
    run(`git push`)
end




