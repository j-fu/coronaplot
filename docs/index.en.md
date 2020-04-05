---
title:  Plot of corona virus development (April 5, 2020)
---

- [Diese Seite auf Deutsch](index.md)
- [Plots for  Germany](de-plots.md) (in German)
- [Introduction](#introduction)
- [Absolute numbers](#absolute-numbers)
- [Logarithmic scale](#logarithmic-scale)
- [Development of daily growth rates](#development-of-daily-growth-rates)
- [Changes in this document](#changes)
- [Source code for the creation of the plots](https://github.com/j-fu/coronaplot)
- Further Links
    -  [<img src="ms4j.jpg" width="200"> Facemasks for all](https://www.facebook.com/groups/2725984604188343/): Facebook campaign promoting wearing (and making...) of facemasks
    - Interactive [Epidemic Calculator](http://gabgoh.github.io/COVID/index.html)
      based on a mathematical disease model by Gabriel Goh (thanks, Sabine!)
    - [Investigation of the outbreak development](https://www.staff.uni-oldenburg.de/bernd.blasius/project/corona/) by Bernd Blasius using the same data
    - [Interview with Christian Drosten](https://www.zeit.de/wissen/gesundheit/2020-03/christian-drosten-coronavirus-pandemic-germany-virologist-charite/komplettansicht) - Virologist  and one of the main advisers of the German government during this crisis
    -  Similar projects on  [covid19dashbords.com](https://covid19dashboards.com/):
       - [Comparison of country trajectories](https://covid19dashboards.com/compare-country-trajectories/)
       - [Growth analysis](https://covid19dashboards.com/growth-analysis/)


## Introduction
The Center for Systems Science and Engineering (CSSE)  of Johns Hopkins University
collects and publishes the data of the diesease development.

After an idea of [Mark Handley](https://twitter.com/MarkJHandley/status/1237119688578138112?s=20) we take the same
data source and plot the data in a different way for selected countries.


- [Blog post describing the project at CSSE](https://systems.jhu.edu/research/public-health/ncov/).
- [The](https://gisanddata.maps.arcgis.com/apps/opsdashboard/index.html#/bda7594740fd40299423467b48e9ecf6) corona virus map.
- Data for the plots come from the [github repository containing the current data](https://github.com/CSSEGISandData/COVID-19)
  which are [updated once per day around 23:59 (UTC)](https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data#update-frequency)
  and may lag behind the data in the map.    
  Data  for the  US are  based on  the state  data, county  data are
  ignored.  Data  for  Europe  currently  include   the  EU,
  Switzerland, Norway, UK and Serbia only. All other European countries had
  on April 4 less than 500 infections each.
- These data depend on many factors, among these are:
   - the real number of infections
   - the availability of tests.
   The later  strongly varies between countries.



## Absolute numbers
![](infected-exp.png) 

Development of confirmed  adjusted cases since the first day with more than 500 reported infections. This representation compares the initial 
[exponential phases](https://en.wikipedia.org/wiki/Exponential_growth) of the spread of the virus.


## Logarithmic scale
![](infected.png) 

This is the same plot, just with a logarithmic scale of the y-axis.


## Development of daily growth rates
![](infected-growthrate.png) 

![](infected-growthrate-weeklyavg.png) 

These plots show the evolution of the average daily growth rates. A constant growth rate corresponds to an exponential growth. A constant *growth rate* of 100% per day corresponds to a *growth factor* of 2 per day and a daily doubling of case numbers.
A constant *growth  rate* of 10% per day corresponds to a *growth factor* of 1.1 per day. The right Y-axis shows the 
[doubling times](https://en.wikipedia.org/wiki/Doubling_time) (time it takes to double the number of infected)
corresponding to the different growth rates. Averaging is based on the geometric average of the growth factors.


### Comment on these plots

As described above, the case numbers are biased by the availability of tests.  Increasing availability of tests due to government actions appears to be a possible cause of the initial growth of the rate for most countries. If all or a fixed percentage of cases would be detected, one should expect a constant growth rate. As a consequence, the  growth rate in the beginning phase is overestimated by a unknown extent.
On the other hand, if this interpretation is true, *and the availability of tests does not decrease* this also would mean that when the growth rate of detected cases is going down, the real  growth rate decreases as well.



## Changes
We document here significant changes besides data updates. 
### 2020-04-03
-  Additional [plots for  Germany](de-plots.md)
### 2020-03-29
- Additional data for Germany from the Robert Koch Institute (RKI). These are not published as time series.
These data  are watched by [Wikipedia](https://de.wikipedia.org/wiki/COVID-19-Pandemie_in_Deutschland#Infektionsfälle), and time series
are provided in the article. These data are used here.
### 2020-03-24
- For the international data used here, there is now one US entry in the new format time series files which appearantly
has been cleaned for the past. Counting seems to have changed. See also the [annoucement by JHU](https://github.com/CSSEGISandData/COVID-19/issues/1250).

### 2020-03-22
- Added 7-day average plot
- Switched averaging in the growth rate graph from arithmetic [mean](https://en.wikipedia.org/wiki/Mean) to geometric mean of the growth factors.  
For varying daily growh factors over the averaging period, the geometric mean tells us what would have been the *constant* daily growth factor  with the same outcome. Therefore, this type of mean is more adequate for this process. In comparison, before, in particular the US data had been biased by outliers. For comparison, here is the old graph with the data of March 22:

<img src="https://github.com/j-fu/coronaplot/raw/51326c1522407fca8a5c32ba280460d8924d2f06/infected-growthrate.png" width="200">




