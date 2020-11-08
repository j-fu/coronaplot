### A Pluto.jl notebook ###
# v0.12.7

using Markdown
using InteractiveUtils

# ╔═╡ 5d84ea34-2202-11eb-0a5e-8153f59b5785
using Gumbo, HTTP,PyPlot,DataFrames,Dates,CSV

# ╔═╡ d02e25a2-2202-11eb-21b7-89a516182e0f
rawpage=HTTP.get("https://de.wikipedia.org/wiki/COVID-19-Pandemie_in_Deutschland/Statistik");

# ╔═╡ fb46d6f8-2202-11eb-1cda-8509c49cb0de
parsed_page=parsehtml(String(rawpage.body));

# ╔═╡ ce05b5c6-2205-11eb-3533-b3a8e0450f2e
function find_table(element,text)
	if isa(element,HTMLText)
     	return nothing
    end
	if length(element.children)>0 && element[1] isa Gumbo.HTMLElement{:caption} && occursin(text,String(element[1][1].text))
		return element
	else
		for i=1:length(element.children)
			 result=find_table(element.children[i],text)
             if result!=nothing
				return result
			end
		end
	end
end

# ╔═╡ aaf63af0-2206-11eb-0c77-df3ffa48b31b
t=find_table(parsed_page.root,"Infektionsfälle");

# ╔═╡ 05f3b3a0-2208-11eb-07f4-cbfd72d3aa4a
function header(t)
	hd=t[2][1]
	hdr=[hd[i][1][1].text for i=3:18]
	push!(hdr,"DE")
end

# ╔═╡ 226610d0-220a-11eb-1a51-e913fa1a9120
hd=header(t)

# ╔═╡ f85174da-220c-11eb-3bdc-0505db8fa860
function col(t,land)
	hd=header(t)
	for i=1:length(header(t))
		if land==hd[i]
			return i
		end
	end
	nothing
end

# ╔═╡ 32269a70-220b-11eb-0c7b-b389a74d0654
header(t)

# ╔═╡ f784c84c-220a-11eb-18c1-9f9ccbc76377
nrows(t)=length(t[2].children)-2

# ╔═╡ e2e5c45e-220a-11eb-1c25-fb79acd8d277
function row(t,i)
	tr=t[2][i+1]
	start=2
	if haskey(tr[1].attributes,"rowspan")
		start=3
	end
	[ replace(tr[i][1].text, r"\n|\t|\." => s"")  for i=start:length(tr.children)-2]
end

# ╔═╡ 9a7b1f6c-2213-11eb-2eed-0bfd1e360bc2
row(t,50)

# ╔═╡ 02467d42-2211-11eb-2b75-79953c5ca690
date_start=Date(2020,2,23)

# ╔═╡ bd80acd6-220f-11eb-223a-134dd4b501aa
num(s)= try parse(Int64,s) catch e 0 end

# ╔═╡ 406c112e-220f-11eb-22ff-e95bf1ed6128
begin
df=DataFrame(Datum=[date_start+Day(i) for i=1:nrows(t)])
for icol=1:length(header(t))
	df[Symbol(header(t)[icol])]=[num(row(t,i)[icol]) for i=1:nrows(t)]
end
end

# ╔═╡ 5455d774-220f-11eb-1038-8db3d3646f6f
df

# ╔═╡ 43270c24-2210-11eb-0789-e733ddad3fda
begin
	fig=figure(2)
	clf()
    xhd=header(t)
	for i=1:length(xhd)
	plot_date(df[:Datum],df[Symbol(xhd[i])],"-",label=xhd[i])
	end
	legend(loc="upper left")
	fig	
end

# ╔═╡ edff59b8-2214-11eb-32a1-bd37af96c44b
CSV.write("rki_scraped.csv",df)

# ╔═╡ 90756dc8-2205-11eb-092b-e1f28bf76325
parsed_page.root[2][3][5][7][1][17];

# ╔═╡ Cell order:
# ╠═5d84ea34-2202-11eb-0a5e-8153f59b5785
# ╠═d02e25a2-2202-11eb-21b7-89a516182e0f
# ╠═fb46d6f8-2202-11eb-1cda-8509c49cb0de
# ╠═ce05b5c6-2205-11eb-3533-b3a8e0450f2e
# ╠═aaf63af0-2206-11eb-0c77-df3ffa48b31b
# ╠═226610d0-220a-11eb-1a51-e913fa1a9120
# ╠═f85174da-220c-11eb-3bdc-0505db8fa860
# ╠═05f3b3a0-2208-11eb-07f4-cbfd72d3aa4a
# ╠═32269a70-220b-11eb-0c7b-b389a74d0654
# ╠═f784c84c-220a-11eb-18c1-9f9ccbc76377
# ╠═e2e5c45e-220a-11eb-1c25-fb79acd8d277
# ╠═9a7b1f6c-2213-11eb-2eed-0bfd1e360bc2
# ╠═02467d42-2211-11eb-2b75-79953c5ca690
# ╠═bd80acd6-220f-11eb-223a-134dd4b501aa
# ╠═406c112e-220f-11eb-22ff-e95bf1ed6128
# ╠═5455d774-220f-11eb-1038-8db3d3646f6f
# ╠═43270c24-2210-11eb-0789-e733ddad3fda
# ╠═edff59b8-2214-11eb-32a1-bd37af96c44b
# ╠═90756dc8-2205-11eb-092b-e1f28bf76325
