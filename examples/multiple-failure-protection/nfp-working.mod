
include "params.mod";

dvar int+ flow[ edgeset ][ requestset ] in 0..1 ;


execute {

  writeln( "") ;
  writeln( "BUILDING RECOVERY DEMANDs"  );
  writeln( "") ;



}

minimize sum( e in edgeset , r in requestset ) flow[ e ][ r ] * e.distance ;


subject to {

 	/* NETWORK FLOW FORMULATION */

 	// flow balance
 	forall ( r in requestset , v in nodeset : ( v != r.src ) && ( v != r.dst) )
 	  	sum( e in edgeset : e.dst == v || e.src == v ) flow[ e ][ r ] <= 2;

 	forall ( r in requestset , v in nodeset : ( v != r.src ) && ( v != r.dst) )
 	  	sum( e in edgeset : e.dst == v || e.src == v ) flow[ e ][ r ] != 1;

 			  	 
	// out of source == provide  
	forall( r in requestset )
		sum ( e in edgeset : e.src == r.src || e.dst == r.src ) flow[ e ][ r ] == ( r.demand > 0 ? 1 : 0 ) ;
			
	// in of dest == provide
	forall( r in requestset )
		sum ( e in edgeset : e.dst == r.dst || e.src == r.dst ) flow[ e ][ r ] == ( r.demand > 0 ? 1 : 0 ) ;
			

}

float workingcapacity = sum( r in requestset , e in edgeset ) flow[ e ][ r ] * e.distance * r.demand  ;

execute {
	var r,e,f , v ;

	for ( r in requestset ){

		write("working path of request " , r , " : " ) ;
		
		for ( e in edgeset )
			if ( flow[ e ][ r ].solutionValue == 1 ) write( e.id , " ") ;
		writeln();				
		
	} 

	// building recovery
	for ( f = 1 ; f <= nfailure ; f ++ )
	for ( r in requestset ) {

		recovery[ f ][ r ] = 0;


		for ( var st in failureset[ f ] )
		if ( flow[  edge_by_id( st )  ][ r ].solutionValue == 1 ){
			recovery[ f ][ r ] =  r.demand ;
			break ;
		}

		if ( acceptfailureset[ f ] == 0 )
			recovery[f ][ r ] = 0 ;
		
	}

	// print recovery demand 
	
	for ( f = 1 ; f <= nfailure ; f ++ ){

		var found = 0 ;
		
		for ( r in requestset )
		if ( recovery[ f ][ r ] > 0 ) {
			found ++ ;
			if ( found == 1 )
				writeln( "if failure set " , failureset[ f ] , " is actived " );
			writeln("...request " , r , " need to recover : " , recovery[ f ][ r ] , " units" );
		}
	} 
	
	
	lineSep("",".");
	
	writeln("Overall Working Capacity : " , workingcapacity );

	lineSep("",".");
	
	setNextModel("MASTER-RELAX-0");
}
