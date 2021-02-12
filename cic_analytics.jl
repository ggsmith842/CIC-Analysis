##
#load packages
using Plots
using MarketData
using IterableTables
using DataFrames
##

##--------
#load dataset
eth = yahoo(:"ETH-USD", YahooOpt(period1 = now() - Month(1)))
snp = yahoo(:"^GSPC",YahooOpt(period1=now()-Month(1)))
##---

##---
#Do a plot
plot(eth, seriestype = :candlestick)
##----

##
#Convert to dataframe
eth_df = DataFrame(eth)
snp_df = DataFrame(snp)

#Combine close from eth and snp to test for correlation
#Crypto trades on the weekends resulting in more prices
#Will result in a loss of data;may can
eth_snp_df= leftjoin(eth_df,snp_df, on = :timestamp,makeunique=true)
closing_df = eth_snp_df[:,["Close","Close_1"]]

#have to replace missing values next
#then normalize

##
