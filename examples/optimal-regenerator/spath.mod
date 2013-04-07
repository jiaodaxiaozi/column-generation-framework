include "params.mod";

string SRC ;
string DST ;
int KPATH_ONE = 1 ;

execute {


    // ---------------------------------------------------------------------------------------------------- //
    // POP FIRST SOURCE->DESTIONATION IN K_SDSET
    // ---------------------------------------------------------------------------------------------------- //

    var firstItem = Opl.item( K_SDSET , 0 );

    SRC = firstItem.id_src ;
    DST = firstItem.id_dst ;

    K_SDSET.remove( firstItem ); 
    
    setNextModel("KPATH") ;
}

dvar int flow[ 1.. KPATH_ONE][ DIRECTED_EDGESET ] in 0..1 ;
dvar int vontage[ 1.. KPATH_ONE ][ NODESET ] in 0..100 ;
dvar float pathlength[ k in 1..KPATH_ONE ]; 

minimize sum ( k in 1..KPATH_ONE , e in DIRECTED_EDGESET ) flow[ k ][ e ] * e.distance ;

subject to {

    forall ( k in 1.. KPATH_ONE ) {

        forall ( v in NODESET : v.id != SRC && v.id != DST )
        sum( e in DIRECTED_EDGESET : e.dst == v.id ) flow[ k ][ e ] == sum( e in DIRECTED_EDGESET : e.src == v.id ) flow[ k ][ e ] ;
        
        sum( e in DIRECTED_EDGESET : e.dst == DST ) flow[ k ][ e ] == 1 ;
        sum( e in DIRECTED_EDGESET : e.src == SRC ) flow[ k ][ e ] == 1 ;

        sum( e in DIRECTED_EDGESET : e.src == DST ) flow[ k ][ e ] == 0 ;
        sum( e in DIRECTED_EDGESET : e.dst == SRC ) flow[ k ][ e ] == 0 ;


    }


// ---------------------------------------------------------------------------------------------------- //
// REMOVE CIRCLE BY USING VONTAGE
// ---------------------------------------------------------------------------------------------------- //
forall ( k in 1 .. KPATH_ONE ) {

    forall ( e in DIRECTED_EDGESET , v_src in NODESET , v_dst in NODESET : e.src == v_src.id && e.dst == v_dst.id )
    vontage[ k ][ v_src ]  >= vontage[ k ][ v_dst ] + 1 - ( 1 - flow[ k ][ e ] ) * 100 ; 
    pathlength[ k ] == sum ( e in DIRECTED_EDGESET ) flow[ k ][ e ]  * e.distance;
}


};

// ---------------------------------------------------------------------------------------------------- //
// CALCULATE REACH DISTANCE
// ---------------------------------------------------------------------------------------------------- //

int  reach[ k in 1..KPATH_ONE ] = min( tr in TRSET ) (pathlength[ k ] <= tr ? tr : 1000000) ; 

execute {

    var startIndex = 0;
    for ( var obj in SINGLEHOP_SET )
        if ( startIndex <= obj.index )
            startIndex = obj.index + 1 ;

        for ( var k = 1 ; k <= KPATH_ONE ; k ++ ) 
        {


            SINGLEHOP_SET.addOnly(  startIndex + k - 1 , SRC , DST , pathlength[ k ].solutionValue , reach[k] );

            if (k==1)
                for ( var b in BITRATE){

                // generate dummy wavelength configuration
                var newIndex = WAVELENGTH_CONFIGSET.size ;
                WAVELENGTH_CONFIGSET.addOnly( newIndex ,startIndex,b );                
                WAVELENGTH_CONFIGINDEX.addOnly( newIndex , dummy_cost );

            }

            for ( var e in DIRECTED_EDGESET )
                if ( flow[ k ][ e ].solutionValue > 0 )
                {
                    SINGLEHOP_EDGESET.addOnly( startIndex + k - 1 ,  Opl.ord( DIRECTED_EDGESET , e ));
                }    

            }

            if ( K_SDSET.size == 0 ) {
                // ---------------------------------------------------------------------------------------------------- //
                // FINISS FINDING SHORTEST PATHS
                // ---------------------------------------------------------------------------------------------------- //
                writeln("DISPLAY K-SHORTEST PATH RESULTS");
                writeln("There is " , SINGLEHOP_SET.size , " lightpaths" );  
                for  ( var i = 0 ; i < SINGLEHOP_SET.size ; i ++ ){

                    write("lightpath " , i , " : " );
                    var thepath = Opl.item( SINGLEHOP_SET , i );
                    // ---------------------------------------------------------------------------------------------------- //
                    // DISPLAY PATH
                    // ---------------------------------------------------------------------------------------------------- //
                    for( var ed in SINGLEHOP_EDGESET )
                        if ( ed.indexPath == i )
                            write( Opl.item( DIRECTED_EDGESET , ed.indexEdge ) ) ; 

                        writeln( " length = " , thepath.pathLength 
                               , " reach  = " , thepath.reach 
                               , " (" , thepath.src 
                               , "->" , thepath.dst , ")" );  

                        for ( var j = 0 ; j < DEMAND.size ; j ++ )
                        {
                                var dd  = Opl.item( DEMAND , j );
                                if ( dd.src == thepath.src && dd.dst == thepath.dst){
                                    writeln( dd );
                                }
                        }

                } // end for all paths

                stop();

            }
        }

