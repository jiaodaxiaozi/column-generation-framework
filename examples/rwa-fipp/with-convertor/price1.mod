include "params.mod" ;


dvar float+ cost ;
dvar float+ p[ DEMAND ] in 0..1  ;
dvar int+ x[ EDGESET ] in 0..1;
dvar int+ y[ DEMAND  ][ EDGESET ] in 0..1;

dvar int+ protect[ DEMAND ][ EDGESET ] in 0..1 ; 
dvar int+ z[ EDGESET ] in 0..1;

execute {

	setModelDisplayStatus( 1 ) ;

	cplex.intsollim = 1; // take only one solution
	cplex.cutup = 	-0.01 ; // reduced cost 		
	cplex.parallelmode = -1 ; // opportunistic mode
	cplex.threads = 0 ; // use maximum threads


	writeln("SOLVE " , getModel() );

	setNextModel("FINAL1");

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

    forall( d in DEMAND , e in EDGESET )
        y[d][e] <= NARROW_FLOW[ d ][ e ] ;
	// working paths
	forall ( e in EDGESET )
		sum( d in DEMAND )  y[d][e] == x[e] ;

	// protect circle
	forall ( e in EDGESET  ) {

			max( d in DEMAND )  protect[d][e] == z[e] ;
	}

	// cost
	cost == sum( e in EDGESET ) (x[e]+z[e]);


	// protection part
	forall( d in DEMAND ) {
		forall ( v in NODESET : v != d.src && v != d.dst )	
			sum( e in EDGESET : e.src == v ) protect[ d ][ e ]	== sum( e in EDGESET : e.dst == v ) protect[d][ e ];	

		sum( e in EDGESET : e.src == d.src ) protect[d][e] == p[d]  ;
		sum( e in EDGESET : e.src == d.dst ) protect[d][e] == 0 ;
		sum( e in EDGESET : e.dst == d.dst ) protect[d][e] == p[d]  ;
		sum( e in EDGESET : e.dst == d.src ) protect[d][e] == 0 ;


	
		forall ( e in EDGESET )
			( protect[d][e] + y[d][e] ) <= 1 ;	

	}

	

	// cycles

	forall ( v in NODESET ){
		sum( e in EDGESET : e.src == v ) z[e] == sum ( e in EDGESET : e.dst == v ) z[e] ;
		sum( e in EDGESET : e.src == v || e.dst == v ) z[e] <= 2 ;
    }

	

}

float working_cost = sum( e in EDGESET ) x[ e ] ;
float protect_cost = sum( e in EDGESET ) z[e ] ;
 
int colorEdge[ EDGESET ] ;
execute {

	setNextModel("RELAXMASTER1");

    var newindex = 0 ;
 
    for ( c in CONFIGSET )
    if ( c.index >= newindex ) newindex = c.index + 1 ; 
     
	
    writeln("Price Obj :", cplex.getObjValue(), " Cost : " , cost.solutionValue , " column index " , newindex );

	CONFIGSET.addOnly( newindex , cost.solutionValue, p.solutionValue , working_cost , protect_cost  , x.solutionValue , z.solutionValue );

    
    var d , e , listE ;

    // add routing set
    for ( e in EDGESET ) 
    for ( d in DEMAND  )
    if ( y[d][e].solutionValue > 0.5 )
    {
        ROUTESET.addOnly( newindex , d.src , d.dst , e.id );

    }



    function drawColor( lstE , color ){
        
        for ( var it = 0; it < lstE.length ; it++ )
        if ( colorEdge[ lstE[ it ] ] == color ){

            // if no edge with color connect to this edge
            var ncolor = 0;
            var nextEdge = null ; 
            for ( var it1 = 0 ; it1 < lstE.length ; it1 ++ )
            if ( lstE[ it1 ].src == lstE[ it ].dst )
            { 
              if (colorEdge[ lstE[ it1 ] ] == color)        ncolor ++ ;
              if (colorEdge[ lstE[ it1 ] ] == 0 )   nextEdge = lstE[ it1 ] ;      
           
            }
           
            if ( ncolor == 0 && nextEdge != null ){

                colorEdge[ nextEdge ] = color ;
                drawColor( lstE , color ) ;
                break ;
            } 
        } 

    }

    function writePath( color , currentEdge ) {
    
        write( currentEdge.src , "->" );
        colorEdge[ currentEdge ] = 0 ;
        var nt = 0 ;
        for ( var ee in EDGESET )
        if ( colorEdge[ ee ] == color && ee.src == currentEdge.dst ){
            writePath( color , ee );
            nt ++ ;
        } 
        if ( nt == 0 ) write( currentEdge.dst );
    }

    function writeFlow( dem , lstE ){

        // clear colorEdge
        for ( var ee in EDGESET ) colorEdge[ ee ] = 0 ;
        // draw source edge
        var c = 1;
        for ( var it = 0; it < lstE.length ; it++ )
        if ( lstE[ it ].src == dem.src )  
            { colorEdge[ lstE[ it ] ] = c; drawColor( lstE , c ); c++; }

        for ( var cc = 1 ; cc < c ; cc ++ ){
        
            for ( ee in EDGESET )
            if ( colorEdge[ ee ] == cc && ee.src == dem.src ) {
                write("Path " , cc , ":" );
                writePath( cc  , ee ) ;
                writeln();
            }            
        }
    };

    /*

	// write out the working part 
	for ( d in DEMAND )
	if ( p[ d ].solutionValue > 0 ) 
	{
		writeln("DEMAND " , d , " = " , p[ d ].solutionValue );
        writeln("--- working ---");
        // working path
        listE = new Array();
		for ( e in EDGESET )
		if ( y[ d ][ e ].solutionValue > 0 ) 
            listE[ listE.length ] = e;
        writeFlow( d,  listE );

        writeln("--- protecting ---");
        // protecting path
        listE = new Array();
        for( e in EDGESET )
        if ( protect[ d ][ e ].solutionValue > 0 ) 
            listE[ listE.length ] = e;
        
        writeFlow( d ,listE );
 
	}	

    // writing cycles
    for ( e in EDGESET )
        colorEdge[ e ] = 0 ;

    function visit( ed ) {

        colorEdge[ ed ] = 1 ;
        write( ed.src , "->");
        var ncount = 0 ;
        for ( var ee in EDGESET )
        if ( z[ ee ].solutionValue > 0 && colorEdge[ ee ] == 0 && ed.dst == ee.src ){
        
            visit( ee ); 
            ncount ++ ;
        }
        if ( ncount ==0 ) write( ed.dst );
    }
    writeln("CYCLES : ");
    for ( e in EDGESET )
    if ( z[ e ].solutionValue > 0.5 && colorEdge[ e ] == 0 )     { write("cycle ="); visit( e ); writeln(); }
    */
}
