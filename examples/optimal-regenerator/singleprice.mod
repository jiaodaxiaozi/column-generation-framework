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
	cplex.cutup = 	-0.001 ; // reduced cost 		
	cplex.parallelmode = -1 ; // opportunistic mode
	cplex.threads = 0 ; // use maximum threads
	
	setNextModel("MULTIPRICE");
		
}

dvar  float+ thecost ;

dvar  int+ a[ BITRATE ][ SINGLEHOP_SET ] in 0..1;
dvar  float+ pcost[ BITRATE ][ SINGLEHOP_SET ];
dvar  int+ d[ NODESET ] ;
dvar  int+ select[ DIRECTED_EDGESET ] in 0..1 ;

minimize      thecost - dual_wave[0] 

                      - sum ( v in NODESET ) dual_slot[ v ] * d[ v ]  

                      - sum ( b in BITRATE , vi in NODESET , vj in NODESET)  
							dual_provide[ b ][ vi ][ vj ] * ( sum( p in SINGLEHOP_SET : p.src == vi.id && p.dst == vj.id ) a[b][p]   )  ;			


subject to {


    

	// disjoint lightpath
	forall ( l in DIRECTED_EDGESET )
		sum( b in BITRATE , p in SINGLEHOP_SET , lp in SINGLEHOP_EDGESET : lp.indexPath == p.index && lp.indexEdge == ord( DIRECTED_EDGESET , l )  ) 
			a[b][p] == select[ l ] ;


    forall( v in NODESET )
        d[ v ] == sum( l in DIRECTED_EDGESET : l.src == v.id || l.dst == v.id ) select[ l ] ;

	// cost per path
    forall( b in BITRATE , p in SINGLEHOP_SET )
    		pcost[b][p] == a[b][p] * REGENERATOR_COST[ b ][ p.reach ];

	thecost == sum( b in BITRATE , p in SINGLEHOP_SET ) pcost[ b ][ p ];
} 


float cost[ b in BITRATE ][ tr in TRSET ] = sum( p in SINGLEHOP_SET : p.reach == tr ) pcost[b][p] ; 
int   count[ b in BITRATE ][ tr in TRSET ] = sum( p in SINGLEHOP_SET : p.reach == tr ) a[b][p] ; 


/********************************************** 

	POST PROCESSING
	
 *********************************************/

execute {
	
	
	writeln("Price Objective : " , cplex.getObjValue() , " Cost : " , thecost.solutionValue );  
		
	var newindex = WAVELENGTH_CONFIGINDEX.size ;
	writeln("New Index : " , newindex )
	FINISH_RELAX_FLAG.add( 1 );


    for ( var v in NODESET )
    if ( d[v].solutionValue > 0.5 )
        SINGLEHOP_DEGREESET.addOnly( newindex , v.id , d[v].solutionValue );	

	// add new wavelength configuration
	WAVELENGTH_CONFIGINDEX.addOnly( newindex , thecost.solutionValue );

    var b , tr ;

    for ( b in BITRATE )
    for ( tr in TRSET  )
        WAVELENGTH_CONFIGSTAT.addOnly( newindex , b , tr , cost[ b ][ tr ] , count[ b ][ tr ] );

	for ( b in BITRATE)
		for ( var p in SINGLEHOP_SET)
			if ( a [ b ][ p ].solutionValue > 0.5 )
	 			WAVELENGTH_CONFIGSET.addOnly( newindex , p.index , b );

	
}  

  
