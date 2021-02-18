
## Learning Julia

The main goal of this little project was to learn the basic of Julia while also playing around with some financial data. I chose cryptocurrencies as the main focus of this project due to it's heavy cultural presence lately. Cryptocurrency is truly an interesting beast with so many layers and concepts that are above my understanding. 

Regarding Julia, it is a beautiful language. I plan to do more projects with Julia in the future hopefully with a bigger focus on big data problems and parralel processing. Julia is known for its elegant syntax and its speed. The former is definitley true, and I look forward to being impressed with the latter.


# CIC-Analysis 
### Cryptocurrency Index Correlation Analysis

**Analysis of the relationship between  index funds prices and cryptocurrency prices.** <br>

#### Problem Statement <br>

Can we determine a relationship between cryptocurrency prices and the performance of the overall market. For example, is there a relationship between Ethereum and the S&P 500?


#### Data <br>

The data for this project was collected from the `MarketData` package in Julia. The data collected is a time series with open, close, adj close, and volume. I found the time series format difficult to work with and did not include a returns column for the asset in question. To counter this I created the `process_assets()` function which grabs the data, creates a returns column, merges the new column, and creates a DataFrame object. The function returns the time series and the data frame. 


```julia

function process_assets(symbol,period) 
 data = yahoo(symbol, YahooOpt(period1 =(now() - period),period2 =now()-Day()))
 returns = percentchange(data.Close)
 merged_data = merge(data,returns.*100)
 merged_data= TimeSeries.rename(merged_data::TimeArray, :Close_1 => :Return)
 merged_df = DataFrame(merged_data)
 return merged_data, merged_df
end

eth, eth_df = process_assets(string("ETH-USD"),Month(2))
```


*note: I should have split the data into train/test sets at this point but I was more focused on learning the language at the time.*

#### EDA <br>

Looking at the data for Ethereum, ChainLink, & the S&P 500 index showed good data quality with no real issues regarding the data. The biggest issue initially is that since the S&P doesn't trade on weekends and holidays there were missing values. This was solved using next observation carried backwards imputation (NOCB).

### Distribution for ETH <br>

![alt text](https://github.com/ggsmith842/CIC-Analysis/blob/main/eth_density.PNG)



### Scatter Plot 
**Closing prices for S&P and ETH**

```julia
plot(closing_df.Close,closing_df.Close_1,
 seriestype = :scatter,
 title = "S&P Close and ETH Close",
 legend=false)

```

![alt text](https://github.com/ggsmith842/CIC-Analysis/blob/main/eth_lnk_close.PNG)

**Let's look at the correlation**

```julia
#no strong correlation between returns for lnk and eth
@df eth_lnk_df print("Return Correlation :",cor(:Return,:Return_1),"\n")
#very strong correlation in closing prices
@df eth_lnk_df print("Closing Price Correlation :",cor(:Close,:Close_1))

```

Return Correlation :0.57
Closing Price Correlation :0.93


