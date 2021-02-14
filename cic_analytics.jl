##
#load packages
using Plots
using StatsPlots
using Indicators
using MarketData
using IterableTables
using DataFrames
using StatsBase
using Statistics
using TimeSeries
using Impute: Impute
using FreqTables

##

##--------
#load dataset and process
function process_assets(symbol,period)
    data = yahoo(symbol, YahooOpt(period1 =(now() - period),period2 = now()- Day(1)))
    returns = percentchange(data.Close)
    merged_data = merge(data,returns.*100)
    merged_data= TimeSeries.rename(merged_data::TimeArray, :Close_1 => :Return)
    merged_df = DataFrame(merged_data)

    return merged_data, merged_df
end

eth, eth_df = process_assets(string("ETH-USD"),Month(1))
lnk, lnk_df = process_assets(string("LINK-USD"),Month(1))
snp, snp_df = process_assets(string("^GSPC"),Month(1))
#eth = yahoo(:"ETH-USD", YahooOpt(period1 = now() - Month(1)))

##---


##-- candlestick and MAs function
function crypto_MAs(ts,df,n1=7,n2=2)
    plot(ts, seriestype = :candlestick)
    movingaverage=sma(sort(df, :timestamp).Close, n=n1)
    short_MA = sma(sort(df, :timestamp).Close, n=n2)
    plot!(movingaverage, linewidth=2, color=:black)
    plot!(short_MA, linewidth=2, color=:blue)

    end
##--
# Work on eth EDA
print(describe(eth_df))
sigma_sq = var(eth_df.Close)
sigma = std(eth_df.Close)
print("std dev: ",sigma)
#candlestick with MA
crypto_MAs(eth,eth_df)
#Plot density
histogram(eth_df[:,"Returns"],bins=15,label="Returns")
#its interesteing that there's a gap between 1400-1500 price
##----

##--
#Plotting link
crypto_MAs(lnk,lnk_df)
histogram(lnk.Close,bins=25,label="Close")

print(describe(lnk_df))

print(var(lnk_df.Close))
print(std(lnk_df.Close))



##--

##--
crypto_MAs(snp,snp_df)
histogram(snp.Close,bins=30,label="Close")

print(describe(snp_df))

print(var(snp_df.Close))  #3582.6
print(std(snp_df.Close)) #59.85
##--

##--
#Combine close from eth and snp to test for correlation
#Crypto trades on the weekends resulting in more prices
#Will result in a loss of data;use last value immupation for snp

eth_snp_df= leftjoin(eth_df,snp_df, on = :timestamp,makeunique=true)
closing_df = eth_snp_df[:,["Close","Close_1"]]

eth_snp_df = Impute.locf(eth_snp_df)
closing_df = Impute.locf(closing_df)
#have to replace missing values next
#then normalize

##--

##--
gr()
plot(closing_df.Close,closing_df.Close_1, seriestype = :scatter, title = "S&P Close and ETH Close")
#no correlation between returns for snp and eth
@df eth_snp_df cor(:Return,:Return_1)
#moderate correlation in closing prices
@df eth_snp_df cor(:Close,:Close_1)
##--

plot(boxplot(closing_df.Close_1),boxplot(closing_df.Close))

#### NExt step is to normalize returns and check scatter plot/corr
#### After that check relationship between link and eth




##--
#Bayesian Inference section
eth_pos_returns = ((eth_df.Return) .> 0)
snp_pos_returns = ((snp_df.Return) .> 0)

DataFrame(Decline=[length(eth_pos_returns)-sum(eth_pos_returns),
    length(snp_pos_returns)-sum(snp_pos_returns),12+8],
    Increase=[sum(eth_pos_returns),sum(snp_pos_returns),18+13],
    Totals = [12+18,8+13,20+31])
nrow(eth_df)+nrow(snp_df)

##--
