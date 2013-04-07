include "params.mod";

dvar int+ y[ DEMAND  ][ EDGESET ] in 0..1;
dvar int+ p[ DEMAND  ] ;
execute{

    setModelDisplayStatus( 1 );

    writeln("START PRE-PROCESSING");
    writeln("Number of nodes : " , NODESET.size );
    writeln("Number of edges : " , EDGESET.size );
    writeln("Number of demands : " , DEMAND.size );
	writeln("Number of wavelengths : " , NWAVELENGTH );

	cplex.parallelmode = -1 ; // opportunistic mode
	cplex.threads = 0 ; // use maximum threads




}

minimize sum( d in DEMAND , e in EDGESET ) y[d][e] - 100000 * sum( d in DEMAND ) p[d] ;
subject to {
	forall( d in DEMAND ) {
		forall ( v in NODESET : v != d.src && v != d.dst )	
			sum( e in EDGESET : e.src == v ) y[ d ][ e ]	== sum( e in EDGESET : e.dst == v ) y[d][ e ];	

		sum( e in EDGESET : e.src == d.src ) y[d][e] == p[d] ;
		sum( e in EDGESET : e.src == d.dst ) y[d][e] == 0 ;
		sum( e in EDGESET : e.dst == d.dst ) y[d][e] == p[d] ;
		sum( e in EDGESET : e.dst == d.src ) y[d][e] == 0 ;


        p[d] <= 3 ;
	}

    
}

execute {

    var d,d1,d2,e ;

    for( d in DEMAND) {

        writeln("SHORTEST PATH OF " , d );

        for( e in EDGESET ){
            if ( y[d][e].solutionValue > 0.5 )
                write( e );

               NARROW_FLOW[ d] [ e ] = y [ d ][ e ].solutionValue;
        }
        writeln();

    }
	setNextModel("RELAXMASTER1" );

    EXTRA_CALL[0]= 0;
 
}
