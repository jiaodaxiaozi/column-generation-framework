/****************************************************************************
 * COLUMN GENERATION - SINGLE HOP WAVELENGTH CONFIGURATION PRICING PROBLEM
 *
 * Author: Hoang Hai Anh
 * Email : hoanghaianh@gmail.com
 *
 ****************************************************************************/

include "params.mod";



execute {

	writeln("SOLVING SINGLE PRICE");
	

	// CPLEX settings for PRICING
	
	cplex.intsollim = 1; // take only one solution
	cplex.cutup = 	-0.01 ; // reduced cost 		
	cplex.parallelmode = -1 ; // opportunistic mode
	cplex.threads = 0 ; // use maximum threads
	
	
		
}

dvar  float+ thecost ;

dvar  int+ a[ BITRATE ][ SINGLEHOP_SET ] in 0..1;

minimize      thecost - sum ( b in BITRATE , vi in NODESET , vj in NODESET)  
							dual_provide[ b ][ vi ][ vj ] * ( sum( p in SINGLEHOP_SET : p.src == vi.id && p.dst == vj.id ) a[b][p]   )  ;			

subject to {

	// disjoint lightpath
	forall ( l in DIRECTED_EDGESET )
		sum( b in BITRATE , p in SINGLEHOP_SET , lp in SINGLEHOP_EDGESET : lp.indexPath == p.index && lp.indexEdge == ord( DIRECTED_EDGESET , l )  ) 
			a[b][p] <= 1 ;

} 

/********************************************** 

	POST PROCESSING
	
 *********************************************/

execute {
	
	
	writeln("Price Objective : " , cplex.getObjValue()  );  
		
	
	
}  

  
