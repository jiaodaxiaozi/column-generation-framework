/*********************************************
 * COLUMN GENERATION - PRICING PROBLEM
 *
 * Author: Hoang Hai Anh
 * Email : hoanghaianh@gmail.com
 *
 *********************************************/

include "params.mod";



execute {

	// CPLEX settings for PRICING
	
	cplex.intsollim = 1; // take only one solution
	cplex.cutup = 	-0.01 ; // reduced cost 		
	cplex.parallelmode = -1 ; // opportunistic mode
	cplex.threads = 0 ; // use maximum threads
	
	
	
}

dvar  int+ x[ 1..nitem ] ;

minimize      1 - sum ( i in 1..nitem  ) dual_demand[ i ] * x[ i ] ;			

subject to {

	sum( i in 1..nitem ) x[ i ] * item_size[ i ] <= W ;

} 

/********************************************** 

	POST PROCESSING
	
 *********************************************/

execute {
	
	
	writeln("Price Objective : " , cplex.getObjValue()  );  
		
	// add new column
	patternset.addOnly( x.solutionValue );
		
	
	setNextModel( "START" );
	
	
}  

  
