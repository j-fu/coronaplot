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

# Plot data for countries
function plotcountries(df,
                       countries,
                       kind;
                       label="", # label
                       lw=2, # plot line width
                       lt="-", # plot line type
                       delta=7, # averaging mask: delta days befor and after
                       Nstart=500 # starting data for shifting curves
                       )
    if label===""
        label=countries[1]
    end
    
    # Add 1 to data for logkind plot
    if kind=="log"
        logkind_correction=1.0e-10
    elseif  kind=="growthrate"
        logkind_correction=1.0
    else
        logkind_correction=0.0
    end

    # Create shifted time series
    # Shift timeseries to the left by cutting of the first `shift` entries
    reldays="days behind"
    basedata=create_countries_timeseries(df,countries)
    basedata.=basedata.+logkind_correction
    shift=1
    while basedata[shift]<Nstart
        shift=shift+1
    end
    data=basedata[shift:end]
    days=collect(0:length(data)-1)
    # print for debugging purposes
    #println(data)
    println("$(label), $(maximum(data))")
    # if maximum(data)==1
    #     error("$(label) not found")
    # end

    # Add to plot
    if kind=="abs"
        plot(days,data,label="$(label)",lt,linewidth=lw,markersize=6)
    end
    if kind=="log"
        semilogy(days,data,label="$(label)",lt,linewidth=lw,markersize=6)
    end
    if kind=="growthrate"
        grate0=basedata[2:end]./basedata[1:end-1]
        @show grate0
        
        grate=ones(length(grate0)-2*delta-1)
        j=1
        for i=1+delta:length(grate0)-delta-1
            fac=1.0/(1+2*delta)
            grate[j]=fac*grate0[i]
            for d=1:delta
                grate[j]+=fac*(grate0[i-d]+grate0[i+d])
            end
            j=j+1
        end
        grate.=(grate.-1).*100
        
        day0=1
        if countries[1]=="US"
            day0=34
        end
        plot(day0:length(grate),grate[day0:end],label="$(label)",lt,linewidth=lw,markersize=6)
    end
end



# Create the plots
function create_plots(;delta=7,Nstart=500)

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

    
    # Plot absolute values to show exponential behavior
    clf()
    title("Corona Virus Development in countries with more than 3000 infections$(trailer)")
    plotcountries(rawdata,["Italy"],"abs",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["France"],"abs",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["Spain"],"abs",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["Iran"],"abs",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["Korea, South"],"abs",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["China"],"abs",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["Switzerland"],"abs",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,Europe,label="Europe","abs",lt="b-",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["Germany"],lw=3,lt="r-o","abs",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["US"],"abs",lt="k-",delta=delta,Nstart=Nstart)
    PyPlot.ylim(1,80_000)
    PyPlot.xlim(0,30)
    PyPlot.grid()
    PyPlot.xlabel("Days since occurence of at least $(Nstart) infections")
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
    plotcountries(rawdata,["Italy"],"log",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["France"],"log",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["Spain"],"log",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["Iran"],"log",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["Korea, South"],"log",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["China"],"log",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["Switzerland"],"log",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,Europe,label="Europe","log",lt="b-",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["Germany"],lw=3,lt="r-o","log",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["US"],"log",lt="k-",delta=delta,Nstart=Nstart)
    PyPlot.xlim(0,40)
    PyPlot.grid()
    PyPlot.xlabel("Days since occurence of at least $(Nstart) infections")
    PyPlot.ylabel("Infections (logarithmic scale)")
    PyPlot.legend(loc="lower right")
    PyPlot.savefig("../docs/infected.png")
    PyPlot.savefig("../infected.png")

    # Plot absolute values to show exponential behavior
    fig = PyPlot.figure(3)
    fig = PyPlot.gcf()
    fig.set_size_inches(10,5)
    clf()
    title("$(2*delta+1) day average of daily growth rate of COVID-19 infections in countries with >3000 infections$(trailer)")
    plotcountries(rawdata,["Italy"],"growthrate",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["France"],"growthrate",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["Spain"],"growthrate",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["Iran"],"growthrate",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["Korea, South"],"growthrate",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["China"],"growthrate",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["Switzerland"],"growthrate",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,Europe,label="Europe","growthrate",lt="b-",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["Germany"],lw=3,lt="r-o","growthrate",delta=delta,Nstart=Nstart)
    plotcountries(rawdata,["US"],"growthrate",lt="k-",delta=delta,Nstart=Nstart)
    PyPlot.ylim(0,120)
    PyPlot.xlim(10,45)
    PyPlot.grid()
    PyPlot.xlabel("Days since January $(22+delta), 2020")
    PyPlot.ylabel("Daily growth/%")
    PyPlot.legend(loc="upper left")
    PyPlot.savefig("../docs/infected-growthrate.png")
    PyPlot.savefig("../infected-growthrate.png")


end

# publish on github
function publish(;msg="data update")
    run(`git commit -a -m $(msg)`)
    run(`git push`)
end
