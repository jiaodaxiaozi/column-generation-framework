
include "params.mod";

dvar int  flow[ logicset ][ edgeset ] in 0..1 ;



execute {

    writeln("Preprocessing ...") ;

    /*
    for ( var f = 1 ; f <= nfailure ; f ++ )
    {
        writeln( " failure " , f , " happends : " );

        for (var e1 in edgeset )
        if ( efail[ f ][ e1 ] == 1 )
            writeln( e1 , " is broken " );
    } */


    cplex.epgap = 0;

    for ( var e in edgeset )
        capacity[ e ] = 0 ;
}

minimize sum( l in logicset , e in edgeset ) flow[ l ][ e ] ;

subject to {


    forall( lg in logicset ) {

        // intermediate node
        forall( v in nodeset : ( v != lg.src ) && ( v != lg.dst ) )
            sum( e in edgeset : e.src == v ) flow[ lg ][ e ] == sum( e in edgeset : e.dst == v ) flow[ lg ][ e ] ; 

        sum( e in edgeset : e.src == lg.src ) flow[ lg ][ e ] == 1 ;
        sum( e in edgeset : e.dst == lg.dst ) flow[ lg ][ e ] == 1 ;

        sum( e in edgeset : e.src == lg.dst ) flow[ lg ][ e ] == 0 ;
        sum( e in edgeset : e.dst == lg.src ) flow[ lg ][ e ] == 0 ;


    }
}



execute {

 writeln("NUMBER LOGIC : " , logicset.size );


 for ( var lg in logicset ) {

    var pathcost = 0 ;

    write("SP l-link " + lg + " : "  ) ;

    for ( var e in edgeset ) 
    if ( flow[ lg ][ e ].solutionValue > 0.5 ) {

        write( e.src + "-" + e.dst , " " ) ;
        capacity[ e ] = capacity[e ] + 1 ;

        pathcost = pathcost + 1;

        thepath[ e]  = 1 ;
    } else
        thepath[ e ] = 0 ;

    writeln( " length = " , pathcost );

    //configset.addOnly( configset.size , lg.id , pathcost , thepath );
 }
 


 /* -------------- RANDOM SETUP ---------------*/
 Opl.srand( (new Date()).getSeconds() );

 // return random from a to b
 function selectRand( a , b ) {

    return ( Opl.rand( b - a + 1 ) + a );
 }


// set new capacity
for ( e in edgeset ) { 

    var percent = Opl.ceil( capacity[e] * 0.2 )  ;
    
    if ( percent < 1 ) percent = 1 ;

    var dv = 0 ; 
    
    while( dv  == 0 ) 
        dv = selectRand( - percent ,  percent )  ; 
 
    var newv = capacity[e] + dv ; 

    if ( newv <= 0 ) newv = 1 ;
    

    writeln( "edge " , e , " old = " , capacity[e] , " new = " , newv , " change : " , dv );
    capacity[ e ] = newv ;

}

writeln();
writeln("NUMBER CONFIGSETS : " , configset.size );

setNextModel("RELAX-ROUTE");

} 
