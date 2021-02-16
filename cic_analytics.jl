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
using HypothesisTests
using StatsModels
using Lathe
using GLM

##

##--------
#load dataset and process
function process_assets(symbol,period) #gotta figure out how to fix date
    data = yahoo(symbol, YahooOpt(period1 =(now() - period),period2 =now()-Day(4)))
    returns = percentchange(data.Close)
    merged_data = merge(data,returns.*100)
    merged_data= TimeSeries.rename(merged_data::TimeArray, :Close_1 => :Return)
    merged_df = DataFrame(merged_data)

    return merged_data, merged_df
end

eth, eth_df = process_assets(string("ETH-USD"),Month(2))
lnk, lnk_df = process_assets(string("LINK-USD"),Month(2))
snp, snp_df = process_assets(string("^GSPC"),Month(2))
#eth = yahoo(:"ETH-USD", YahooOpt(period1 = now() - Month(1)))

##---


##-- candlestick and MAs function
function crypto_MAs(ts,df,n1=7,n2=2)
    plot(ts, seriestype = :candlestick,title="Candlestick")
    movingaverage=sma(sort(df, :timestamp).Close, n=n1)
    short_MA = sma(sort(df, :timestamp).Close, n=n2)
    plot!(movingaverage, linewidth=2, color=:black)
    plot!(short_MA, linewidth=2, color=:blue,label=n2)

    end
##--
# Work on eth EDA
print(describe(eth_df),"\n")
sigma = std(eth_df.Close)
print("sigma: ",sigma)
#candlestick with MA
crypto_MAs(eth,eth_df)
#Plot density
histogram(eth_df[:,"Return"],bins=15,label="Returns")
#its interesteing that there's a gap between 1400-1500 price
##----

##--
#Plotting link
crypto_MAs(lnk,lnk_df)
histogram(lnk.Close,bins=25,label="Close")

print(describe(lnk_df),"\n","sigma ",std(lnk_df.Close))
##--

##--
crypto_MAs(snp,snp_df)
histogram(snp.Close,bins=30,label="Close")

print(describe(snp_df),"\n","sigma ",std(snp_df.Close))

##--

##--
eth_snp_df= leftjoin(eth_df,snp_df, on = :timestamp,makeunique=true)
closing_df = eth_snp_df[:,["Close","Close_1"]]

eth_snp_df = Impute.nocb(eth_snp_df)
closing_df = Impute.nocb(closing_df)

eth_lnk_df = leftjoin(eth_df,lnk_df, on = :timestamp,makeunique=true)
eth_lnk_df_close = eth_lnk_df[:,["Close","Close_1"]]

##--

##--
# ETH vs SNP
gr()
plot(closing_df.Close,closing_df.Close_1, seriestype = :scatter, title = "S&P Close and ETH Close")
#no correlation between returns for snp and eth
@df eth_snp_df cor(:Return,:Return_1)
#moderate correlation in closing prices
@df eth_snp_df cor(:Close,:Close_1)

#ETH vs LNK
plot(eth_lnk_df_close.Close,eth_lnk_df_close.Close_1,
    seriestype = :scatter, title = "ETH Close and LNK Close",label="Close")
#no correlation between returns for snp and eth
@df eth_lnk_df cor(:Return,:Return_1)
#good correlation in closing prices
@df eth_lnk_df cor(:Close,:Close_1)

##--
#### Next step is to normalize returns and check scatter plot/corr
#function to normalize a pair of columns ie eth and snp returns
function normalize_column(arr)
    dt=StatsBase.fit(UnitRangeTransform, arr; dims=1, unit=true)
    dt_norm = StatsBase.transform(dt,arr)
    return dt_norm
end

eth_norm_close = normalize_column(eth_df.Close)
lnk_norm_close = normalize_column(lnk_df.Close)

eth_lnk_norm_close = DataFrame(eth=eth_norm_close,lnk=lnk_norm_close)
#plot(eth_norm_returns,snp_norm_returns, seriestype = :scatter, title = "S&P Return and ETH Return")
#no correlation at all with returns

##--
#Run linear regression on lnk and eth
train, test = Lathe.preprocess.TrainTestSplit(eth_lnk_norm_close,.70)

fm = @formula(eth ~ lnk)
linearRegressor = lm(fm, train)
print(linearRegressor)

gr()
plot(eth_lnk_norm_close.lnk,eth_lnk_norm_close.eth,
    seriestype = :scatter, title = "ETH Close and LNK Close",label="Close",legend=:bottomright)
plot!((x) -> -0.06898 + 1.1825 * x, 0, 1, label="fit_exact")
##--

ypredicted_test = predict(linearRegressor, test)


#predicted vs actual
DataFrame(eth_pred=ypredicted_test,eth_actual=test.eth)

##--
#Bayesian Inference section
#Build function to calculate BI probability

#function-----------------------
function bayes_prob(df1,df2,increase=true,complement=false)

    df = leftjoin(df1,df2, on = :timestamp,makeunique=true)
    if sum(describe(df).nmissing) > 0
        df = Impute.nocb(df) #in case missing values exist

    end

    return_df = DataFrame(A=df.Return.>0,B=df.Return_1.>0)
    my_table = freqtable(return_df.B,return_df.A)

    if increase == true
        prob_a = sum(my_table[:,Name(true)])/sum(my_table)
        prob_b = sum(my_table[Name(true),:])/sum(my_table)
        prob_ba = sum(my_table[Name(true),Name(true)])/sum(my_table[:,Name(true)])

        prob_ab = prob_ba*prob_a/prob_b
    else
        prob_a = sum(my_table[:,Name(true)])/sum(my_table)
        prob_b = sum(my_table[Name(false),:])/sum(my_table)
        prob_ba = sum(my_table[Name(false),Name(true)])/sum(my_table[:,Name(true)])

        prob_ab = prob_ba*prob_a/prob_b
    end

    if complement==false
        return prob_ab
    else
        return 1-prob_ab
    end
end

bayes_prob(eth_df,lnk_df)

#end function----------------------------

##--
#put in weave
#summarize findings and contents

##--
