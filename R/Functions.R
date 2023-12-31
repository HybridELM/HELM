library(jsonlite)
library(tswge)
library(lsa)  ##for cosine similarity
library(proxy) ## for jaccard similarity
library(neighbr)
library(nnfor)
library(RDCOMClient)
library(forecast) # thetaf()
library(smooth)   # es(), auto.ssarima(), auto.ces()

#######################################################################################

read_data<-function(which_data='monthly'){

  ##change which_data for different m3 series
  json_file = switch(
    which_data,
    "monthly"= lapply(readLines("https://raw.githubusercontent.com/tiddles585/Capstone/main/M3_Json/monthly.json"), fromJSON),
    "yearly"= lapply(readLines("https://raw.githubusercontent.com/tiddles585/Capstone/main/M3_Json/yearly.json"), fromJSON),
    "quarterly"= lapply(readLines("https://raw.githubusercontent.com/tiddles585/Capstone/main/M3_Json/quarterly.json"), fromJSON),
    "other"= lapply(readLines("https://raw.githubusercontent.com/tiddles585/Capstone/main/M3_Json/other.json"), fromJSON),
  )

  return(json_file)

}

#######################################################################################-

to_numeric<-function(json_file){
  ##turn target variables into numeric from string, if necessary

  json_file <- lapply(json_file, function(x) {
    x$target <- as.numeric(x$target)
    return(x)
  })

  return(json_file)
}

#######################################################################################-


series_features<-function(json_file){
  ##stores information as seasonality, difference, phis thetas, and overall series length

  json_file<-lapply(json_file,function(x){
    x$series_features<-list('p'=0,'q'=0,'d'=0,'s'=0,
                            'series_length'=length(x$target),
                            'phi'=0,'theta'=0,
                            'year'=0,'month'=0)
    return(x)})


  return(json_file)
}



#######################################################################################-

##This assigns d=1 if p value is less than .05

cochrane_orcutt_eval<-function(json_file){

  json_file<-lapply(json_file,function(x) {

    ##get data

    t<-seq(1,x$series_features$series_length,1)
    data=x$target

    ##fit cochrane orcutt
    fit.lm<-lm(data~t)

    p_value <- tryCatch({
      # code that might produce an error
      summ=summary(cochrane.orcutt(fit.lm,convergence = 1e-6))
      p_value<-summ$coefficients[,4]['t']
    }, error = function(e) {
      # code to execute if an error occurs
      p_value=.03
    })

    if(p_value<=.05){
      x$series_features$d=1
    }
    return(x)
  })

  return(json_file)

}


#



#######################################################################################-


remove_trend_differencing<-function(json_file){

  json_file<-lapply(json_file,function(x) {

    if(x$series_features$d==1){
      x$Transformed=artrans.wge(x$target,c(1),plottr = FALSE) }
    else {
      x$Transformed=x$target
    }


    return(x)

  })
  return(json_file)
}


#######################################################################################-


##Code borrowed from aic5 function in tswge package

my_aic<-function (x, p = 0:5, q = 0:2, type = "aic")
{
  pmax = max(p)
  pmin = min(p)
  qmax = max(q)
  qmin = min(q)
  nr = (pmax - pmin + 1) * (qmax - qmin + 1)
  aval <- matrix(0, nrow = nr, ncol = 3)
  mytype = type
  indx = 0
  for (ip in pmin:pmax) for (iq in qmin:qmax) {
    {
      indx <- indx + 1
      ret <- try(aic.wge(x, p = ip, q = iq, type = mytype),
                 silent = TRUE)
      if (is.list(ret) == TRUE) {
        aval[indx, ] <- c(ret$p, ret$q, ret$value)
      }
      else {
        aval[indx, ] <- c(ip, iq, 999999)
      }
    }
  }
  dat <- data.frame(aval)
  sorted_aval <- dat[order(dat[, 3], decreasing = F), ]
}



#######################################################################################-



get_Phi_Thetas_aic<-function(json_file){

  ## estimate phis and thetas...data at this point shoudl be transformed for trend and seasonality
  ##This estimates phis and thetas based off of the top aic value.
  json_file<- lapply(json_file,function(x){

    aic<-my_aic(x$Transformed)
    p=aic$X1[1]
    q=aic$X2[1]
    x$series_features$p=p
    x$series_features$q=q
    estimates<-est.arma.wge(x$Transformed,p=p,q=q,factor=FALSE)
    x$series_features$phi=estimates$phi
    x$series_features$theta=estimates$theta

    return(x)
  }
  )

  return(json_file)
}

#######################################################################################-



#######################################################################################-



forecast_arima<-function(json_file,horizon=0){


  ##this just returns forecasts horizon and series features.
  fore_holder<-invisible(lapply(json_file,function(x){
                                                          fores<-(fore.aruma.wge(x$target,phi=x$series_features$phi,
                                                          theta=x$series_features$theta,
                                                          d=x$series_features$d,
                                                          s=x$series_features$s,
                                                          n.ahead=horizon,
                                                          lastn=TRUE,
                                                          plot = FALSE))

                                                          return(list('forecasts'=fores$f,
                                                                    'horizon'=horizon,
                                                                    'phi'=x$series_features$phi,
                                                                    'theta'=x$series_features$theta,
                                                                    'd'=x$series_features$d,
                                                                    's'=x$series_features$s,
                                                                    'original_length'=x$series_features$series_length))}
  ))



  return(fore_holder)
}

#######################################################################################-
# START DUY'S STUFF
#######################################################################################-

forecast_es = function(json_file, horizon=0) {
  
  fore_holder<-invisible(lapply(json_file,function(x){

    es_holder = es(x$monthly_timeseries)
    # ets(y, all defaults) is equivalent to es(y, model="ZXZ")
    # ets() is the original exponential smoothing state space model by Hyndman et al.(2008), consisting of 24 models
            # 1st letter (A, M) = error, 2nd letter (N, A, M, D) = trend, 3rd letter (N, A, M) = seasonal
    # es() is the regularly updated extension to it, consisting of 30 models that can all be regulated via...
        # only all additive = XXX, no multiplicative trend = ZXZ, no additive components (slow moving products) = YYY, ...
        # forecast combination of AIC weights for all models = CCC, same but all non-seasonal models = CCN
            # 1st letter (A, M) = error, 2nd and sometimes 3rd letter (N, A, Ad, M, Md) = trend, 3rd letter (N, A, M) = seasonal
    model = es_holder$model
    holder = forecast(es_holder, h=horizon)$forecast
    
    return(list('forecasts'=holder, 'model'=model, 'horizon'=horizon, 'original_length'=x$series_features$series_length))
                                   # model="NNN" = SES (simple exponential smoothing)
                                   # model="ANN" = SES with additive error
                                   # model="AAA" = additive Holt-Winter's
                                   # model="MAM" = multiplicative Holt-Winter's
    
  }))
  
  return(fore_holder)
}

forecast_ces = function(json_file, horizon=0) {
  
  fore_holder<-invisible(lapply(json_file,function(x){
    
    ces_holder = ces(x$monthly_timeseries)
    # ...
    holder = forecast(ces_holder, h=horizon)$forecast
    
    return(list('forecasts'=holder, 'horizon'=horizon, 'original_length'=x$series_features$series_length))
    
  }))
  
  return(fore_holder)
}

forecast_theta = function(json_file, horizon=0) {
  
  fore_holder<-invisible(lapply(json_file,function(x){
    
    holder = thetaf(x$monthly_timeseries, horizon)$mean
    # ...
    
    return(list('forecasts'=holder, 'horizon'=horizon, 'original_length'=x$series_features$series_length))
    
  }))
  
  return(fore_holder)
}

#######################################################################################-

fix_start = function(json_file) {

  json_file<-lapply(json_file,function(x) {
    x$series_features$year = strftime(x$start, "%Y")
    x$series_features$month = strftime(x$start, "%m")


    return(x)
  })

  return(json_file)
}

#######################################################################################-

create_monthly_timeseries = function(json_file) {

  json_file<-lapply(json_file,function(x) {
    x$monthly_timeseries = ts(data = x$target,
                         start = c(x$series_features$year, x$series_features$month),
                         frequency = 12)

    return(x)
  })

  return(json_file)
}

#######################################################################################-
# END DUY'S STUFF
#######################################################################################-

#######################################################################################-


write_forecasts<-function(forecasts,name,folder){

  saveRDS(forecasts, file=paste0(folder,'/',name,".RData"))

}



#######################################################################################-

sMAPE_calculate<-function(json_file,forecast_object){
  #sMAPE_holder<-c()
# h=2:18
# which_series=1:1428
  ##Gets forecasts and originals for horizon passed.
      my_sMAPES<-lapply(horizon,function(h) {

        targets<-lapply(which_series,function(x) {
                          l<-length(json_file[[x]]$target)
                          json_file[[x]]$target[(l+1-h):l]
                          })



        fores <- list()

        # Iterate over the numbers 1 to 10 and extract the forecasts object for each series
        for (i in which_series) {
          fores[[i]] <- forecast_object[[h-1]][[i]]$forecasts
        }

        sMAPE<-sapply(1:length(targets),function(ind) (2/(h))*sum((abs(targets[[ind]]-fores[[ind]])/(abs(targets[[ind]])+abs(fores[[ind]])))*100))
        return(sMAPE)

      })

     return(my_sMAPES)
}



#######################################################################################-




read_forecasts<-function(folder,name){


  read_in<-readRDS(paste0(folder,'/',name,".RData"))

  return(read_in)

}

#######################################################################################-


write_sMAPES<-function(sMAPES,folder,name){

  saveRDS(sMAPES, file=paste0(folder,'/',name,"_sMAPES_.RData"))
}



#######################################################################################-

##This is for individual horizons
sMAPE_summary<-function(sMAPES,h){

  print(summary(sMAPES[[h-1]]))
  hist(sMAPES[[h-1]],main=paste('Horizon',h),xlab='sMAPE')
  ?hist

}


#######################################################################################-

summary_all_horizons<-function(sMAPES){

  mins<-sapply(sMAPES,function(x) min(x))
  means<-sapply(sMAPES,function(x) mean(x))
  medians<-sapply(sMAPES,function(x) median(x))
  maxes<-sapply(sMAPES,function(x) max(x))
  df<-data.frame('Horizon'=horizon,'Min'=mins,'Median'=medians,'Mean'=means,'Max'=maxes)
  print(df)


}

#read_in<-lapply(1:length(names_list), function(x) readRDS(paste0(folder_list[x],'/',names_list[x],".RData")))
#my_sums<-lapply(read_in,function(x) summary_all_horizons(x))


#######################################################################################-
names_list<-c("ARIMA_sMAPES_","HW_ADDI_sMAPES_","HW_MULTI_sMAPES_","MLP_sMAPES_")
folder_list<-c("sMAPES")

import_multiple_smapes<-function(names_list,folder_list){
  read_in<-lapply(1:length(names_list), function(x) readRDS(paste0(folder_list,'/',names_list[x],".RData")))

  my_sums <- lapply(read_in, function(x) {
    my_frame <- data.frame(Mean = numeric(), Median = numeric())
    lapply(x, function(i) {
      temp <- data.frame(Mean = mean(i), Median = median(i))

      ##Note the <<-, this pushes my_frame to the function import_multiple_smapes environment scope

      my_frame <<- rbind(my_frame, temp)

    })
    return(my_frame)
  })


#
#   for (i in seq_along(my_sums)) {
#     my_sums[[i]]$Method <- names_list[i]
#   }
#
#   merged_df <- do.call(rbind, my_sums)
  return(my_sums)
}

import_multiple_smapes(names_list,folder_list)

#######################################################################################-
#Call other files to maintain consistency

source('LSTM.R')
