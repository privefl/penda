#'DU_rearrangement
#'
#' This function reorganizes matrices resulting from the multiple test. It takes a
#' "DUDUDUDU" matrix and make two independant D and U matrices.
#'
#'@param multiple_tests The results matrix, which has a form of "DUDUDUDU".
#'@param simu_data The matrix of initial_data or simulated_data in the simulation, used for dimnames.
#'@param multiple_values The vector with different values of the test.
#'
#'@return This function returns a list of two logical matrices. The D matrix with TRUE
#'for genes down-regulated, and the U matrix with TRUE for genes up-regulated.
#'
#'@examples
#'D_U = find_D_U_ctrl(ctrl_data, quant = 0.001, factor = 4, threshold = 0.99)
#'simulation = simplified_simulation(simu_data, fraction = 0.3, threshold = 60)
#'multiple_values = c(0.01, 0.02, 0.03)
#'multiple_test = sapply(multiple_values, function(value){
#'  sample_test(ctrl_data, simulated_data, quant_0 = 0.03, iterations = 10, D_U, threshold = value)
#'})
#'sorted_matrix = DU_rearrangement(multiple_test, simulation$initial_data, multiple_values)

DU_rearrangement = function(multiple_tests, simu_data, multiple_values){

  #Definition of D and U matrices for all the conditions
  D_simu = matrix(data = NA, nrow = length(simu_data)
                  , ncol = length(multiple_values)
                  , dimnames = list(names(simu_data), multiple_values))
  U_simu = matrix(data = NA, nrow = length(simu_data)
                  , ncol = length(multiple_values)
                  , dimnames = list(names(simu_data), multiple_values))

  #D and U are put in the matrices for all the conditions
  for (r in 1:length(multiple_values)){
    D_simu[,r] = unlist(multiple_tests[(r*2-1)])
    U_simu[,r] = unlist(multiple_tests[r*2])
  }
  return(list(D = D_simu, U = U_simu))
}


#'test_multiple_thresholds
#'
#' This function makes patient_test for different values of the threshold.
#'
#'@param ctrl_data A matrix with genes expressions in controls for all the patients.
#'@param D_U_ctrl The list of Down and Up-expressed genes matrices in the control.
#'@param simulation The list of initial data $initial_data and modified data in $simulated_data
#'@param threshold_values The vector of values of the threshold for regulation_test.
#'@param iterations The maximal number of iterations for the test. If the dysregulation list
#'no longer changes, iterations are stop before.
#'@param quant_test The quantile for the test. When D and U lists are void, we use the naive method.
#'@param factor_test The factor for the test. The limit D will be quant(gene)/factor, and the limit U quant(gene)*factor.
#'
#'@return This function returns a list of two logical matrices. The D matrix with for each threshold
#'TRUE for genes down-regulated, and the U matrix with TRUE for genes up-regulated.
#'
#'@examples
#'D_U = find_D_U_ctrl(ctrl_data, quant = 0.001, factor = 4, threshold = 0.99)
#'simulation = simplified_simulation(simu_data, fraction = 0.3, threshold = 60)
#'multiple_values = c(0.01, 0.02, 0.03)
#'test_threshold = test_multiple_thresholds(ctrl_data, D_U, simulation, threshold_values = multiple_values, iterations = 10, quant_test = 0, factor_test = 1)
#'
#'@export

test_multiple_thresholds = function(ctrl_data, D_U_ctrl, simulation, threshold_values, iterations, quant_test = 0, factor_test = 1){
  #Test for all threshold values
  multiple_test = sapply(threshold_values, function(t){
    print(c("Threshold",t))
    sample_test(simulation$simulated_data, ctrl_data, iterations, D_U_ctrl, t, quant_test, factor_test)
  })
  sorted_test = DU_rearrangement(multiple_test, simulation$initial_data, threshold_values )
  return (sorted_test)
}


#'choose_threshold
#'
#' This function makes for each patient the test with multiple values for the treshold.
#' After that, it computes FDR and TPR, and print the threshold closest of your goal FDR.
#'
#'@param ctrl_data A matrix with genes expressions in controls for all the patients.
#'@param D_U_ctrl The list of Down and Up-expressed genes matrices in the control.
#'@param iterations The maximal number of iterations for the test. If the dysregulation list
#'no longer changes, iterations are stop before.
#'@param simulation The list of initial data $initial_data and modified data in $simulated_data
#'@param threshold_values A vector with different values to test for the threshold.
#'@param FDR_goal The FDR you would like for this test.
#'@param quant_test The quantile for the test. When D and U lists are void, we use the naive method.
#'@param factor_test The factor for the test. The limit D will be quant(gene)/factor, and the limit U quant(gene)*factor.
#'
#'@return This function returns a matrix with 4 columns : the patient number, the value of the threshold tested,
#'the FDR and the TPR of the test.
#'
#'@example
#'D_U = find_D_U_ctrl(ctrl_data, quant = 0.001, factor = 4, threshold = 0.99)
#'simulation = simplified_simulation(simu_data, fraction = 0.3, threshold = 60)
#'threshold_values = c(0.003, 0.1, 0.2, 0.3, 0.5)
#'which_threshold = choose_threshold(ctrl_data, D_U, iterations = 10, simulation, threshold_values, FDR_goal = 0.06)
#'
#'@export

choose_threshold = function(ctrl_data, D_U_ctrl, iterations, simulation, threshold_values, FDR_goal = 0.06, quant_test = 0, factor_test = 1){
  results = c()
  #For each patient
  for(p in 1:ncol(simulation$initial_data)){
    print(c("Patient number",p))
    simulation_p = list(initial_data = simulation$initial_data[,p], simulated_data = simulation$simulated_data[,p])

    #The test is made for all the values of threshold
    test = test_multiple_thresholds(ctrl_data, D_U_ctrl, simulation_p, threshold_values, iterations, quant_test, factor_test)

    #For each value,
    for(value in 1:ncol(test$D)){
      #Computing of FP, TP, FN, TN
      results_simu = results_simulation(test$D[,value], test$U[,value], simulation_p)
      #Computing of FDR and TPR
      FDR = results_simu$FP / (results_simu$TP + results_simu$FP)
      TPR  = results_simu$TP / (results_simu$TP + results_simu$FN)
      FPR = results_simu$FP / (results_simu$TN + results_simu$FP)
      results = rbind(results, c(p, colnames(test$D)[value], FDR, TPR, FPR))
    }
  }

  #Search the FDR goal
  median_t = c()
  for (value in 1:length(threshold_values)){
    threshold = threshold_values[value]
    FDRt = as.numeric(results[results[,2] == threshold & !is.na(results[,3]), 3])
    median_t = rbind(median_t, c(threshold, median(FDRt)))
  }
  small_FDR = median_t[median_t[,2] <= FDR_goal,]
  if(length(small_FDR) !=0){
    #If only one FDR under the FDR goal
    if (is.vector(small_FDR)){
      print ("The threshold closest to the FDR is")
      print (small_FDR[1])
      print("Which has a median FDR of")
      print(small_FDR[2])
    #If more than one FDR under the FDR goal
    } else {
      idx = which(small_FDR[,2] == max(small_FDR[,2]))
      print ("The threshold closest to the FDR is")
      print (small_FDR[idx, 1])
      print("Which has a median FDR of")
      print(small_FDR[idx, 2])
    }
  } else {
    print ("Your FDR is not reachable, check the results table to choose your threshold.")
  }
  colnames(results) = c("patient", "threshold", "FDR", "TPR", "FPR")
  return(results)
}


#'choose_quantile
#'
#' This function makes for each patient the naive test with multiple values for the quantile.
#' After that, it computes FDR and TPR, and print the quantile closest of your goal FDR.
#'
#'@param ctrl_data A matrix with genes expressions in controls for all the patients.
#'@param simulation The list of initial data $initial_data and modified data in $simulated_data
#'@param FDR_goal The FDR you would like for this test.
#'@param factor The factor for the test The D limit will be quantmin/factor, and the U limit quantmax*factor.
#'@param quantile_values A vector with different values to test for the quantile.
#'
#'@return This function returns a matrix with 3 columns : the value of the quantile tested,
#'the FDR and the TPR of the test.
#'
#'@examples
#'simulation = simplified_simulation(simu_data, fraction = 0.3, threshold = 60)
#'which_quantile = choose_quantile(ctrl_data, simulation, FDR_goal = 0.06)
#'
#'@export

choose_quantile = function(ctrl_data, simulation, FDR_goal, factor = 1.4, quantile_values = c(0.005, 0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1, 0.2)){
  results = c()

  print ("Computing results")
  for (q in 1:length(quantile_values)){
    test = naive_test(ctrl_data, simulation$simulated_data, quantile_values[q], factor)
    results_simu = results_simulation(test$D, test$U, simulation)

    FDR = results_simu$FP / (results_simu$TP + results_simu$FP)
    TPR  = results_simu$TP / (results_simu$TP + results_simu$FN)
    FPR = results_simu$FP / (results_simu$TN + results_simu$FP)
    results = rbind(results, c(quantile_values[q], FDR, TPR, FPR))
  }

  small_FDR = results[results[,2] <= FDR_goal & !is.na(results[,2]) ,]
  if(length(small_FDR) !=0){
    if (is.vector(small_FDR)){
      print ("The quantile closest to the FDR for this factor is")
      print (small_FDR[1])
      print("Which has a FDR for the naive method of")
      print(small_FDR[2])
    } else {
      idx = which(small_FDR[,2] == max(small_FDR[,2]))
      print ("The quantile closest to the FDR for this factor is")
      print (small_FDR[idx, 1])
      print("Which has a FDR for the naive method of")
      print(small_FDR[idx, 2])
    }
  } else {
    print ("Your FDR is not reachable, check the results table to choose your quantile.")
  }
  colnames(results) = c("quantile", "FDR", "TPR", "FPR")
  return(results)
}

