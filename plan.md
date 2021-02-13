### Overview and EDA

- Summary statistics (avg, variance)
- Plots (candlesticks with moving avg[50,200], density plot)
- additional tasks 
 > -- create function that accepts symbol(s) and then plots candlestick and moving averages

### Problem 1: Relationships are Tough

Is there a relationship between s&p closing prices and eth closing prices or eth closing prices and chainlink closing prices.

**Testing Methods**
- Plotting of df with both prices (scatter plot)
- Correlation Matrix between features for each pairwise group
- Test for independence (Null S&P and ETH are related) *Chisq test*

**Potential Issues**
 - S&P and crypto have different number of trading days. *can remedy with knn imputation for S&P prices*
 
 ##### Relationship Exists
 
  - If a relatioship exists dig deeper and try to determine the kind of relationship
 
 
 ### Problem 2: It'll work Probably (Bayes) 
 
  - Probabilistic model
  - If we know ethereum has increased, what's the probability chainlink will increase
  - If we know chainlink increased, whats the probability ethereum will increase
  
  **Potential Issues/tasks**
  
  - have to find whether day resulted in a gain or loss 
  - put into contingency table and apply bayes theorem
  
  ### Problem 3: I'm not the simulation! You are!
  
  - Goal is to create an index that would accurately work to predict trends of cryptocurrency
  
  **Ideas**
  
  - Build index consisting of various companies/futures all related or invested in cryptocurrency
  - Calculate NAV type pricing value for this index and test for a relationship with eth close
  
  **Potential Issues/Tasks**  
  - What will go into the index (companies who accept, own crypto and crypto futures)
  - What formula will create index price (NAV style pricing formula)
  - How will formula account for different number of trading days (index has to trade as if it trades everyday)

  
