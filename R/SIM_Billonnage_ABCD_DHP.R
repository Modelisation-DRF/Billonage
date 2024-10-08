#' Fonction prévoit la répartition par produits des arbres de 6 essences feuillus à l'aide des nouvelles
#' équations de Petro régionalisés ou celles de 2015.
#'
#' @param Data Un dataframe qui contient en ligne les arbres dont on veut prévoir
#'             les rendements en produit Petro.
#'             Le dataframe doit contenir une colonne bilonID qui numérote individuellement chacune des lignes.
#'             Doit aussi contenir les colonnes Espece et DHPcm
#'             Pour type=DHP et type=ABCD, il faut la colonne eco ou reg_eco
#'             Pour type=ABCD ou ABCD2015, il faut aussi une colonne ABCD
#'             Pour type=MSCR, il faut aussi une colonne MSCR
#'             Pour type=1234, il faut aussi les colonnes prod0 et vigu0
#'             Les équations ne s'appliquent qu'aux arbres avec un dhp>23, les autres seront supprimés
#'             Les équations ne s'appliquent qu'aux espèces: "ERS", "BOJ", "ERR", "BOP", "HEG", "CHR", les autres seront supprimés
#' @param type "DHP" pour utiliser les équations régionalisées basées seulement sur le DHP
#'             "ABCD" pour utiliser les équations régionalisées basées sur ABCD
#'             "1234" pour utiliser les équations de 2015 basées sur 1234
#'             "MSCR" pour utiliser les équations de 2015 basées sur MSCR
#'             "DHP2015" pour utiliser les équations de 2015 basées seulement sur le DHP
#'             "ABCD2015" pour utiliser les équations de 2015 basées sur ABCD
#' @return Retourne un dataframe avec l'estimation du volume par classe de produit
#'          pour chacun des arbres "ERS", "BOJ", "ERR", "BOP", "HEG", "CHR" pour Petro2015 et ERS/BOJ pour Petro2024
#' @examples
#' vol_billon <- SIMBillonnageABCD_DHP(Data=liste_arbres_ex, type="ABCD")
#' @export
#'

SIMBillonnageABCD_DHP<- function (Data , type){

  select=dplyr::select

  Data<- Data %>% filter(DHPcm >23) %>%
    mutate(type =NA)

  data<- Data %>% filter(Espece %in% c("ERS", "BOJ", "ERR", "BOP", "HEG", "CHR") )

  if (nrow(data) == 0) {

    Data<- Data %>% mutate(erreur = "Code d'essence \uE0 l'ext\uE9rieur de la plage de valeurs possibles pour billonage")

    return(Data)
  }

                          ##### ABCD#####
  if(!"eco" %in% colnames(data)){
    data <-ConvertisseurEco(data)
  }

  if (type %in% c("ABCD", "ABCD2015") && all(is.na(data$ABCD))) {
    type <- ifelse(type == "ABCD", "DHP", "DHP2015")
  }




  final <- data.frame()
  if(type %in% c("ABCD","DHP")){

    if(type == "ABCD"){
      # Séparer les arbres possédant la qualité ABCD des autres
     data_ABCD <- data %>% filter(!is.na(ABCD))
     data_pas_ABCD <-data %>% filter(is.na(ABCD))

     regional_ABCD <- data_ABCD %>% filter(Espece %in% c("ERS", "BOJ"))

     non_regional_2015_ABCD <- data_ABCD %>% filter(!Espece %in% c("ERS", "BOJ"))

     # Billonnage régionalisé pour les arbres possédant la qualité ABCD

     regional_result_ABCD <- data.frame()
     if (nrow(regional_ABCD) > 0) {
     regional_result_ABCD <-ABCD_DHP_regio(data=regional_ABCD, type ="ABCD" )
     }

     #Billonnage non régionalisé pour les arbres possédant la qualité ABCD

     non_regional_2015_result_ABCD <- data.frame()

     if (nrow(non_regional_2015_ABCD) > 0) {
     non_regional_2015_result_ABCD <- ABCD_DHP215(data=non_regional_2015_ABCD, type ="ABCD2015")
     }

     regional_pas_ABCD <- data_pas_ABCD %>% filter(Espece %in% c("ERS", "BOJ"))
     non_regional_2015_pas_ABCD <- data_pas_ABCD %>% filter(!Espece %in% c("ERS", "BOJ"))

     # Billonnage régionalisé pour les arbres ne  possédant pas la qualité ABCD
     # donc Billonage éffectuer avec DHP

     regional_result_pas_ABCD <- data.frame()

     if (nrow(regional_pas_ABCD) > 0) {
     regional_result_pas_ABCD <-ABCD_DHP_regio(data=regional_pas_ABCD, type ="DHP" )
     }

     # Billonnage non régionalisé pour les arbres ne  possédant pas la qualité ABCD
     # donc Billonage éffectuer avec DHP
     non_regional_2015_result_pas_ABCD<- data.frame()

     if (nrow(non_regional_2015_pas_ABCD) > 0) {
     non_regional_2015_result_pas_ABCD <- ABCD_DHP215(data=non_regional_2015_pas_ABCD, type ="DHP2015")
     }

     finl1 <-rbind(regional_result_ABCD,non_regional_2015_result_ABCD)
     finl2 <-rbind(regional_result_pas_ABCD,non_regional_2015_result_pas_ABCD)
     final <-rbind(finl2,finl1)

    }else{

    regional <- data %>% filter(Espece %in% c("ERS", "BOJ"))
    regional_result <- data.frame()

    if (nrow(regional) > 0) {
    regional_result <-ABCD_DHP_regio(data=regional, type =type )
    }

    non_regional_2015 <- data %>% filter(!Espece %in% c("ERS", "BOJ"))
    non_regional_2015_result <- data.frame()

    if (nrow(non_regional_2015) > 0) {
    non_regional_2015_result <- ABCD_DHP215(data=non_regional_2015, type ="DHP2015")
    }

    final <-rbind(regional_result,non_regional_2015_result)
   }
  }else{


    if(type=="ABCD2015"){

      data_ABCD <- data %>% filter(!is.na(ABCD))
      data_pas_ABCD <-data %>% filter(is.na(ABCD))

      final_ABCD<- data.frame()

      if (nrow(data_ABCD) > 0) {
      final_ABCD <- ABCD_DHP215(data=data_ABCD, type ="ABCD2015")
      }

      final_DHP <- data.frame()
      if (nrow(data_pas_ABCD) > 0) {
      final_DHP<- ABCD_DHP215(data=data_pas_ABCD, type ="DHP2015")
      }

      final<-rbind(final_ABCD,final_DHP)

    }else{

      final <- ABCD_DHP215(data=data, type =type)
    }


  }


  final<-final %>% select(DER,F1,F2,F3,F4,P,bilonID,type)


  return (final)


}
