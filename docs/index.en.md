---
title:  Plot of corona virus development (March 19)
---

- [Diese Seite auf Deutsch](index.md)
- [Introduction](#introduction)
- [Absolute numbers](#absolute-numbers)
- [Logarithmic scale](#logarithmic-scale)
- [Development of daily growth rates](#development-of-daily-growth-rates)
- [Source code for the creation of the plots](https://github.com/j-fu/coronaplot)

## Introduction
The Center for Systems Science and Engineering (CSSE)  of Johns Hopkins University
collects and publishes the data of the diesease development.

After an idea of [Mark Handley](https://twitter.com/MarkJHandley/status/1237119688578138112?s=20) we take the same
data source and plot the data in a different way for those countries which have more than 3000 cases.


- [Blog post describing the project at CSSE](https://systems.jhu.edu/research/public-health/ncov/).
- [The](https://gisanddata.maps.arcgis.com/apps/opsdashboard/index.html#/bda7594740fd40299423467b48e9ecf6) corona virus map.
- Data for the plots come from the [github repository containing the current data](https://github.com/CSSEGISandData/COVID-19)
  which are [updated once per day around 23:59 (UTC)](https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data#update-frequency)
  and may lag behind the data in the map.    
  Data  for the  US are  based on  the state  data, county  data are
  ignored.  Data  for  Europe  currently  include   the  EU,
  Switzerland, Norway, UK only. All other European countries have
  (as of March 17) less than 100 infections each.
- These data depend on many factors, among these are:
   - the real number of infections
   - the availability of tests.
   The later  strongly varies between countries, and it can plausibly be assumed that it is increasing due to increasing government efforts.




## Absolute numbers
![](infected-exp.png) 

Development of confirmed  adjusted cases since Jan  22, 2020.  Plotted with time shifts in order to compare initial 
[exponential phases](https://en.wikipedia.org/wiki/Exponential_growth).

The data for Italy are plotted without time shift. E.g. the data for Germany are shifted 8 days backward in time. 
They show that as of March 16, Germany (my country...) is very much on the same track as Italy,
just eight days behind. 



## Logarithmic scale
![](infected.png) 

This is the same plot, just with a logarithmic scale of the y-axis.


## Development of daily growth rates
![](infected-growthrate.png) 

This plot shows the evolution of the daily growth rates, averaged over 15 days. A constant growth rate corresponds to an exponential growth. A constant *growth rate* of 100% corresponds to a *growth factor* of 2 and a daily doubling of case numbers.
A constant *growth* rate of 10% corresponds to a *growth factor of* 1.1.

### Comment on this plot

As described above, the case numbers are biased by the availability of tests.  Increasing availability of tests due to government actions appears to be a possible cause of the initial growth of the rate for most countries and of the very high growth rate (as of March 19) for the US. If all or a fixed percentage of cases would be detected, one should expect a constant growth rate. As a consequence, the  growth rate is overestimated by a unknown extent.
On th eother hand, if this interpretation is true, this also would mean that when the growth rate of detected cases is going down, the real  growth rate decreases as well.



