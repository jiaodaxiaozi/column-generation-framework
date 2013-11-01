/*********************************************
 *
 * COLUMN GENERATION - MASTER PROBLEM
 *
 *
 *********************************************/

include "params.mod";


dvar float+ dummy   ;

// number of copies of singlehop configuration
dvar int+ z[ WAVELENGTH_CONFIGINDEX ] ;
// number of copies of multihop configuration
dvar int+ y[ MULTIHOP_CONFIGSET  ] ;
// intermediate node
dvar int+ x[ NODESET ] in 0..1 ;
dvar float+ groom[ NODESET ][ NODESET ][ BITRATE ] ;
execute{

    setModelDisplayStatus( 1 );	

    writeln("SOLVING : " , getModel() , FINISH_RELAX_FLAG );
    
    if ( isModel( "FINALMASTER" ) ){
        cplex.epgap = 0.15 ;
        cplex.tilim = 3600 * 2 ;
        writeln( "FINAL MASTER WITH " , WAVELENGTH_CONFIGINDEX.size , " SINGLE HOP AND " , MULTIHOP_CONFIGSET.size , " MULTIHOP ");
    }

}



minimize       sum( c in WAVELENGTH_CONFIGINDEX ) c.cost * z[ c ] 
            +  dummy * dummy_cost ; 

subject to {

    
    ctWave:
        sum ( c in WAVELENGTH_CONFIGINDEX ) z[c] <= NWAVELENGTH ;   

    ctDegree:
        forall ( v in NODESET )
            ctSlot : 
        sum( c in WAVELENGTH_CONFIGINDEX , d in SINGLEHOP_DEGREESET : c.index == d.index && d.nodeid == v.id ) z[c] * d.degree <= NNODESLOT ; 
 
    // compute provide per bitrate between vi vj
    forall(   b in BITRATE , vi  in NODESET , vj  in NODESET ) {

       ctProvide : 
            
             sum( cindex in WAVELENGTH_CONFIGINDEX , c in WAVELENGTH_CONFIGSET , p in SINGLEHOP_SET 
                        : c.index == cindex.index 
                          && c.bitrate == b && c.indexPath == p.index 
                          && p.src == vi.id && p.dst == vj.id ) z[ cindex ] 
        
            >= 

            sum( m in MULTIHOP_CONFIGSET , l in MULTIHOP_LINKSET : m.bitrate == b && m.index == l.index 
                            && l.id_vi == vi.id && l.id_vj == vj.id  )
                y[ m ] ; 


    }

    forall( b in BITRATE , vs  in NODESET , vd  in NODESET ) {

        // satisfy request
        ctRequest: 
             sum( m in MULTIHOP_CONFIGSET : m.src == vs.id &&  m.dst == vd.id && m.bitrate == b  ) y[ m ]  
                >=  
            groom[ vs ][ vd ][ b ] ;
    }

    forall( vs in NODESET , vd in NODESET  ){

           sum( b in BITRATE ) groom[ vs ][ vd ][ b ] * b + dummy >= sum( d in DEMAND : d.src == vs.id && d.dst == vd.id ) d.traffic;
    
    }

   forall(  v in NODESET )
    ctRegen :
        sum( m in MULTIHOP_CONFIGSET , s in MULTIHOP_INTERSET :  m.index == s.index && s.nodeid == v.id ) 
                y[m] <= x[v] * NNODESLOT;

  
        sum( v in NODESET )  x[v] <= NGEN ;
    	
};



float provide[ b in BITRATE ][ vi in NODESET ][ vj in NODESET ] =  sum( m in MULTIHOP_CONFIGSET , l in MULTIHOP_LINKSET : 
                                m.bitrate == b && m.index == l.index 
                            && l.id_vi == vi.id && l.id_vj == vj.id  )
                y[ m ] ; 


float totalprovide = sum(   b in BITRATE , vi  in NODESET , vj  in NODESET ) provide[ b ][ vi ][ vj ];

float costbyrate[ b in BITRATE ] = sum ( c in WAVELENGTH_CONFIGINDEX, s in  WAVELENGTH_CONFIGSTAT : s.index == c.index && s.rate == b ) z[c] * s.cost ;  
float   countbyrate[ b in BITRATE ] = sum ( c in WAVELENGTH_CONFIGINDEX, s in  WAVELENGTH_CONFIGSTAT : s.index == c.index &&  s.rate == b ) z[c] * s.count ;  
  

float cost2d[ b in BITRATE ][ tr in TRSET ] = sum ( c in WAVELENGTH_CONFIGINDEX, s in  WAVELENGTH_CONFIGSTAT : s.index == c.index && s.rate == b && s.reach == tr ) z[c] * s.cost ;  
float   count2d[ b in BITRATE ][ tr in TRSET ] = sum ( c in WAVELENGTH_CONFIGINDEX, s in  WAVELENGTH_CONFIGSTAT : s.index == c.index &&  s.rate == b && s.reach == tr ) z[c] * s.count ;  

float   number_wavelength = sum ( c in WAVELENGTH_CONFIGINDEX ) z[c ] ;
float   number_regen= sum( v in NODESET ) x[ v ] ;



/********************************************** 

	POST PROCESSING
	
 *********************************************/
 
	
execute CollectDualValues {


            // copy dual values
        var v, p ,  b , vi , vj ,tr;
    writeln( "Master Objective: " , cplex.getObjValue(), " Dummy :" , dummy 
            , " Provide " , totalprovide , " NCALL : " , NMASTERCALL[ 0 ] , " NSINGLE : " , WAVELENGTH_CONFIGINDEX.size ,  " NMULTI : " , MULTIHOP_CONFIGSET.size  );
 
// ======================================================== RELAX MASTER ================================================================
if ( isModel("RELAXMASTER" )) {


    NMASTERCALL[ 0 ]  = NMASTERCALL[ 0 ] + 1 ;

    if (( NMASTERCALL[0] % 10 ) == 0 ){

            //saveStateToFile("install_10.dat" );
 

    }

    RELAXOBJ[1] = RELAXOBJ[0];
    RELAXOBJ[0] = cplex.getObjValue();

   if   (   FINISH_RELAX_FLAG.size == 0 || NMASTERCALL[0] > 200  ) {
           
            setNextModel("FINALMASTER"); 
            // saveStateToFile("install_final.dat" );
            // stop();
         } 
    else {

        setNextModel("SINGLEPRICE");  

        FINISH_RELAX_FLAG.remove( 1 );     

        // copy dual slot values
        for ( v in NODESET )
            dual_slot[ v ] = ctSlot[v].dual ;


        dual_wave[ 0 ] = ctWave.dual ;

         
    	
        // copy regen dual values
        for ( v in NODESET )
            dual_regen[ v ] = ctRegen[ v ].dual ;
        
        // copy provide dual values
        for ( b in BITRATE )
            for( vi in NODESET )
                for( vj in NODESET )	           
                    dual_provide[ b ][ vi ][ vj ] = ctProvide[ b ][ vi ][ vj ].dual ;

                
        // copy request & avail dual values
            for ( b in BITRATE )
                for( vi in NODESET )
                    for( vj in NODESET ){

                        dual_request[ b ][ vi ][ vj ] = ctRequest[ b ][ vi ][ vj ].dual ;
    
                        // add new multihop process
                        if ( vi.id != vj.id)
                            CAL_MULTISET.add( vi.id , vj.id , b);

                    }
	}
    

}


 // =============================== FINAL MASTER ================================================== 
 if ( isModel("FINALMASTER"))
 {
        
                lineSep("FINAL","-");
                var intobj = cplex.getObjValue();

                writeln("RELAX-OBJ : " ,  RELAXOBJ[0] );
                writeln("INT-OBJ: " , intobj );
                writeln("GAP : " , GAP( RELAXOBJ[0], intobj ));
                writeln("WAVELENGTH : " , number_wavelength );

                writeln( "NREGEN:" , number_regen );    

    
                for ( b in BITRATE ){
                    writeln("COST-BY-RATE-" + b + "=" , costbyrate[ b ] );
                    writeln("COUNT-BY-RATE-" + b + "=", countbyrate[ b ] );
                }

                for ( b in BITRATE )
                for ( tr in TRSET ) {

                    writeln("COST-2D-RATE-" + b + "-TR-" + tr + "=" , cost2d[ b ][ tr ] );
                    writeln("COUNT-2D-RATE-" + b + "-TR-" + tr + "=", count2d[ b ][ tr ] );
     
                }    


                for ( b in BITRATE )
                for ( vs in NODESET )
                for ( vd in NODESET )
                if ( provide[ b ][ vs ][ vd ] > 0 )
                    writeln( "PROVIDE:" , b , ":" , vs.id , ":" , vd.id , ":" , provide[ b ][ vs ][ vd ] ); 
};    

}


   
    



