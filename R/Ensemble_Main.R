#######################################################################################-
##Ensemble Main
#######################################################################################-
##Get names of all forecasts done so far regardless of model
#This allows you to add new ensemble names to the list of ensembles above
get_all_directory_forecasts()


ARIMA_FORECASTS<-readRDS(paste0('ARIMA_Forecasts','/',"ARIMA_CochraneOrc_forecast_1428",".RData"))

  ##VARS
    #Names of Folders

            ARIMA_Folder="ARIMA_Forecasts"
            HW_Folder='HW_Forecasts'
            LSTM_Folder="LSTM_Forecasts"
            MLP_Folder='MLP_Forecasts'
            CES_Folder='CES_Forecasts'
            ES_Folder='ES_Forecasts'
            Theta_Folder='Theta_Forecasts'
            DeepAR_Folder='DeepAR_Forecasts'
            #These are defined in Main as well, (crappy programming choice)

            ##These are the combinations of stat methods which will be randomly selected later:

            Stat_Folders<-c(ARIMA_Folder,HW_Folder,HW_Folder,ARIMA_Folder,CES_Folder,Theta_Folder,ES_Folder)
            Stat_Forecasts<-c("ARIMA_CochraneOrc_forecast_1428",'HW_ADDI_forecast_1428',
                              'HW_MULTI_forecast_1428','ARIMA_All_difference_forecast_1428',
                              'CES_forecast_1428','Theta_forecast_1428','ES_forecast_1428')


            DL_Folders<-c(MLP_Folder,DeepAR_Folder,LSTM_Folder)
            DL_Forecasts<-c('MLP_forecast_combined','DeepAR_forecast','LSTM_forecast')



            ##Creates all the different combinations of lists

            Num_ensembles=100

                stat_combos<-get_all_inx(up_to=length(Stat_Folders),how_many = Num_ensembles,replace_sample = FALSE)
                DL_combos<-get_all_inx(up_to=length(DL_Folders),min_combo = 1,how_many=Num_ensembles,replace_sample=TRUE)
                stat_index<-sapply(sample(1:length(stat_combos),size = Num_ensembles,replace=TRUE), function(x) x)
                DL_index<-sapply(sample(1:length(DL_combos),size = Num_ensembles,replace=TRUE), function(x) x)

                DL_final_combos<-sapply(DL_index,function(x) unlist(DL_combos[[x]]))
                Stat_final_combos<-sapply(stat_index,function(x) unlist(stat_combos[[x]]))

                List_of_List_of_DL_Folders<-sapply(DL_final_combos,function(x) DL_Folders[x])
                List_of_List_of_stat_Folders<-sapply(Stat_final_combos,function(x) Stat_Folders[x])

                List_of_List_of_DL_Fores<-sapply(DL_final_combos,function(x) DL_Forecasts[x])
                List_of_List_of_stat_Fores<-sapply(Stat_final_combos,function(x) Stat_Forecasts[x])

                Final_Folder_Lists<-sapply(1:Num_ensembles,function(x) c(List_of_List_of_DL_Folders[[x]],List_of_List_of_stat_Folders[[x]]))
                Final_Forecasts_Lists<-sapply(1:Num_ensembles,function(x) c(List_of_List_of_DL_Fores[[x]],List_of_List_of_stat_Fores[[x]]))


            ##

            horizon=2:18
            which_series=1:1428

          ##THESE ARE CHANGEABLE AND MUST LINE UP IE if ARIMA_Folder is first in list_of_folders, then an ARIMA Model must be first in List_of_ensembles

            # source('Functions.R')
            # source('Preprocess.R')
            #
            # List_of_Folders<- Final_Folder_Lists[[10]]
            # List_of_Ensembles<-Final_Forecasts_Lists[[10]]
            #
            # List_of_Folders<-c(ARIMA_Folder,HW_Folder,HW_Folder,ARIMA_Folder,CES_Folder,Theta_Folder,ES_Folder)
            # List_of_Ensembles<-c("ARIMA_CochraneOrc_forecast_1428",'HW_ADDI_forecast_1428',
            #                   'HW_MULTI_forecast_1428','ARIMA_All_difference_forecast_1428',
            #                   'CES_forecast_1428','Theta_forecast_1428','ES_forecast_1428')
start=Sys.time()
for(x in 1:100){


            List_of_Folders<-Final_Folder_Lists[[x]]
            List_of_Ensembles<-Final_Forecasts_Lists[[x]]



            # List_of_Folders<-c(HW_Folder,MLP_Folder)
            # List_of_Ensembles<-c('HW_ADDI_forecast_1428',"MLP_forecast_combined")
  ##RUNNERS

    ##Create ensembles!


            my_ensemble_mean<-get_ENSEMBLE(List_of_Folders,List_of_Ensembles,ensemble_type = 'mean')
            my_ensemble_median<-get_ENSEMBLE(List_of_Folders,List_of_Ensembles,ensemble_type='median')
            #my_ensemble_smape<-get_ENSEMBLE(List_of_Folders,List_of_Ensembles,ensemble_type='smape')

    ##Get sMAPES


            my_sMAPES_mean<-sMAPE_calculate(json_file,my_ensemble_mean)
            my_sMAPES_median<-sMAPE_calculate(json_file,my_ensemble_median)
           # my_sMAPES_smape<-sMAPE_calculate(json_file,my_ensemble_smape)

            summary_all_horizons(my_sMAPES_mean)
            summary_all_horizons(my_sMAPES_median)
            #summary_all_horizons(my_sMAPES_smape)

            write_sMAPES(my_sMAPES_mean,'ensemble_sMAPES_2',paste0('Ensemble_mean',x))
            write_sMAPES(my_sMAPES_median,'ensemble_sMAPES_2',paste0('Ensemble_median',x))
            message(x)
}

    ##WRITE

Sys.time()-start

saveRDS(Final_Forecasts_Lists, file="C:\\Users\\tavin\\OneDrive\\Desktop\\Capstone_git_main\\Capstone\\R\\ensemble_sMAPES_2\\ensemble_names.RData")

Final_Forecasts_Lists



#######################################################################################-
##Functions
#######################################################################################-
  #Create indexes of all possible combinations

            get_all_inx<-function(up_to=7,min_combo=2,how_many=10,replace_sample=FALSE){
              numbers <- up_to

              all_combinations <- list()


              for (length in min_combo:numbers) {
                combinations <- combn(numbers, length)
                num_combinations <- ncol(combinations)
                for (i in 1:num_combinations) {
                  all_combinations <- c(all_combinations, list(combinations[, i]))
                }
              }
              return(all_combinations)

            }


  #######################################################################################-


    get_ENSEMBLE<-function(List_of_Folders,List_of_Ensembles,ensemble_type='mean'){

          ##CREATE Ensemble Environment

                 ##CREATE TEMP LISTS OF EACH FORECAST BASED ON HOW MANY YOU WANNA ENSEMBLE

                for (i in seq_along(List_of_Folders)) {

                  var_name <- paste0("ensemble_", i)
                  assign(var_name, read_forecasts(List_of_Folders[i],List_of_Ensembles[i]))
                }

                num_horizons=length(ensemble_1)
                num_series=length(ensemble_1[[1]])

                ###################################################

                ##PRE-ASSIGN Size of list for memory allocation reasons

                ensemble_sum<-vector('list',length=num_horizons)

                ensemble_sum <- lapply(ensemble_sum, function(x) {
                  vector("list", length = num_series)
                })

                ensemble_sum <- lapply(ensemble_sum, function(x) {
                  lapply(x, function(y) {
                    list(forecasts = NULL)
                  })
                })



         ###################################################
          ##Get lambda functions for making ensembles between forecasts

                 lambda_functions <- ensemble_lambda(ensemble_type)

                 ##Depending on the ensemble type, this generally pre-processes the forecasts
                 lambda_forecast_sum<-lambda_functions$lambda_forecast_sum

                 ##This is where the magic happens.  Will get appropriate ensembled forecast i.e. mean,median smape...
                 lamdba_forecast_ens <- lambda_functions$lamdba_forecast_ens

          ###################################################
          ## Make the ensemble!

           for(j in 1:num_horizons){
             for(k in 1:num_series){

               ##These IFS allow the variable that holds the combined forecasts to be flexible based on method

               if(ensemble_type=='mean'){
                 forecast_sum<-0
               } else if(ensemble_type=='median'){
                 forecast_sum<-NULL
               } else if(ensemble_type=='smape'){
                 forecast_sum<-0
               }

               ##Tavin add in here when you get gback from the park
               ##This section will be for sMAPE only
               ##it is going to calculate your sMAPE weights
               ##
               ##Only used for sMAPE ensemble weighting
               ens_smape_weight<-NULL
               if(ensemble_type=='smape'){

                 weights_summary<-NULL

                 for(l in seq_along(List_of_Folders)){
                   var_name <- paste0("ensemble_", l)
                   ensemble <- get(var_name)
                   ensemble<-sMAPE_calculate_step(json_file,ensemble,j,k)
                   weights_summary<-rbind(weights_summary,ensemble)
                 }

                 ##This is added to correct for division by 0 instances
                 weights_summary<-weights_summary+.000001
                 bounded_inverse<-1/weights_summary
                 bounded_inverse
                 bounded_inverse_sum<-colSums(bounded_inverse)
                 ens_smape_weight <- t(t(bounded_inverse) / bounded_inverse_sum)
               }




               ##The section below will stay the same i think

               for(l in seq_along(List_of_Folders)){
                 var_name <- paste0("ensemble_", l)
                 ensemble <- get(var_name)

                 forecast_sum <- lambda_forecast_sum(forecast_sum, ensemble, j, k,l, ens_smape_weight)
               }

               ensemble_sum[[j]][[k]]$forecasts<-lamdba_forecast_ens(forecast_sum)
             }
           }

      return(ensemble_sum)
    }



    ##this will be lambda_forecast_ense
    ensemble_1[[j]][[k]]$forecasts*ens_smape_weight[1,]+
      ensemble_2[[j]][[k]]$forecasts*ens_smape_weight[2,]+
      ensemble_3[[j]][[k]]$forecasts*ens_smape_weight[3,]

  #######################################################################################-

  #######################################################################################-

    ##These functions are called by the ensembler...they are used in the final compilation of the ensembler.

    sMAPE_calculate_step<-function(json_file,forecast_object,j,k){

      fiz=json_file[[k]]
      forecast_object=forecast_object[[j]][[k]]

      targets<-fiz$target[(length(fiz$target)-j):length(fiz$target)]

      fores<-forecast_object$forecasts

      ##NOTE THIS CALCULATES INDIVIDUAL SMAPE, THE AVERAGE OF THESE VALUES WILL NOT EQUAL THE OVERALL EVALUATED SMAPE. N PARAMETERS IS ADJUSTED TO JUST 1
      sMAPE<-sapply(1:length(targets),function(ind) (2*sum((abs(targets[[ind]]-fores[[ind]])/(abs(targets[[ind]])+abs(fores[[ind]])))*100)))

      return(sMAPE)

    }

    ##Get names of all forecasts done so far regardless of model

    get_all_directory_forecasts<-function(){
      dir(dir()[grep('Forecasts',dir())])
    }


  #######################################################################################-

  #######################################################################################-

    ##These functions are called by the ensembler...they are used in the final compilation of the ensembler.




    ensemble_lambda <- function(ensemble_type, num_horizons, num_series) {

      lambda_forecast_sum <- NULL
      lamdba_forecast_ens <- NULL

      if (ensemble_type == 'mean') {

        lamdba_forecast_ens <- function(fore) {
          return(fore/length(List_of_Folders))
        }

        lambda_forecast_sum <- function(prev, current, j, k,l,ens_smape_weight) {
          return(prev + current[[j]][[k]]$forecasts)
        }

      } else if (ensemble_type == 'median') {

        lamdba_forecast_ens <- function(fore) {
          return(apply(fore, MARGIN = 2, median))
        }

        lambda_forecast_sum <- function(prev, current, j, k,l,ens_smape_weight) {
          return(rbind(prev, current[[j]][[k]]$forecasts))
        }

      } else if (ensemble_type == 'smape') {

        # lambda_weights_sum <- function(prev, current) {
        #   return(rbind(prev, sMAPE_calculate_step(json_file, current)))
        # }

        ## These need adjusted still
        lamdba_forecast_ens <- function(fore) {
          return(fore)
        }

        lambda_forecast_sum <- function(prev, current, j, k,l, ens_smape_weight) {
          return(prev + current[[j]][[k]]$forecasts * ens_smape_weight[l,])
        }
      }

      ## combine into list of functions
      lambda_list <- list(lambda_forecast_sum = lambda_forecast_sum,
                          lamdba_forecast_ens = lamdba_forecast_ens)

      return(lambda_list)
    }
