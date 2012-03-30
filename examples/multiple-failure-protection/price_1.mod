

include "params.mod" ;



execute {


	cplex.intsollim = 1;
	cplex.cutup = 	-0.0001 ; // reduced cost 

	
	setNextModel("MASTER-RELAX-0");
}

dvar  int+ y[ 1 .. nfailure ][ edgeset ][ requestset ] in 0..1 ;
dvar  int+ d[ 1 .. nfailure ][ nodeset ][ requestset ] in 0..1 ; 

dvar  int+ path   [ edgeset ][ requestset ] in 0..1 ;
dvar  int+ degree [ nodeset ][ requestset ] in 0..1 ;


// cover circle

int   current_used[ e in edgeset ] = item( poolcycle , consider_cycle[ 0 ] ).used[ e ] ;
int   current_d_used[ v in nodeset ] = sum( e in edgeset : e.src == v || e.dst == v ) current_used[ e ] >= 1 ;

float cost = sum( e in edgeset ) current_used[ e ] * e.distance;
dvar  int+ provide[ range_failure_request ] in 0..2 ;


minimize      cost - sum ( fr in set_failure_request  ) 
			dual_protect[ fr.failure ][ fr.request ] * provide[ ord( set_failure_request, fr ) ];				

subject to {



/* CANNOT USE FAILURE SET */

sum( f in 1..nfailure , e in edgeset , id in failureset[ f ] : id == e.id )	
	sum( r in requestset ) y[ f ][ e ][ r ]== 0;

	
/* NETWORK FLOW FORMULATION */
 
forall ( f in 1..nfailure , r in requestset , v in nodeset :  ( v != r.src ) && ( v != r.dst ))
if ( recovery[ f ][ r ] > 0 )
	sum( e in edgeset : e.dst == v || e.src == v ) y[ f ][ e ][ r ] == 2 * d[ f ][ v ][ r ];



/* PROVIDE PROTECTION */

forall ( f in 1..nfailure , r in requestset  )
if ( recovery[ f ][ r ] > 0 )
	sum( e in edgeset : e.dst == r.src || e.src == r.src ) y[ f ][ e ][ r ] == provide[ ord( set_failure_request, <f,r> ) ];


forall ( f in 1..nfailure , r in requestset )
if ( recovery[ f ][ r ] > 0 )
	sum( e in edgeset : e.dst == r.dst || e.src == r.dst ) y[ f ][ e ][ r ] == provide[ ord( set_failure_request, <f,r> ) ];


/* CALCULATE COVER CIRCLE */

forall( f in 1..nfailure , e in edgeset )
	current_used[ e ] >= sum ( r in requestset : recovery[ f ][ r ] > 0 ) y[ f ][ e ][ r ] ;



forall( e in edgeset , r in requestset )	
	path[ e ][ r ] <= current_used[ e ];


forall ( r in requestset , v in nodeset :  ( v != r.src ) && ( v != r.dst ))
	sum( e in edgeset : e.dst == v || e.src == v ) path[ e ][ r ] == 2 * degree[ v ][ r ];

forall ( r in requestset  )
	sum( e in edgeset : e.dst == r.src || e.src == r.src ) path[ e ][ r ] == degree[ r.src ][ r ];

forall ( r in requestset  )
	degree[ r.src ][ r ] >= current_d_used[ r.src ] + current_d_used[ r.dst ] - 1;


} 


/********************************************** 

	POST PROCESSING
	
 *********************************************/

execute {

	// print price objective 
	writeln("Reduced Price Objective : " , cplex.getObjValue() , " Cycle : " , consider_cycle[0] ,  " Configuration Cost : " , cost );  



	if ( enter_point[ 0 ] == 0 )	
		poolset.addOnly( poolset.size , cost , provide.solutionValue , current_used );
	else {

		var c = Opl.item( poolset , enter_point[ 1 ] );

		c.cost = cost;
	
		for ( var r in range_failure_request )
			c.provide[ r ] = provide[ r ].solutionValue ;

		for ( var e in edgeset )
			c.used[ e ] = current_used[ e ] ;
	}
	
	running[0] = 1 ;

//	setNextModel("MASTER-RELAX-1");
}  

  
