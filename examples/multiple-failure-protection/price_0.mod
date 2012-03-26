

include "params.mod" ;



execute {


	cplex.intsollim = 1;
	cplex.cutup = 	-0.0001 ; // reduced cost 
		
	setNextModel("MASTER-FINAL");	
}

dvar  float+ y[ 1 .. nfailure ][ edgeset ][ requestset ] in 0..1;
dvar  int+   d[ 1 .. nfailure ][ nodeset ][ requestset ] in 0..1 ; 

dvar  float+ path   [ edgeset ][ requestset ] in 0..1 ;
dvar  int+   degree [ nodeset ][ requestset ] in 0..1 ;


// cover circle
dvar  int+ used   [ edgeset    ] in 0..1;
dvar  int+ d_used [ nodeset    ] in 0..1;

dexpr float  cost = sum( e in edgeset ) used[ e ] * e.distance;
dvar  int+ provide[ range_failure_request ]  in 0..2;


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
	used[ e ] >= sum ( r in requestset : recovery[ f ][ r ] > 0 ) y[ f ][ e ][ r ] ;

forall( v in nodeset )
	sum( e in edgeset : e.src == v || e.dst == v )  used[ e ] == 2 * d_used[ v ] ;

// remove empty case 
cost >=  3 ;		


forall( e in edgeset , r in requestset )	
	path[ e ][ r ] <= used[ e ];


forall ( r in requestset , v in nodeset :  ( v != r.src ) && ( v != r.dst ))
	sum( e in edgeset : e.dst == v || e.src == v ) path[ e ][ r ] == 2 * degree[ v ][ r ];

forall ( r in requestset  )
	sum( e in edgeset : e.dst == r.src || e.src == r.src ) path[ e ][ r ] == degree[ r.src ][ r ];

forall ( r in requestset  )
	degree[ r.src ][ r ] >= d_used[ r.src ] + d_used[ r.dst ] - 1;



} 


/********************************************** 

	POST PROCESSING
	
 *********************************************/

execute {
	// copy current used
	poolcycle.addOnly( used.solutionValue );

	// print price objective 
	writeln("General Price : " , cplex.getObjValue() , " Config Cost : " , cost.solutionValue , " ncycle : " , poolcycle.size );  

	// update column 
	if ( enter_point[ 0 ] == 0 )	
		poolset.addOnly(  poolset.size , cost.solutionValue , provide.solutionValue , used.solutionValue );	
	else {

		var c = Opl.item( poolset , enter_point[ 1 ] );

		c.cost = cost.solutionValue;

		for ( var r in range_failure_request )
			c.provide[ r ] = provide[r ].solutionValue ;
		
		for ( var e in edgeset )
			c.used[ e ] = used[ e ].solutionValue ;
				
	}
		
	setNextModel("MASTER-RELAX-1");
	
	consider_cycle[ 0 ] = -1;
	running[0]=0;
}  

  
