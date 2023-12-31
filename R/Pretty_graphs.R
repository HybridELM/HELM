##THIS SECTION NEEDS WORK, BUT IS ARGUABLY NOT IMPORTANT YET.. MOST OF THE CODE IS JUST SHOTGUN STYLE AT THE MOMENT.

###
library(tidyr)
library(tableHTML)
library(flextable)


##For getting ensembles
    folder_list<-c("ensemble_sMAPES_2")
    names_list<-dir("ensemble_sMAPES_2")[grep("sMAPES",dir("ensemble_sMAPES_2"))]
    names_list<-gsub(".RData","",names_list)
    names_list<-names_list[order(x,decreasing=FALSE)[1:4]]
    names_list<-names_list[c(1,4,2,3)]
    #my_method <- as.character(1:200)  # Length is set to 2 * 100
    my_method<-c("Ensemble 1","Ensemble 2 ","Ensemble 3","Ensemble 4")

    my_sMAPES<-import_multiple_smapes(names_list,folder_list)
    all_metrics <- data.frame(Name = character(), Horizon = integer(), Type = character(), Value = numeric())

##





##For all single methods at a time

    names_list<-c("ARIMA_sMAPES_","ARIMA_CochraneOrc_forecast_1428_sMAPES_","HW_ADDI_sMAPES_","HW_MULTI_sMAPES_",'Theta_forecast_1428_sMAPES_','CES_forecast_1428_sMAPES_',
                  'ES_forecast_1428_sMAPES_',
                  "MLP_sMAPES_",'DeepAR_forecast_sMAPES_','LSTM_forecast_sMAPES_')
    folder_list<-c("sMAPES")
    my_method <- c("ARIMA Differenced", "ARIMA Cochrane", "HW Add","HW Multi","Theta",'CES','ES',"MLP","DeepAR","LSTM")
    my_sMAPES<-import_multiple_smapes(names_list,folder_list)

##


##


##For best single methods and ensembles at a time

      names_list<-c("ARIMA_sMAPES_",'Theta_forecast_1428_sMAPES_','CES_forecast_1428_sMAPES_',
                    'Ensemble_median76_sMAPES_','Ensemble_mean76_sMAPES_','Ensemble_median1_sMAPES_','Ensemble_mean1_sMAPES_')
      folder_list<-c("sMAPES")
      my_method <- c("ARIMA Differenced","Theta",'CES','Ensemble 1','Ensemble 2','Ensemble 3','Ensemble 4')
      my_sMAPES<-import_multiple_smapes(names_list,folder_list)

##################################################################################

##This formats everything for the table..This is for the MEAN

all_metrics <- data.frame(Name = character(), Horizon = integer(), Type = character(), Value = numeric())


sapply(1:length(my_method), function(x) {
  temp <- data.frame(Mean = my_sMAPES[[x]]$Mean, Median = my_sMAPES[[x]]$Median, Horizon = 2:18)
  temp_long <- gather(temp, key = "Type", value = "Value", Mean, Median)
  temp_long$Name <- my_method[x]
  all_metrics <<- rbind(all_metrics, temp_long)
})


temp<-all_metrics%>%pivot_wider(names_from=Name,values_from=Value)
temp_mean<-temp[temp$Type=='Mean',]
temp_mean<-temp_mean[,-2]
temp_mean<-t(temp_mean)
nem<-c('2','3','4','5',"6",'7','8','9','10','11','12','13','14','15','16','17','18')
nem<-as.character(nem)
temp_mean<-as.data.frame(temp_mean)
temp_mean<-round(temp_mean,digits=2)
names(temp_mean)<-nem
temp_mean<-temp_mean[-1,]
temp_mean$Horizon<-row.names(temp_mean)
temp_mean<-temp_mean[,c(18,1:17)]

##Gets minimum values for highlighting
min_vals <- apply(temp_mean[,-1], 2, min)


tableHTML(temp_mean,rownames = FALSE,widths = c(200,rep(100,17)),collapse = 'separate',spacing = '3px',
          border = 0 ,second_headers=list(18,c('Mean sMAPE Values on Horizons 2-18')))%>%
  add_css_conditional_column(conditional = 'min',
                             same_scale=FALSE,
                             css = list('border', '5px solid #CD7F32'),
                             columns =2:(length(temp_mean)))%>%  add_css_row(css = list(c( 'font-size', 'text-align','height'), c( '20px', 'center','50px')))%>%
  add_css_row(css = list('background-color', '#f2f2f2'),
              rows = odd(3:13))%>%
  add_css_column(css=list(c('font-weight','padding-right'),c('bold','20px')),columns = 1)%>%
  #add_css_caption(css =list(c('border-collapse','border-spacing'),c('separate','15px')))%>%
  add_css_header(css = list( c('height','border-bottom','background-color','color','font-size'), c('10px','5px solid steelblue','steelblue','white','30px')),headers = 1:19)


tableHTML::write_tableHTML(table,"C:\\Users\\tavin\\OneDrive\\Desktop\\Capstone_git_main\\Capstone\\R\\100_ensembles_2.html")
render_tableHTML(table)
#############################################################



tableHTML(temp_mean,rownames = FALSE,widths = c(60,rep(100,17)),
          border = 2 ,second_headers=list(18,c('Mean sMAPE Values on Horizons 2-18')))%>%
  add_css_conditional_column(conditional = 'min',
                             same_scale=FALSE,
                             css = list('border', '5px solid #CD7F32'),
                             columns =2:(length(temp_mean))) %>%
  add_css_row(css = list(c( 'font-size', 'text-align'), c( '35px', 'center')))%>%
  add_css_row(css = list('background-color', '#f2f2f2'),
              rows = odd(3:5))%>%
  # add_css_header(css = list(c('transform', 'height'),
  #                           c('rotate(-25deg)', '50px')),
  #                headers = 2:19)
  add_css_header(css = list( c('height','border-bottom-width'), c('100px','8px')),
                 headers = 2:19)%>%
  add_css_second_header(css=list('height','100px'),second_headers = 1:19)

############################################################################################

temp<-all_metrics%>%pivot_wider(names_from=Name,values_from=Value)
temp_mean<-temp[temp$Type=='Median',]
temp_mean<-temp_mean[,-2]
temp_mean<-t(temp_mean)
nem<-c('2','3','4','5',"6",'7','8','9','10','11','12','13','14','15','16','17','18')
nem<-as.character(nem)
temp_mean<-as.data.frame(temp_mean)
temp_mean<-round(temp_mean,digits=2)
names(temp_mean)<-nem
temp_mean<-temp_mean[-1,]
temp_mean$Horizon<-row.names(temp_mean)
temp_mean<-temp_mean[,c(18,1:17)]


table<-tableHTML(temp_mean,widths = rep(100,18),spacing = '3px',second_headers=list(18,c('Median sMAPE Values on Horizons 2-18')),rownames = FALSE)%>%
  add_css_row(css = list(c( 'font-size', 'text-align'), c( '35px', 'center')))%>%
  add_css_conditional_column(conditional = 'min',
                             same_scale=FALSE,
                             css = list('border', '5px solid #CD7F32'),
                             columns =2:(length(temp_mean)))%>%
  add_css_header(css = list(c('transform', 'height'),
                            c('rotate(-25deg)', '50px')),
                 headers = 2:19) %>%
  add_css_row(css = list('background-color', '#f2f2f2'),
              rows = odd(3:5))
render_tableHTML(table)

###
library(ggplot2)
library(ggthemes)

le_group=interaction(all_metrics$Name[all_metrics$Type=='Mean',],all_metrics$Type[all_metrics$Type=='Mean',])

all_metrics[all_metrics$Type=='Mean',]%>% ggplot(aes(x=Horizon,y=Value,color=Name))+geom_line(size=1.2)+
  ylab("sMAPE")+theme_clean()+theme(axis.title = element_text(face="bold"),axis.text = element_text(face="bold"))+
  ggtitle("Horizon vs sMAPE")+theme(plot.title = element_text(hjust=.5))+scale_color_manual(name = "Measure and Model",values=palette)

palette<-c("#00CD66", "#CD3278", "#36648B", "#CDAD00", "#CD7F32", "#BA55D3")
palette<-c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f",
           "#bcbd22", "#17becf", "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", "#c49c94")

all_metrics[all_metrics$Type=='Mean',]%>% ggplot(aes(x=Horizon,y=Value,color=Name))+geom_line(size=1.2)+
  ylab("sMAPE")+theme_clean()+theme(axis.title = element_text(face="bold"),axis.text = element_text(face="bold"))+
  ggtitle("Top Ensembles and Single Method: Horizon vs sMAPE")+theme(plot.title = element_text(hjust=.5))+scale_color_manual(name = "Ensemble Key",values=palette)


### Get domain of each forecast

    name='Ensemble_median76_sMAPES_'
    folder = 'ensemble_sMAPES_2'
    Monthly_Domains <- read.csv("C:/Users/tavin/OneDrive/Desktop/Capstone_git_main/Capstone/R/Monthly_Domains.csv")
    domain_array<-rep(Monthly_Domains$Category,17)
    domain_array<-gsub(" ","",domain_array)
    my_sMAPES<-readRDS('ensemble_sMAPES_2/Ensemble_median76_sMAPES_.RData')

    my_forecasts<-read_forecasts(folder = folder,name = name)


    my_sMAPES<-sMAPE_calculate(json_file,my_forecasts)

    unlist_smapes<-data.frame(unlist(my_sMAPES))

    #domain_forecasts
    domain_forecasts<-cbind(unlist_smapes,domain_array)

    repeats <- c()

    for (i in 2:18) {
      repeats <- c(repeats, rep(i, 1428))
    }

    domain_forecasts$Horizon=repeats

    names(domain_forecasts)<-c("sMAPES","Domain","Horizon")
    names(domain_forecasts)


    mean_data_ARIMA <- domain_forecasts %>%
      group_by(Domain, Horizon) %>%
      summarize(mean_sMAPES = mean(`sMAPES`))

    # Plotting the mean MLP sMAPES against the Horizon, separated by Domai
library(ggplot2)
    library(ggthemes)
    mean_data_ARIMA%>% ggplot(aes(x=Horizon,y=mean_sMAPES,color=Domain))+geom_line(size=1.2)+
      ylab("sMAPE")+theme_clean()+theme(axis.title = element_text(face="bold"),axis.text = element_text(face="bold"))+
      ggtitle("ARIMA sMAPES by Domain")+theme(plot.title = element_text(hjust=.5))
    #+scale_color_manual(name = "Measure and Model",values=palette)


install.packages('gridExtra')
    library(gridExtra)
grob1<-ggplotGrob(mean_data_ARIMA)
grob2<-ggplotGrob(mean_data_ces)
grob3<-ggplotGrob(mean_data_DeepAR)
grob4<-ggplotGrob(mean_data_Theta)
combined_plot <- grid.arrange(mean_data_ARIMA, mean_data_ces, mean_data_DeepAR, mean_data_Theta, nrow = 2, ncol = 2)



    palette<-c("#00CD66", "#CD3278", "#36648B", "#CDAD00", "#CD7F32", "#BA55D3")
    palette<-c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f",
               "#bcbd22", "#17becf", "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", "#c49c94")

    all_metrics[all_metrics$Type=='Mean',]%>% ggplot(aes(x=Horizon,y=Value,color=Name))+geom_line(size=1.2)+
      ylab("sMAPE")+theme_clean()+theme(axis.title = element_text(face="bold"),axis.text = element_text(face="bold"))+
      ggtitle("Horizon vs sMAPE")+theme(plot.title = element_text(hjust=.5))+scale_color_manual(name = "Measure and Model",values=palette)
