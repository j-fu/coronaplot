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
function plotcountry(df,  
                       countries,  # Array of countries
                       kind;       # Kind of plot  
                       label="", # label
                       lw=2,       # plot line width
                       lt="-",     # plot line type
                       averaging_period=15,   # averaging period: averaging_period days
                       Nstart=500  # starting data for shifting curves
                       )

    # If label name is not given, take the first name from the array
    if label===""
        label=countries[1]
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
    println("$(label), $(maximum(data))")

    # Perform plots
    if kind=="abs"
        plot(days,data,label="$(label)",lt,linewidth=lw,markersize=6)
    end
    
    if kind=="log"
        semilogy(days,data,label="$(label)",lt,linewidth=lw,markersize=6)
    end

    if kind=="growthrate"
        # Calculate daily growth factors
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
        if label=="US"
            day0=34
        end
        # Plot
        plot(day0:length(grates),grates[day0:end],label="$(label)",lt,linewidth=lw,markersize=6)
    end
end


function plotcountries(df,
                       kind;       # Kind of plot
                       averaging_period=15,   # averaging period: averaging_period days
                       Nstart=500  # starting data for shifting curves
                       )
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
    
    plotcountry(df,["Italy"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df,["France"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df,["Spain"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df,["Iran"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df,["Korea, South"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df,["China"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df,["Switzerland"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df,["Netherlands"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df,Europe,label="Europe",kind,lt="b-",Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df,["Germany"],lw=3,lt="r-o",kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df,["US"],kind,lt="k-",Nstart=Nstart, averaging_period=averaging_period)
end

# Create the plots
function create_plots(;averaging_periods=[7,15],Nstart=500)

    rawdata=read_download_infected()

    trailer="\nData source: $(dataurl) $(Dates.today())\nData processing: https://github.com/j-fu/coronaplot"
    # Plot absolute values (linear Y scale) to show exponential behavior
    fig = PyPlot.figure(1)
    fig = PyPlot.gcf()
    fig.set_size_inches(10,5)
    clf()
    title("Corona Virus Development in countries with more than 3000 infections$(trailer)")
    plotcountries(rawdata,"abs",Nstart=Nstart)
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
    plotcountries(rawdata,"log",Nstart=Nstart)
    PyPlot.xlim(0,40)
    PyPlot.grid()
    PyPlot.xlabel("Days since occurence of at least $(Nstart) infections")
    PyPlot.ylabel("Number of infections (logarithmic scale)")
    PyPlot.legend(loc="lower right")
    PyPlot.savefig("../docs/infected.png")
    PyPlot.savefig("../infected.png")

    ifig=3
    for averaging_period in averaging_periods
        # Plot evolution of growth rate average
        fig = PyPlot.figure(ifig)
        fig = PyPlot.gcf()
        fig.set_size_inches(10,5)
        clf()
        title("$(averaging_period) day average of daily growth rate of COVID-19 infections in countries with >3000 infections$(trailer)")
        plotcountries(rawdata,"growthrate",averaging_period=averaging_period)
        PyPlot.ylim(0,100)
        PyPlot.xlim(10,45)
        PyPlot.grid()
        month="February"
        day=averaging_period-10
        if day<=0
            month="January"
            day=averaging_period+22
            PyPlot.xlim(16,55)
        end
        PyPlot.xlabel("Days since $(month) $(day), 2020")
        PyPlot.ylabel("$(averaging_period) day average of daily growth/%")
        PyPlot.legend(loc="upper left")
        
        # Add second y axis with doubling time
        # see  https://stackoverflow.com/a/10517481/8922290
        ax1 = PyPlot.gca()
        ax2 = ax1.twinx()
        ax2.set_ylim(ax1.get_ylim())
        growth_rates= collect(0:10:100)
        ax2.set_yticks(growth_rates)
        dtimes=doubling_time.(growth_factor.(growth_rates))
        ax2.set_yticklabels([ @sprintf("%.2f",dtimes[i]) for i=1:length(dtimes)])
        ax2.set_ylabel("Doubling time/days")
        if averaging_period==15
            PyPlot.savefig("../docs/infected-growthrate.png")
            PyPlot.savefig("../infected-growthrate.png")
        end
        if averaging_period==7
            PyPlot.savefig("../docs/infected-growthrate-weeklyavg.png")
            PyPlot.savefig("../infected-growthrate-weeklyavg.png")
        end
        ifig=ifig+1
    end

end

# publish on github
function publish(;msg="data update")
    run(`git commit -a -m $(msg)`)
    run(`git push`)
end




