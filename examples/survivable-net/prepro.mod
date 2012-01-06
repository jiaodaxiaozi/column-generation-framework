
include "params.mod";

dvar int  flow[ logicset ][ edgeset ] in 0..1 ;



execute {

    writeln("Preprocessing ...") ;


    cplex.epgap = 0;

    for ( var e in edgeset )
        writeln("capacity of " , e , " = " , e.cap );
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

        pathcost = pathcost + 1;

        thepath[ e]  = 1 ;
    } else
        thepath[ e ] = 0 ;

    writeln( " length = " , pathcost );

    configset.addOnly( configset.size , lg.id , pathcost , thepath );
 }
 


 
writeln();
writeln("NUMBER CONFIGSETS : " , configset.size );

setNextModel("RELAX-ROUTE");

} 
