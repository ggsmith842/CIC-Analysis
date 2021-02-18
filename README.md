
## Learning Julia

The main goal of this little project was to learn the basic of Julia while also playing around with some financial data. I chose cryptocurrencies as the main focus of this project due to it's heavy cultural presence lately. Cryptocurrency is truly an interesting beast with so many layers and concepts that are above my understanding. 

Regarding Julia, it is a beautiful language. I plan to do more projects with Julia in the future hopefully with a bigger focus on big data problems and parralel processing. Julia is known for its elegant syntax and its speed. The former is definitley true, and I look forward to being impressed with the latter.

*Disclaimer*
This project was not held to overly strict standards that a pure analytics project would normally have. This main objective of this project was to become familiar with the Julia language.


# CIC-Analysis 
### Cryptocurrency Index Correlation Analysis

**Analysis of the relationship between  index funds prices and cryptocurrency prices.** <br>

#### Problem Statement <br>

Can we determine a relationship between cryptocurrency assets or the performance of the overall market. For example, is there a relationship between Ethereum and the S&P 500?


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



### Scatter Plots
**Closing prices for S&P and ETH**

```julia
plot(closing_df.Close,closing_df.Close_1,
 seriestype = :scatter,
 title = "S&P Close and ETH Close",
 legend=false)

```

![alt_text](https://github.com/ggsmith842/CIC-Analysis/blob/main/snp_eth_close.PNG)



Return Correlation: 0.0048
Closing Price Correlation: 0.873


There does exist a decent correlation between the closing prices for the S&P and ETH.

**Refer to Problem Statement**
From here we would want to dig deeper into the relationship between the S&P and ETH since that's what the initial problem statement intends to uncover.
The methods used below can be applied to the S&P dataset but this would require imputation at the top level for the S&P included training set. However, in the interest of time I decided to look closer at the relationship ETH had with LINK. 


**Let's look at ChainLink**

![alt text](https://github.com/ggsmith842/CIC-Analysis/blob/main/eth_lnk_close.PNG)


The scatter plot of closing prices showed a linear trend between both Ethereum and ChainLink.

```julia
#no strong correlation between returns for lnk and eth
@df eth_lnk_df print("Return Correlation :",cor(:Return,:Return_1),"\n")
#very strong correlation in closing prices
@df eth_lnk_df print("Closing Price Correlation :",cor(:Close,:Close_1))

```

Return Correlation: 0.57
Closing Price Correlation: 0.93


After seeing the strong correlation between ChainLink and Ethereum I decided to run a linear regression model on the data.

### Regression Model

Similar to python `Lathe` supports a `TrainTestSplit` function which makes getting training and test data extremely simple.

```julia
combined_data=DataFrame(eth=eth_df.Close,lnk=lnk_df.Close)
train, test = Lathe.preprocess.TrainTestSplit(combined_data,.70)
```

![alt text](https://github.com/ggsmith842/CIC-Analysis/blob/main/trainData.PNG)

After creating training/test data I simplified the normalization process by creating the `normalize column()` function. The function takes in an array and returns the normalized values.

```julia
function normalize_column(arr)
 dt=StatsBase.fit(UnitRangeTransform, arr; dims=1, unit=true)
 dt_norm = StatsBase.transform(dt,arr)
 return dt_norm
end
```
Fitting the linear regression model was very similar to the syntax seen in R and I found even more simple than fitting with python.

```julia
#Run linear regression on lnk and eth
fm = @formula(eth ~ lnk)
linearRegressor = lm(fm, eth_lnk_norm_close)

print(linearRegressor,"\n",r2(linearRegressor))
```
![alt text](https://github.com/ggsmith842/CIC-Analysis/blob/main/regression_model.PNG)

**This model has an R^2 value of .869 and an RMSE of 0.151**

```julia
gr()
plot(eth_lnk_norm_close.lnk,eth_lnk_norm_close.eth,
 seriestype = :scatter, title = "ETH Close and LNK Close",label="Close",legend=:bottomright)
plot!((x) -> coef(linearRegressor)[1] + coef(linearRegressor)[2] * x, 0, 1, label="fit")
```

![alt text](https://github.com/ggsmith842/CIC-Analysis/blob/main/regression_plot.PNG)


### Still Time for Bayes

For a final little exercise I wanted to apply Bayesian Inference to a financial problem. Specifically, if the return of one asset increases, what is the probability of a second asset's returns also increasing. 

I really enjoy functional programming and I try to make as many things as possible functions when I program. The `bayes_prob()` function is the most involved function in this project but simple enough. Ensuring I was applying bayes theorem properly was my main concern, and I'm still a little skeptical.


The function applies Bayes Theorem which is *P(A|B) = P(B|A)P(A)/P(B)* where A for example is the increase in  asset A's returns and B is the increase in asset B's returns.


The function accepts three arguments:
 * df1: the first asset's dataframe
 * df2: the second asset's dataframe
 * increase: a bool that treats the conditional even as increasing returns when true

```julia
#Bayesian Inference section
#Build function to calculate BI probability
#function-----------------------
function bayes_prob(df1,df2,increase=true)
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
 return prob_ab
end
#end function
```

The two examples below give the probabilities of Ethereum returns increasing based on the behavior of ChainLink returns. 

```julia
print("Probability ETH returns increase given that ChainLink returns increase: ")
print(round(bayes_prob(eth_df,lnk_df),digits=3), "\n")

print("Probability ETH returns increase given that ChainLink returns decrease: \n")
print(round(bayes_prob(eth_df,lnk_df,false),digits=3))
```

```
Probability ETH returns increase given that ChainLink returns increase: 0.8
Probability ETH returns increase given that ChainLink returns decrease: 0.464
```
**Interpretting Results** <br>
Based on Bayes Theorem if the returns of ChainLink increase then Ethereum returns have an 80% probability of also increasing.
However, if ChainLink returns decrease, there is only a 46% chance of Ethereum returns increasing and since we can easily calculate the complement of these probabilites we can also say that there is a 54% chance of Ethereum returns decreasing if ChainLink returns decrease while there is only a 20% chance of Ethereum returns decreasing if ChainLink increases.




**Thanks for reading**
##### That's all for now!
