include "params.mod";


execute {


    setModelDisplayStatus( 1 );

    writeln("START SHORTEST SURVEY");
    writeln("");
    writeln("number of nodes :" , NODESET.size );
    writeln("number of undirected edges :" , UNDIRECTED_EDGESET.size );
    writeln("SEED TRAFFIC : " , SEED_TRAFFIC );

    // ---------------------------------------------------------------------------------------------------- //
    // GENERATE DIRECTED EDGES
    // ---------------------------------------------------------------------------------------------------- //
    
    for ( i = 0 ; i < UNDIRECTED_EDGESET.size ; i ++ ){

        tedge = Opl.item( UNDIRECTED_EDGESET , i );
        DIRECTED_EDGESET.add( tedge.id_va , tedge.id_vb , tedge.distance ); 
        DIRECTED_EDGESET.add( tedge.id_vb , tedge.id_va , tedge.distance ); 
    } 

    writeln("number of directed edges : " , DIRECTED_EDGESET.size );

    // ---------------------------------------------------------------------------------------------------- //
    // TOTAL POPULATION
    // ---------------------------------------------------------------------------------------------------- //
    var totalpop = 0 ;
    for ( i = 0 ; i < NODESET.size ; i ++ )
        totalpop += Opl.item( NODESET , i ).pop ;
    writeln("total population : " , totalpop );

    // ---------------------------------------------------------------------------------------------------- //
    // TRAFFIC GENERATION
    // ---------------------------------------------------------------------------------------------------- //

    K_SDSET.clear();



    var unitload = 0 ;

    // GENERATE DIRECTED TRAFFIC  
    for ( i = 0 ; i < NODESET.size ; i ++ )
        for ( var j = 0 ; j < NODESET.size ; j ++ )  
            if ( i != j ) 
            {
                var node_i = Opl.item( NODESET , i );
                var node_j = Opl.item( NODESET , j );

                K_SDSET.add( node_i.id , node_j.id );

                unitload = unitload +   ( node_i.pop * node_j.pop / ( totalpop * totalpop )) * ( node_i.pop /( node_i.pop + node_j.pop));




        var trafficdemand =  ( SEED_TRAFFIC * node_i.pop * node_j.pop / ( totalpop * totalpop )) * ( node_i.pop /( node_i.pop + node_j.pop));

         writeln("TRAFFIC:" , node_i.id , ":" , node_j.id , ":" , trafficdemand );
         DEMAND.add( node_i.id , node_j.id, trafficdemand );


    }


    writeln( "UNITLOAD     :" , unitload ) ;

    writeln( "REGENERATOR COST" );
    writeln( "10Gps 750km  :" , REGENERATOR_COST[ 10 ][ 750 ] );
    writeln( "10Gps 1500km :" , REGENERATOR_COST[ 10 ][ 1500 ] );
    writeln( "10Gps 3000km :" ,REGENERATOR_COST[ 10 ][ 3000 ] );

    writeln( "40Gps 750km  :" , REGENERATOR_COST[ 40 ][ 750 ] );
    writeln( "40Gps 1500km :", REGENERATOR_COST[ 40 ][ 1500 ] );
    writeln( "40Gps 3000km :", REGENERATOR_COST[ 40 ][ 3000 ] );

    writeln( "100Gps 750km  :" , REGENERATOR_COST[ 100 ][ 750 ] );
    writeln( "100Gps 1500km :",REGENERATOR_COST[ 100 ][ 1500 ] );
    writeln( "100Gps 3000km :",REGENERATOR_COST[ 100 ][ 3000 ] );



    FINISH_RELAX_FLAG.add( 1 ); // add  flag
    setNextModel("RELAXMASTER");
    NMASTERCALL[0] = 0 ;


}

