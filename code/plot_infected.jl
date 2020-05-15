using PyPlot
using Dates
using CSV
using XLSX
using DataFrames
using Printf


# Number of column containing country name
c_country=2

# Number of start column of time series
c_timeseries_start=5


#dsname=""
dsname=""

# Source file for data (for download)

# New version
jhu_infected="https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv"
jhu_deaths="https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv"
jhu_recovered="https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_recovered_global.csv"
rki_nowcast="https://www.rki.de/DE/Content/InfAZ/N/Neuartiges_Coronavirus/Projekte_RKI/Nowcasting_Zahlen.xlsx?__blob=publicationFile"

# Data URL (for data source in plot)
dataurl="https://github.com/CSSEGISandData/COVID-19/"

# Download and read data for confirmed infection cases
# This creates a dataframe
function load_jhu_infected(;download=true)
    if download
        Base.download(jhu_infected,"jhu_infected.csv")
    end
    CSV.read("jhu_infected.csv")
end

function load_jhu_recovered(;download=true)
    if download
        Base.download(jhu_recovered,"jhu_recovered.csv")
    end
    CSV.read("jhu_recovered.csv")
end
function load_jhu_deaths(;download=true)
    if download
        Base.download(jhu_deaths,"jhu_deaths.csv")
    end
    CSV.read("jhu_deaths.csv")
end

# Download and read data for confirmed infection cases
# This creates a dataframe
function load_rki()
    csv=CSV.read("rki.csv")
end

function load_nowcast(;download=false)
    if download
        Base.download(rki_nowcast,"Nowcasting_Zahlen.xlsx")
    end
    xf=XLSX.readxlsx("Nowcasting_Zahlen.xlsx")
    sheet=xf["Nowcast_R"]
    nowcast=[]
    i=1
    for row in XLSX.eachrow(sheet)
        if i>1
            push!(nowcast,row[2])
        end
        i=i+1
    end
    nowcast
end

function alldata_world(;download=false)
    (dead=load_jhu_deaths(download=download),
     infected=load_jhu_infected(download=download),
     recovered=load_jhu_recovered(download=download),
     #     https://data.worldbank.org/indicator/SP.POP.TOTL
     popdata=CSV.read("population.csv"))
end

function alldata_blaender(;download=false)
    (dead=nothing,
     infected=CSV.read("rki.csv"),
     recovered=nothing,
     #     https://www.statistik-bw.de/VGRdL/tbls/tab.jsp?rev=RV2014&tbl=tab20&lang=de-DE
     popdata=CSV.read("einwohnerzahl-bundeslaender.csv"))
end


# Create a new dataframe wich contains only data for given countries
# For US and China, data are given state/province/county-wise
# For former colonial powers with overseas territories etc. there are multiple rows as well
function select_countries_rows(df_jhu,countries)
    countries_mask=BitArray(undef,length(countries),size(df_jhu,1))
    for i=1:length(countries)
        countries_mask[i,:].=df_jhu[:,c_country].==countries[i]
    end
    mask=vec(reduce(|,countries_mask,dims=1))
    df_jhu[mask,:]
end



# Create timeseries for list of countries
function create_countries_timeseries(df_jhu,countries)
    crows=select_countries_rows(df_jhu,countries)
    data=sum(convert(Array,crows[:,c_timeseries_start:end]),dims=1)'
    data=convert(Vector{Float64},vec(data))
end


function create_rki_timeseries(df_rki,countries)

end

# Calculate growth factor from growth rate (in %)
growth_factor(growth_rate)=growth_rate/100.0+1

# Calculate doubling time from growth factor
doubling_time(gfactor)= log(2.0)/log(gfactor)

growth_factor_from_doubling_time(dtime)=exp(log(2.0)/dtime)

# Calculate growth rate (in %) from growth factor
growth_rate(gfactor)=(gfactor-1)*100

# Plot data for country
function plotcountry(df,  
                     countries,  # Array of countries
                     kind;       # Kind of plot  
                     label="", # label
                     lw=2,       # plot line width
                     lt="-",     # plot line type
                     averaging_period=15,   # averaging period: averaging_period days
                     Nstart=100  # starting data for shifting curves
                     )
    rki=false
    if size(df,2) <20
        rki=true
    end
    
    # If label name is not given, take the first name from the array
    if label===""
        label=countries[1]
    end
    
    # Add 1 to data for allowing to  logarithm or division
    if kind=="log"
        logdiv_regularization=1.0e-10
    elseif  kind=="growthrate"
        logdiv_regularization=1.0
    elseif  kind=="doublingtime"
        logdiv_regularization=1.0
    else
        logdiv_regularization=0.0
    end

    # Create shifted time series

    # Shift timeseries to the left cutting of the days until Nstart infections occur

    if rki
        basedata=Array{Float64}(df[Symbol(label)])
    else
        basedata=create_countries_timeseries(df,countries).+logdiv_regularization
    end
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

    if kind=="growthrate" || kind=="doublingtime"
        # Calculate daily growth factors
        gfactors=basedata[2:end]./basedata[1:end-1]
        if averaging_period > length(gfactors)-1
            println("skip: $(label)")
            return 
        end

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

        # Calculate growth rates
        grates=growth_rate.(averaged_gfactors)
        dtimes=doubling_time.(averaged_gfactors)

        # Adjust starting day due to change of reporting on US data
        day0=1
        if rki
            day0=33
        end

        if kind=="growthrate"
            plot(day0:day0+length(grates)-1,grates[1:end],label="$(label)",lt,linewidth=lw,markersize=6)
        end
        if kind=="doublingtime"
            plot(day0:day0+length(grates)-1,dtimes[1:end],label="$(label)",lt,linewidth=lw,markersize=6)
        end
    end
end




# Plot data for all countries
function plotcountries(df_jhu,df_rki,
                       kind;       # Kind of plot
                       averaging_period=15,   # averaging period: averaging_period days
                       Nstart=500  # starting data for shifting curves
                       )
    # List of countries belonging to Europa
    # (omitting those with less than 100 cases)
    Europe=[
        "Austria",
        "Sweden",
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
    
    plotcountry(df_jhu,["Italy"],kind,Nstart=Nstart, lt="o-", averaging_period=averaging_period)
    plotcountry(df_jhu,["France"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_jhu,["Spain"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_jhu,["Iran"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_jhu,["Korea, South"],kind,Nstart=Nstart,lt="o-", averaging_period=averaging_period)
    plotcountry(df_jhu,["China"],kind,Nstart=Nstart,lt="o-", averaging_period=averaging_period)
    plotcountry(df_jhu,["Switzerland"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_jhu,["Netherlands"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_jhu,["Austria"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_jhu,["Sweden"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_jhu,["Turkey"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_jhu,["Canada"],lt="y-",kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_jhu,["Russia"],lt="mo-",kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_jhu,["Brazil"],lt="g-",kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_jhu,Europe,label="Europe",kind,lt="b-o",Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_jhu,["Germany"],lw=3,lt="r-o",kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_jhu,["US"],kind,lt="k-",Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_jhu,["United Kingdom"],kind,lt="k-o", Nstart=Nstart, averaging_period=averaging_period)
end





# Plot data for all countries
function plotbundeslaender(df_jhu,df_rki,
                           kind;       # Kind of plot
                           averaging_period=15,   # averaging period: averaging_period days
                           Nstart=100  # starting data for shifting curves
                           )
    
    plotcountry(df_jhu,["Germany"], label="JHU",lw=3,lt="r-",kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["BW"],lt="y-o",kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["BY"],lt="k-o",kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["BB"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["HB"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["HH"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["HE"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["MV"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["NI"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["NW"],lt="b-o",kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["RP"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["SL"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["SN"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["ST"],kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["SH"],lt="y-",kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["TH"],lt="k-",kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["BE"],lw=3,lt="g-o",kind,Nstart=Nstart, averaging_period=averaging_period)
    plotcountry(df_rki,["Gesamt"],lw=3,lt="r-o",kind,Nstart=Nstart, averaging_period=averaging_period)
end



# Create the plots
function create_world_old(;averaging_periods=[7,15],Nstart=500,dtime=true)

    df_jhu=load_jhu_infected()
    df_rki=load_rki()
    N0=10000
    trailer="\nData source: JHU $(Dates.today())\nData processing: https://github.com/j-fu/coronaplot  License: CC-BY 2.0"

    # Plot absolute values (linear Y scale) to show exponential behavior
    fig = PyPlot.figure(1)
    fig = PyPlot.gcf()
    fig.set_size_inches(10,5)
    clf()
    title("Corona Virus Development in countries with more than $(N0) infections$(trailer)")
    plotcountries(df_jhu,df_rki,"abs",Nstart=Nstart)
#    PyPlot.ylim(1,350_000)
    PyPlot.ylim(1,200_000)
    PyPlot.xlim(0,60)
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
    title("Corona Virus Development in countries with more than  $(N0) infections$(trailer)")
    plotcountries(df_jhu,df_rki,"log",Nstart=Nstart)
    PyPlot.xlim(0,60)
    PyPlot.grid()
    PyPlot.xlabel("Days since occurence of at least $(Nstart) infections")
    PyPlot.ylabel("Number of infections (logarithmic scale)")
    PyPlot.legend(loc="upper left")
    PyPlot.savefig("../docs/infected.png")
    PyPlot.savefig("../infected.png")

    
    ifig=3
    for averaging_period in averaging_periods
        # Plot evolution of growth rate average
        fig = PyPlot.figure(ifig)
        fig = PyPlot.gcf()
        fig.set_size_inches(10,5)
        clf()
        if dtime
            title("$(averaging_period) day average of doubling time in countries with > $(N0) infections$(trailer)")
            plotcountries(df_jhu,df_rki,"doublingtime",averaging_period=averaging_period)
        else
            title("$(averaging_period) day average of daily growth rate of COVID-19 infections in countries with > $(N0) infections$(trailer)")
            plotcountries(df_jhu,df_rki,"growthrate",averaging_period=averaging_period)
        end
        PyPlot.xlim(10,90)
        if dtime
            PyPlot.ylim(0,80)
        else
            PyPlot.ylim(0,100)
        end
        
        PyPlot.grid()
        month="February"
        day=averaging_period-10
        if day<=0
            month="January"
            day=averaging_period+22
            PyPlot.xlim(16,95)
        end
        PyPlot.xlabel("Days since $(month) $(day), 2020")

        dtime_label="Doubling time/days"
        grate_label="$(averaging_period) day average of daily growth/%"
        if dtime
            PyPlot.ylabel(dtime_label)
        else
            PyPlot.ylabel(grate_label)
        end
        PyPlot.legend(loc="upper left")

        # Add second y axis
        # see  https://stackoverflow.com/a/10517481/8922290
        if dtime
            ax1 = PyPlot.gca()
            ax2 = ax1.twinx()
            ax2.set_ylim(ax1.get_ylim())
            dtimes=collect(0:5:60)
            ax2.set_yticks(dtimes)
            grates=growth_rate.(growth_factor_from_doubling_time.(dtimes))
            ax2.set_yticklabels([ @sprintf("%.2f",grates[i]) for i=1:length(dtimes)])
            ax2.set_ylabel(grate_label)
        else
            ax1 = PyPlot.gca()
            ax2 = ax1.twinx()
            ax2.set_ylim(ax1.get_ylim())
            growth_rates= collect(0:5:100)
            ax2.set_yticks(growth_rates)
            dtimes=doubling_time.(growth_factor.(growth_rates))
            ax2.set_yticklabels([ @sprintf("%.2f",dtimes[i]) for i=1:length(dtimes)])
            ax2.set_ylabel(dtime_label)
        end
            
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


# Create the plots
function create_blaender_old(;averaging_periods=[7,15],Nstart=100,dtime=true)

    df_jhu=load_jhu_infected()
    df_rki=load_rki()

    trailer="\nDatenquelle: RKI+ JHU $(Dates.today())\nDatenverarbeitung: https://github.com/j-fu/coronaplot  Lizenz: CC-BY 2.0"

    # Plot absolute values (linear Y scale) to show exponential behavior
    fig = PyPlot.figure(1)
    fig = PyPlot.gcf()
    fig.set_size_inches(10,5)
    clf()
    title("Entwicklung der COVID19-Infektionszahlen in Deutschland$(trailer)")
    plotbundeslaender(df_jhu,df_rki,"abs",Nstart=Nstart)
#    PyPlot.ylim(1,350_000)
    PyPlot.ylim(1,40_000)
    PyPlot.xlim(0,55)
    PyPlot.grid()
    PyPlot.xlabel("Tage seit dem Auftreten von $(Nstart) Infektionen")
    PyPlot.ylabel("Anzahl der Infektionen (lineare Skala)")
    PyPlot.legend(loc="upper left")
    PyPlot.savefig("../docs/de-infected-exp.png")

    # Log plot
    fig = PyPlot.figure(2)
    fig = PyPlot.gcf()
    fig.set_size_inches(10,5)
    clf()
    title("Entwicklung der COVID19-Infektionszahlen in Deutschland$(trailer)")
    plotbundeslaender(df_jhu,df_rki,"log",Nstart=Nstart)
    PyPlot.xlim(0,55)
    PyPlot.grid()
    PyPlot.xlabel("Tage seit dem Auftreten von $(Nstart) Infektionen")
    PyPlot.ylabel("Anzahl der Infektionen (logarithmische Skala)")
    PyPlot.legend(loc="lower right")
    PyPlot.savefig("../docs/de-infected.png")

    ifig=3
    for averaging_period in averaging_periods
        # Plot evolution of growth rate average
        fig = PyPlot.figure(ifig)
        fig = PyPlot.gcf()
        fig.set_size_inches(10,5)
        clf()
        if dtime
            title("$(averaging_period)-Tage-Mittel der Vertopplungszeiten$(trailer)")
            plotbundeslaender(df_jhu,df_rki,"doublingtime",averaging_period=averaging_period)
        else
            title("$(averaging_period)-Tage-Mittel der täglichen Wachstumsraten der COVID19-Infektionen in Deutschland$(trailer)")
            plotbundeslaender(df_jhu,df_rki,"growthrate",averaging_period=averaging_period)
        end
        if dtime
            PyPlot.ylim(0,100)
        else
            PyPlot.ylim(0,60)
        end
        PyPlot.xlim(50,90)
        PyPlot.grid()
        month="Februar"
        day=averaging_period-10
        if day<=0
            month="Januar"
            day=averaging_period+22
            PyPlot.xlim(50,95)
        end
        PyPlot.xlabel("Tage seit $(day). $(month)  2020")
        dtime_label="Vedopplungszeinten/d"
        grate_label="$(averaging_period)-tägiges Mittel der täglichen Wachstumsraten/%"
        
        if dtime
            PyPlot.ylabel(dtime_label)
        else
            PyPlot.ylabel(grate_label)
        end
        
        PyPlot.legend(loc="upper left")
        
        # Add second y axis with doubling time
        # see  https://stackoverflow.com/a/10517481/8922290
        if dtime
            ax1 = PyPlot.gca()
            ax2 = ax1.twinx()
            ax2.set_ylim(ax1.get_ylim())
            dtimes=collect(0:5:60)
            ax2.set_yticks(dtimes)
            grates=growth_rate.(growth_factor_from_doubling_time.(dtimes))
            ax2.set_yticklabels([ @sprintf("%.2f",grates[i]) for i=1:length(dtimes)])
            ax2.set_ylabel(grate_label)
        else
            ax1 = PyPlot.gca()
            ax2 = ax1.twinx()
            ax2.set_ylim(ax1.get_ylim())
            growth_rates= collect(0:2.5:60)
            ax2.set_yticks(growth_rates)
            dtimes=doubling_time.(growth_factor.(growth_rates))
            ax2.set_yticklabels([ @sprintf("%.2f",dtimes[i]) for i=1:length(dtimes)])
            ax2.set_ylabel("dtime_label")
        end            
        if averaging_period==15
            PyPlot.savefig("../docs/de-infected-growthrate.png")
        end
        if averaging_period==7
            PyPlot.savefig("../docs/de-infected-growthrate-weeklyavg.png")
        end
        ifig=ifig+1
    end

end

function create_plots_old()
    create_world_old()
    create_blaender_old()
end
# publish on github
function publish(;msg="data update")
    run(`git commit -a -m $(msg)`)
    run(`git push`)
end


#####################################################################
# New plots for active cases and r0


"""
Moving average of timeseries over window
"""
function mvavg(ts,window)
    tsavg=[]
    for i=1:length(ts)-window
        push!(tsavg,sum(ts[i:i+window])/window)
    end
    tsavg
end

"""
Estimate of reproduction rate from time series.
"""
function r0(ts,window)
    r0=[]
    for i=window:length(ts)-window
        # Newly infected during the current period
        new=ts[i+1:i+window]
        # Newly infected during previous period
        old=ts[i-window+1:i]
#        @show length(old), length(new)
        push!(r0,sum(new)/sum(old))
    end
    r0
end

"""
Adjust length of times series to len, padding with values at the
beginning
"""
function leftpad(ts,len;pad=0.0)
    ts_padded=[]
    for i=1:len-length(ts)
        push!(ts_padded,pad)
    end
    for i=1:length(ts)
        push!(ts_padded,ts[i])
    end
    ts_padded
end



"""
Calculate results for given country
"""
function country_results(data, country;
                         world=true,   # do we have country or bundesland ?
                         avg_window=7, # Window for moving average of time series of infected people
                         active_period=15, # Period during which we assume an infection is active 
                         infection_period=5, # Time it takes for an infected person to infect the next (RKI uses 4)
                         population_base=100_000.0
                         )

    # Access data frames via tuple
    (dead,infected,recovered,popdata)=data
    
    # Filter population data for country
    population=filter((row)-> row[1]==country, popdata)[1,2]

    popfac=Float64(population_base)/population


    # Create time series from data
    if world
        ts_dead=create_countries_timeseries(dead,[country]).*popfac
        ts_infected=create_countries_timeseries(infected,[country]).*popfac
        ts_recovered=create_countries_timeseries(recovered,[country]).*popfac
        mvavg_dead=mvavg(ts_dead,avg_window)
    else
        ts_infected=Array{Float64}(infected[Symbol(country)]).*popfac
        mvavg_dead=nothing
    end

    
    mvavg_infected=mvavg(ts_infected,avg_window)

    if world
        mvavg_recovered=mvavg(ts_recovered,avg_window)
        mvavg_active=mvavg_infected-mvavg_recovered-mvavg_dead
    else
        mvavg_recovered=nothing
        mvavg_active=nothing
    end

    # Estimate number of active cases. We just assume that reported
    # cases are active during the active period. If this number is chosen
    # large enough, we seem to get some crude, but conservative estimate.
    #
    # Just subtract the number from `active_period` ago from th ecurrent one
    # We base this on the moving average calculated before
    est_active=leftpad(mvavg_infected[active_period+1:end]-mvavg_infected[1:end-active_period],length(mvavg_infected))


    # Calculate time series of new cases from moving average of infected people
    ts_new=ts_infected[2:end]-ts_infected[1:end-1]
    weekly_new=[]
    for i=8:length(ts_new)
        push!(weekly_new,sum(ts_new[i-6:i]))
    end
    # This is based on the description given in 
    # https://www.heise.de/newsticker/meldung/Corona-Pandemie-Die-Mathematik-hinter-den-Reproduktionszahlen-R-4712676.html
    # describing the RKI method for estimating R0.
    #
    # There are two main differences here: we possibly assume a longer infection period,
    # and we base the results on the moving average of the timeseries of infected instead of the "nowcast"
    ts_new=mvavg_infected[2:end]-mvavg_infected[1:end-1]
    est_r0=leftpad(r0(ts_new,infection_period),length(mvavg_infected))
    

    # Create a time series of dates to get the x axis right
    if world
        date_start=Date(2020,1,22)+Day(avg_window)
    else
        date_start=Date(2020,2,23)+Day(avg_window)
    end        
    dates=[date_start+Day(i) for i=1:length(mvavg_infected)]
    
    
    (mvavg_dead=mvavg_dead,
     mvavg_infected=mvavg_infected,
     mvavg_recovered=mvavg_recovered,
     mvavg_active=mvavg_active,
     est_active=est_active,
     est_r0=est_r0,
     population=population,
     mvavg_new=leftpad(weekly_new,length(mvavg_infected)),
     dates=dates)
end


function nowcast_results(nowcast;
                         active_period=15,   # Period during which we assume an infection is active 
                         infection_period=5, # Time it takes for an infected person to infect the next (RKI uses 4)
                         population_base=100_000)
    pop=82927922.0
    popfac=population_base/pop
    newly=nowcast*popfac
    date_start=Date(2020,3,2)
    dates=[date_start+Day(i) for i=1:length(nowcast)]
    active=[]
    for i=active_period+1:length(nowcast)
        push!(active,sum(newly[i-active_period:i]))
    end
    active=leftpad(active,length(nowcast))
    est_r0=leftpad(r0(newly,infection_period),length(nowcast))
    est_new=[]
    for i=8:length(nowcast)
        push!(est_new,sum(newly[i-7:i]))
    end
    est_new=leftpad(est_new,length(nowcast))
    
    (dates=dates,
     est_new=est_new,
     est_active=active,
     est_r0=est_r0)
end


function plot_active_r0(country;download=false,world=true)

    if world
        data=alldata_world(download=download)
    else
        data=alldata_blaender()
    end

    population_base=100_000
    results=country_results(data,country,
                            world=world,
                            avg_window=7, # Window for moving average of time series of infected people
                            active_period=15, # Period during which we assume an infection is active 
                            infection_period=5, # Time it takes for an infected person to infect the next (RKI uses 4)
                            population_base=population_base)
    
    
    fig = PyPlot.figure(1)
    fig = PyPlot.gcf()
    fig.set_size_inches(10,5)
    clf()
    title(@sprintf("Country: %s, population: %.1f million",country,results.population/1.0e6))
    
    d0=1
    PyPlot.plot_date(results.dates[d0:end],results.mvavg_infected[d0:end],label="infected","b-")
    PyPlot.plot_date(results.dates[d0:end],results.mvavg_new[d0:end],label="new","y-")
    PyPlot.plot_date(results.dates[d0:end],results.est_active[d0:end],label="active (est)","rx")
    if world
        PyPlot.plot_date(results.dates[d0:end],results.mvavg_active[d0:end],label="active (jhu)","r-")
        PyPlot.plot_date(results.dates[d0:end],results.mvavg_recovered[d0:end],label="recovered","g-")
        PyPlot.plot_date(results.dates[d0:end],results.mvavg_dead[d0:end],label="dead","k-")
    end
    PyPlot.xlabel("Date")
    PyPlot.ylabel("Cases per $(population_base) inhabitants")
    PyPlot.legend(loc="upper left")
    PyPlot.grid()
    
    ax1 = PyPlot.gca()
    ax2 = ax1.twinx()
    ax2.set_ylim(0,4)
    ax2.plot_date(results.dates[d0:end],results.est_r0[d0:end],label="R0","m--")
    ax2.plot_date(results.dates[d0:end],[1.0 for i=d0:length(results.dates)],label="R0=1","m-",linewidth=2)
    ax2.set_ylabel("R0")
    ax2.legend(loc="upper right")
    
    PyPlot.show()
end

function countrylist()
   [
    ["Italy", "o-"],
    ["France", "o-"],
    ["Spain", "o-"],
    ["Iran", "-"],
    ["Korea, South","o-"],
    ["China","o-"],
    ["Switzerland", "-"],
    ["Netherlands", "-"],
    ["Austria", "-"],
    ["Sweden", "o-"],
    ["Turkey", "-"],
    ["Canada","y-"],
    ["Russia","mo-"],
    ["Brazil","g-"],
    ["Germany","r-o"],
    ["US","k-"],
    ["United Kingdom","k-o"]
   ]
end

function blaenderlist()
[
["BW","y-o" ],
["BY","k-o" ],
["BB","-"   ],
["HB","-"   ],
["HH","-"   ],
["HE","-"   ],
["MV","-"   ],
["NI","-"   ],
["NW","b-o" ],
["RP","-"   ],
["SL","-"   ],
["SN","-"   ],
["ST","-"   ],
["SH","y-"  ],
["TH","k-"  ],
["BE","g-o" ],
["DE","r-o" ]
]
end

    


    
function plot_active_r0(;download=false, world=true, infection_period=5)
    if world
        data=alldata_world(download=download)
        countries=countrylist()
        trailer="Data source: JHU $(Dates.today())\nData processing: https://github.com/j-fu/coronaplot  License: CC-BY 2.0"
        prefix="world"
    else
        data=alldata_blaender()
        countries=blaenderlist()
        trailer="Datenquelle: RKI via de.wikipedia.org/wiki/COVID-19-Pandemie_in_Deutschland $(Dates.today())\nDatenverarbeitung: https://github.com/j-fu/coronaplot  Lizenz: CC-BY 2.0"
        prefix="de"
        nowcast=load_nowcast(download=download)
    end
    fig = PyPlot.figure(1)
    fig = PyPlot.gcf()
    PyPlot.clf()
    fig.set_size_inches(10,5)
    if world
        d0=40
    else
        d0=10
    end
    population_base=100_000

    if world
        PyPlot.title("Estimated number of infectious persons in selected countries\n$(trailer)")
    else
        PyPlot.title("Schätzung der Zahl der infektiösen Personen\n$(trailer)")
    end
    
    for country in countries
        results=country_results(data,country[1],
                                world=world,
                                avg_window=7, # Window for moving average of time series of infected people
                                active_period=15, # Period during which we assume an infection is active 
                                infection_period=infection_period, # Time it takes for an infected person to infect the next (RKI uses 4)
                                population_base=population_base)
        PyPlot.plot_date(results.dates[d0:end],results.est_active[d0:end],label=country[1],country[2])
    end
    if !world
        results=nowcast_results(nowcast,active_period=15,infection_period=infection_period,population_base=population_base)
        PyPlot.plot_date(results.dates[d0:end],results.est_active[d0:end],label="nowcast","r*-",linewidth=2)
    end

    if world
        PyPlot.xlabel("Date")
        PyPlot.ylabel("Cases per $(population_base) inhabitants")
    else
        PyPlot.xlabel("Datum")
        PyPlot.ylabel("Fälle pro $(population_base) Einwohner")
    end
    PyPlot.legend(loc="upper left")
    PyPlot.grid()
    PyPlot.show()
    PyPlot.savefig("../docs/$(prefix)-active.png")

    ###########################################################################################################################
    fig = PyPlot.figure(2)
    fig = PyPlot.gcf()
    PyPlot.clf()
    if world
        PyPlot.title("Estimated reproduction number of SARS CoV-2 infections in selected countries\n$(trailer)")
    else
        PyPlot.title("Schätzung der Reproduktionszahl für die SARS CoV-2 Pandemie in den Bundesländern\n$(trailer)")
    end
    fig.set_size_inches(10,5)
    PyPlot.ylim(0,2)
    for country in countries
        @show country[1]
        results=country_results(data,country[1],world=world,infection_period=infection_period)
        PyPlot.plot_date(results.dates[d0:end],results.est_r0[d0:end],label=country[1],country[2])
        if country[1]=="Italy" || country[1]=="BY"
            PyPlot.plot_date(results.dates[d0:end],[1.0 for i=d0:length(results.dates)],"k--",linewidth=2)
        end
    end
    if !world
        results=nowcast_results(nowcast,active_period=15,infection_period=infection_period,population_base=population_base)
        PyPlot.plot_date(results.dates[d0:end],results.est_r0[d0:end],label="nowcast","r*-")
    end
    if world
        PyPlot.xlabel("Date")
        PyPlot.ylabel("Reproduction number")
    else
        PyPlot.xlabel("Datum")
        PyPlot.ylabel("Reproduktionszahl")
    end
    PyPlot.legend(loc="upper left")
    PyPlot.grid()
    PyPlot.show()
    PyPlot.savefig("../docs/$(prefix)-repro.png")

    ###########################################################################################################################
    fig = PyPlot.figure(3)
    fig = PyPlot.gcf()
    PyPlot.clf()
    if world
        PyPlot.title("Number of newly infected SARS-CoV2 infections in the last 7 days\n$(trailer)")
    else
        PyPlot.title("Anzahl der Neuinfektionen in den zurückliegenden 7 Tagen\n$(trailer)")
    end
    fig.set_size_inches(10,5)
    for country in countries
        results=country_results(data,country[1],world=world,infection_period=infection_period)
        PyPlot.plot_date(results.dates[d0:end],results.mvavg_new[d0:end],label=country[1],country[2])
    end
    if !world
        results=nowcast_results(nowcast,active_period=15,infection_period=infection_period,population_base=population_base)
        PyPlot.plot_date(results.dates[d0:end],results.est_new[d0:end],label="nowcast","r*-")
    end
    if world
        PyPlot.xlabel("Date")
        PyPlot.ylabel("Cases per $(population_base) inhabitants")
    else
        PyPlot.xlabel("Datum")
        PyPlot.ylabel("Fälle pro $(population_base) Einwohner")
    end
    PyPlot.legend(loc="upper left")
    PyPlot.grid()
    PyPlot.show()
    PyPlot.savefig("../docs/$(prefix)-new.png")

end

function create_plots()
    plot_active_r0(download=true, world=true )
    plot_active_r0(download=false, world=false )
end

# publish on github
function publish(;msg="data update")
    run(`git commit -a -m $(msg)`)
    run(`git push`)
end
