using PyPlot
using Dates
using CSV

r_name=2
r_datastart=5

datasource="https://github.com/CSSEGISandData/COVID-19/raw/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv"
dataurl="https://github.com/CSSEGISandData/COVID-19/"

#infected()=CSV.read("time_series_19-covid-Confirmed.csv")
infected()=CSV.read(download(datasource))


countryrow(df,country)=df[df[:,r_name].==country,:]
rowdata(row,shift)=sum(convert(Array,row[:,r_datastart-shift:end]),dims=1)'
countrydata(df,country,shift)=rowdata(countryrow(df,country),shift)

function plotcountry(df,country;shift=0,lw=2,lt="-")
    plus=""
    if shift<=0
        data=countrydata(df,country,shift).+1
        days=collect(0:length(data)-1)
    else
        plus="+"
        data=countrydata(df,country,0).+1
        days=collect(shift:shift+length(data)-1)
    end
    semilogy(days,data,label="$(country) $(plus)$(shift)",lt,linewidth=lw,markersize=6)
end

function plotcompare(;xshift=1)
    clf()
    title("Comparison of Corona Virus Development\nSource: $(dataurl)\n$(Dates.now())")
    fig = PyPlot.gcf()
    fig.set_size_inches(10,5)
    rawdata=infected()
    plotcountry(rawdata,"Italy",shift=0*xshift)
    plotcountry(rawdata,"France",shift=-9*xshift)
    plotcountry(rawdata,"US",shift=-11*xshift)
    plotcountry(rawdata,"UK",shift=-13*xshift)
    plotcountry(rawdata,"Spain",shift=-9*xshift)
    plotcountry(rawdata,"Iran (Islamic Republic of)",shift=-3*xshift)
    plotcountry(rawdata,"Republic of Korea",shift=4*xshift)
    plotcountry(rawdata,"Mainland China",shift=36*xshift)
    plotcountry(rawdata,"Germany",shift=-9*xshift,lw=3,lt="r-o")
    PyPlot.grid()
    PyPlot.xlabel("Days")
    PyPlot.ylabel("Infections")
    PyPlot.legend(loc="upper left")
    PyPlot.savefig("infected.png")
end

plotcompare()

