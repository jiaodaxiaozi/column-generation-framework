include "params.mod" ;


dvar float+ cost ;
dvar float+ p[ DEMAND ]  ;
dvar float+ pp[ DEMAND ] in 0..2 ;// provide of protect
dvar int+ x[ EDGESET ] in 0..1;
dvar int+ y[ DEMAND  ][ EDGESET ] in 0..1;

dvar int+ protect[ DEMAND ][ EDGESET ] in 0..1 ; 
dvar int+ z[ EDGESET ] in 0..1;

execute {

	setModelDisplayStatus( 1 ) ;

	cplex.intsollim = 1; // take only one solution
	cplex.cutup = 	-0.001 ; // reduced cost 		
	cplex.parallelmode = -1 ; // opportunistic mode
	cplex.threads = 0 ; // use maximum threads


	writeln("SOLVE " , getModel() );

	setNextModel("FINAL");

}
minimize cost - dual_wave[ 0 ] - sum ( d in DEMAND ) dual_provide[ d ] * p[ d ] ; 
subject to {

	forall( d in DEMAND ) {
		forall ( v in NODESET : v != d.src && v != d.dst )	
			sum( e in EDGESET : e.src == v ) y[ d ][ e ]	== sum( e in EDGESET : e.dst == v ) y[d][ e ];	

		sum( e in EDGESET : e.src == d.src ) y[d][e] == p[ d ] ;
		sum( e in EDGESET : e.src == d.dst ) y[d][e] == 0 ;
		sum( e in EDGESET : e.dst == d.dst ) y[d][e] == p[ d ] ;
		sum( e in EDGESET : e.dst == d.src ) y[d][e] == 0 ;
	}

	// working paths
	forall ( e in EDGESET )
		sum( d in DEMAND )  y[d][e] == x[e] ;

	// protect circle
	forall ( e in EDGESET  ) {

			sum( d in DEMAND )  protect[d][e] <= z[e] ;
	}

	// cost
	cost == sum( e in EDGESET ) (x[e]+z[e]);


	// protection part
	forall( d in DEMAND ) {
		forall ( v in NODESET : v != d.src && v != d.dst )	
			sum( e in EDGESET : e.src == v ) protect[ d ][ e ]	== sum( e in EDGESET : e.dst == v ) protect[d][ e ];	

		sum( e in EDGESET : e.src == d.src ) protect[d][e] == pp[d]  ;
		sum( e in EDGESET : e.src == d.dst ) protect[d][e] == 0 ;
		sum( e in EDGESET : e.dst == d.dst ) protect[d][e] == pp[d]  ;
		sum( e in EDGESET : e.dst == d.src ) protect[d][e] == 0 ;


		// if p[d] = 0 then pp[d] = 0
		pp[ d ] <= 2 * p[ d ];
		// if p[d] > 0 then pp[d] >= 1
		pp[ d ] * d.nrequest >= p[d] ;
	
		forall ( e in EDGESET )
			( protect[d][e] + y[d][e] ) <= 1 + abs(pp[d] - 1 );	

	}

	

	// cyccle

	forall ( v in NODESET )
		sum( e in EDGESET : e.src == v ) z[e] == sum ( e in EDGESET : e.dst == v ) z[e] ;

	

}

execute {

	setNextModel("RELAXMASTER");
	writeln("Price Obj :", cplex.getObjValue(), " Cost : " , cost.solutionValue );

	CONFIGSET.addOnly( cost.solutionValue, p.solutionValue );

	// write out the result 

	/*
	for ( var d in DEMAND )
	if ( p[ d ].solutionValue > 0 ) 
	{
		writeln("Demand " , d , " = " , p[ d ].solutionValue );
		for ( var e in EDGESET )
		if ( y[ d ][ e ].solutionValue > 0 ) 
			write( e , " " );
		writeln();

	}*/	
}
