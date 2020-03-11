#!/bin/sh
julia --project=@. plot_infected.jl
git commit -a -m "update `date`"
git push

