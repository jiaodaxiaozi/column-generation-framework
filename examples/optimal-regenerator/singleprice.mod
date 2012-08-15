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
	
	setNextModel("MULTIPRICE");
		
}

dvar  float+ thecost ;

dvar  int+ a[ BITRATE ][ SINGLEHOP_SET ] in 0..1;
dvar  float+ pcost[ BITRATE ][ SINGLEHOP_SET ];

minimize      thecost - sum ( b in BITRATE , vi in NODESET , vj in NODESET)  
							dual_provide[ b ][ vi ][ vj ] * ( sum( p in SINGLEHOP_SET : p.src == vi.id && p.dst == vj.id ) a[b][p]   )  ;			

subject to {

	// disjoint lightpath
	forall ( l in DIRECTED_EDGESET )
		sum( b in BITRATE , p in SINGLEHOP_SET , lp in SINGLEHOP_EDGESET : lp.indexPath == p.index && lp.indexEdge == ord( DIRECTED_EDGESET , l )  ) 
			a[b][p] <= 1 ;

	// cost per path
    forall( b in BITRATE , p in SINGLEHOP_SET )
    // if MTD 750
    if  ( p.pathLength <=750 )
    		pcost[b][p] == a[b][p] * REGENERATOR_COST[ b ][ 750 ];
	// if MTD 1500	    	
    else if ( p.pathLength <= 1500 )
    		pcost[b][p] == a[b][p] * REGENERATOR_COST[ b ][ 1500 ];
	// if MTD 3000    	
	else if ( p.pathLength <= 3000 )    	
			pcost[b][p] == a[b][p] * REGENERATOR_COST[ b ][ 3000 ];
	// not accept length is more than 3000		
	else	{
				a[b][p] == 0;
				pcost[b][p] == 0;	
			}	

	thecost == sum( b in BITRATE , p in SINGLEHOP_SET ) pcost[ b ][ p ];
} 

/********************************************** 

	POST PROCESSING
	
 *********************************************/

execute {
	
	
	writeln("Price Objective : " , cplex.getObjValue() , " Cost : " , thecost.solutionValue );  
		
	var newindex = WAVELENGTH_CONFIGINDEX.size ;
	writeln("New Index : " , newindex )
	FINISH_RELAX_FLAG.add( 1 );
	

	// add new wavelength configuration
	WAVELENGTH_CONFIGINDEX.addOnly( newindex , thecost.solutionValue );

	for ( var b in BITRATE)
		for ( var p in SINGLEHOP_SET)
			if ( a [ b ][ p ].solutionValue > 0.5 )
	 			WAVELENGTH_CONFIGSET.addOnly( newindex , p.index , b );

	
}  

  
