include "params.mod";

dvar int flow[ 1..2][ edgeset ][ requestset ] in 0..1 ;
dvar int demidegree[ 1..2 ][ nodeset ][ requestset ] in 0..1;
dvar int is_ok in 0..1 ;


execute {

  TEMPVAR[0] = TEMPVAR[0] + 1 ;
  writeln("REMOVE INVALID FAILURE SET ... " , TEMPVAR[0]);
  
  if ( TEMPVAR[0] < nfailure ) {	
	
	setNextModel("REMOVE");
	
  } else setNextModel("WORKING");
  
  
  

}

maximize is_ok ;


subject to {

	forall (p in 1..2, e in edgeset : e.id in failureset[ TEMPVAR[0] ] )
		sum( r in requestset ) flow[ p ][ e ][r ] == 0;

 	/* NETWORK FLOW FORMULATION */

	forall ( p in 1..2 , v in nodeset , r in requestset : v != r.src && v!= r.dst )
		 sum( e in edgeset : e.src == v || e.dst == v ) flow[ p ][ e ][ r ] == 2 * demidegree[ p ][ v ][ r ];

	forall ( p in 1..2 ,r in requestset  )		 
		 sum( e in edgeset : e.src == r.src || e.dst == r.src ) flow[ p ][ e ][ r ] == demidegree[ p ][ r.src ][ r ];
		 
	forall ( p in 1..2 , r in requestset  )		 
		 sum( e in edgeset : e.src == r.dst || e.dst == r.dst ) flow[ p ][ e ][ r ] == demidegree[ p ][ r.dst ][ r ];

	forall ( p in 1..2 , r in requestset  )		 		 
		demidegree[ p ][ r.src ][ r ] == demidegree[ p ][ r.dst ][ r ];
	
	forall ( e in edgeset , r in requestset )
		 flow[ 1 ][ e ][ r ] + flow[ 2 ][ e ][ r] <= 1 ;

		 
	forall ( p in 1..2 , r in requestset  )		 		 
		is_ok <= demidegree[ p ][ r.src ][ r ];

}


execute {

	
		if ( is_ok.solutionValue > 0 )
			acceptfailureset[ TEMPVAR[0] ] = 1;
		else
			acceptfailureset[ TEMPVAR[0] ] = 0;
	
		



		// finish !
		if ( TEMPVAR[0] == nfailure ) {
			for ( var j = 1 ; j <= nfailure ; j ++ )
			for ( var i = 1 ; i <= nfailure ; i ++ )
				if ( i != j && failureset_inside[ i ][ j ] == 1 && acceptfailureset[ j ] > 0 )
					acceptfailureset[ i ] = 0 ;
					
				

			var naccept = 0 ;

			for ( i = 1 ; i <= nfailure ; i ++ )
				if  ( acceptfailureset[ i ] > 0){
					writeln(".failure set : " , failureset[ i ] , " ACCEPTED" );
					naccept += 1; 
				}
				else
					writeln(".failure set : " , failureset[ i ] , " REJECTED" );
				
			writeln("--------------------------------------------------");
			writeln("ACCEPTED FAILURE = " , naccept , " NOT-ACCEPT = " , nfailure - naccept );
			writeln();
		}

}
