include "params.mod";

string SRC ;
string DST ;

execute {


    var firstItem = Opl.item( K_SDSET , 0 );

    SRC = firstItem.id_src ;
    DST = firstItem.id_dst ;

    K_SDSET.remove( firstItem ); 

    writeln("FIND " + KPATH_PARAM + "-SHORTESTPATH FROM " + SRC +  "->" + DST );
    
    setNextModel("KPATH") ;
}

dvar int flow[ 1.. KPATH_PARAM][ DIRECTED_EDGESET ] in 0..1 ;
dvar int same[ 1.. KPATH_PARAM][ 1..KPATH_PARAM ][ DIRECTED_EDGESET ] in 0..1 ;
dvar int vontage[ 1.. KPATH_PARAM ][ NODESET ] in 0..100 ;
dvar float pathlength[ k in 1..KPATH_PARAM ]; 

minimize sum ( k in 1..KPATH_PARAM , e in DIRECTED_EDGESET ) flow[ k ][ e ] * e.distance ;

subject to {

forall ( k in 1.. KPATH_PARAM ) {

    forall ( v in NODESET : v.id != SRC && v.id != DST )
        sum( e in DIRECTED_EDGESET : e.dst == v.id ) flow[ k ][ e ] == sum( e in DIRECTED_EDGESET : e.src == v.id ) flow[ k ][ e ] ;
        
    sum( e in DIRECTED_EDGESET : e.dst == DST ) flow[ k ][ e ] == 1 ;
    sum( e in DIRECTED_EDGESET : e.src == SRC ) flow[ k ][ e ] == 1 ;

    sum( e in DIRECTED_EDGESET : e.src == DST ) flow[ k ][ e ] == 0 ;
    sum( e in DIRECTED_EDGESET : e.dst == SRC ) flow[ k ][ e ] == 0 ;

   
}

// different path
forall  ( k1 in 1.. KPATH_PARAM , k2 in 1.. KPATH_PARAM : k1 < k2 ) {

    sum( e in DIRECTED_EDGESET ) flow [k1 ][ e ] * e.distance <= sum( e in DIRECTED_EDGESET ) flow [k2 ][ e ] * e.distance ; 

    forall( e in DIRECTED_EDGESET ) {

       same[ k1 ][ k2 ][ e ]  <= flow[ k1 ][ e ]; 
       same[ k1 ][ k2 ][ e ]  <= flow[ k2 ][ e ]; 

       2 * same[ k1 ][ k2 ][ e ] >= ( flow[ k1 ][ e ] + flow[ k2 ][ e ] ) -1 ; 
    }

    sum( e in DIRECTED_EDGESET ) same[ k1 ][ k2 ][ e ] <= ( sum( e in DIRECTED_EDGESET ) flow[ k1 ][ e ] - 1 )  ;
    sum( e in DIRECTED_EDGESET ) same[ k1 ][ k2 ][ e ] <= ( sum( e in DIRECTED_EDGESET ) flow[ k2 ][ e ] - 1 )  ;

}

// vontage to remove circle
forall ( k in 1 .. KPATH_PARAM ) {

    forall ( e in DIRECTED_EDGESET , v_src in NODESET , v_dst in NODESET : e.src == v_src.id && e.dst == v_dst.id )
        vontage[ k ][ v_src ]  >= vontage[ k ][ v_dst ] + 1 - ( 1 - flow[ k ][ e ] ) * 100 ; 


    
    pathlength[ k ] == sum ( e in DIRECTED_EDGESET ) flow[ k ][ e ]  * e.distance;
}


};


int  reach[ k in 1..KPATH_PARAM ] = min( tr in TRSET ) (pathlength[ k ] <= tr ? tr : 1000000) ; 

execute {

    var startIndex = 0;
    for ( var obj in SINGLEHOP_SET )
        if ( startIndex <= obj.index )
            startIndex = obj.index + 1 ;

    writeln("Start Index = " , startIndex );

    for ( var k = 1 ; k <= KPATH_PARAM ; k ++ ) 
    if ( reach[ k ] < 1000000 )
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
        writeln("DISPLAY K-SHORTEST PATH RESULTS");
        writeln("There is " , SINGLEHOP_SET.size , " lightpaths" );  
        for  ( var i = 0 ; i < SINGLEHOP_SET.size ; i ++ ){

            write("lightpath " , i , " : " );
            for( var ed in SINGLEHOP_EDGESET )
                if ( ed.indexPath == i )
                    write( Opl.item( DIRECTED_EDGESET , ed.indexEdge ) ) ; 

            writeln( " leng = " , Opl.item( SINGLEHOP_SET , i ).pathLength , " reach = " , Opl.item( SINGLEHOP_SET , i ).reach );  

        }
        
        setNextModel("RELAXMASTER");
    }
}

