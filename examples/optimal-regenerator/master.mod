/*********************************************
 *
 * COLUMN GENERATION - MASTER PROBLEM
 *
 *
 *********************************************/

include "params.mod";


dvar float+ dummy_var[ 1 .. PERIOD ][ BITRATE ][ NODESET ][ NODESET ]   ;

// number of copies of singlehop configuration
dvar int+ z[ WAVELENGTH_CONFIGINDEX ] ;
// number of copies of multihop configuration
dvar int+ y[ 1.. PERIOD][ MULTIHOP_CONFIGSET  ] ;
// number of available singlehop links from VI to VJ 
dvar float+ provide[ BITRATE ][ NODESET ][ NODESET ];
// intermediate node
dvar int+ x[ 1..PERIOD][ NODESET ] in 0..1 ;

execute{

    setModelDisplayStatus( 1 );	

    writeln("SOLVING : " , getModel() , FINISH_RELAX_FLAG );
    
    if ( isModel( "FINALMASTER" ) ){
        cplex.epgap = 0.05 ;
        writeln( "FINAL MASTER WITH " , WAVELENGTH_CONFIGINDEX.size , " SINGLE HOP AND " , MULTIHOP_CONFIGSET.size , " MULTIHOP ");
    }

}



minimize       sum( c in WAVELENGTH_CONFIGINDEX ) c.cost * z[ c ] 
            +  sum( p in 1..PERIOD , b in BITRATE , vs  in NODESET , vd  in NODESET ) dummy_var[ p ][ b ][ vs ][ vd ] * dummy_cost ; 

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
                        : c.index == cindex.index && c.bitrate == b && c.indexPath == p.index && p.src == vi.id && p.dst == vj.id ) z[ cindex ] 
        
             == provide[ b ][ vi ][ vj ] ;

    }

    forall( p in 1..PERIOD , b in BITRATE , vs  in NODESET , vd  in NODESET ) {

        // satisfy request
        ctRequest: 
             sum( m in MULTIHOP_CONFIGSET : m.src == vs.id &&  m.dst == vd.id && m.bitrate == b && m.period == p ) y[ p ][ m ]  + dummy_var[ p ][ b ][ vs ][ vd ]
         >=  sum ( dem in DEMAND : dem.period == p  && dem.bitrate == b && dem.src == vs.id && dem.dst == vd.id ) dem.nrequest ;
    }

    // avaialabity for multihop
    forall( p in 1..PERIOD , b in BITRATE , vi  in NODESET , vj in NODESET  ) {
        ctAvail:
            sum( m in MULTIHOP_CONFIGSET , l in MULTIHOP_LINKSET : m.bitrate == b && m.index == l.index && l.id_vi == vi.id && l.id_vj == vj.id  && m.period == p)
                y[ p ][ m ] <= provide[ b ][ vi ][ vj ];

    } 

   forall( p in 1..PERIOD , v in NODESET )
    ctRegen :
        sum( m in MULTIHOP_CONFIGSET , s in MULTIHOP_INTERSET :  m.index == s.index && s.nodeid == v.id && m.period == p ) 
                y[p][m] <= x[p][v] * (sum( dem in DEMAND ) dem.nrequest); 

  
   forall( p in 1..PERIOD )
        sum( v in NODESET )  x[p][v] <= NGEN ;
    	
};


float dummy_multi = sum( p in 1..PERIOD , b in BITRATE , vs  in NODESET , vd  in NODESET ) dummy_var[ p ][ b ][ vs ][ vd ] ;
float dummy_wavelength = sum( c in WAVELENGTH_CONFIGINDEX : c.cost >= ( dummy_cost -1 ) ) z[c] ;

float totalprovide = sum(   b in BITRATE , vi  in NODESET , vj  in NODESET ) provide[ b ][ vi ][ vj ];

float costbyrate[ b in BITRATE ] = sum ( c in WAVELENGTH_CONFIGINDEX, s in  WAVELENGTH_CONFIGSTAT : s.index == c.index && s.rate == b ) z[c] * s.cost ;  
float   countbyrate[ b in BITRATE ] = sum ( c in WAVELENGTH_CONFIGINDEX, s in  WAVELENGTH_CONFIGSTAT : s.index == c.index &&  s.rate == b ) z[c] * s.count ;  
  

float cost2d[ b in BITRATE ][ tr in TRSET ] = sum ( c in WAVELENGTH_CONFIGINDEX, s in  WAVELENGTH_CONFIGSTAT : s.index == c.index && s.rate == b && s.reach == tr ) z[c] * s.cost ;  
float   count2d[ b in BITRATE ][ tr in TRSET ] = sum ( c in WAVELENGTH_CONFIGINDEX, s in  WAVELENGTH_CONFIGSTAT : s.index == c.index &&  s.rate == b && s.reach == tr ) z[c] * s.count ;  

float   number_wavelength = sum ( c in WAVELENGTH_CONFIGINDEX ) z[c ] ;
float   number_regen [ p in 1..PERIOD ] = sum( v in NODESET ) x[ p ][ v ] ;



/********************************************** 

	POST PROCESSING
	
 *********************************************/
 
	
execute CollectDualValues {


            // copy dual values
        var v, p ,  b , vi , vj ,tr;
    writeln( "Master Objective: " , cplex.getObjValue(), " Dummy Multi: " , dummy_multi 
            , " Dummy Wavelength: " , dummy_wavelength 
            , " Provide " , totalprovide , " NCALL : " , NMASTERCALL[ 0 ] , " NSINGLE : " , WAVELENGTH_CONFIGINDEX.size ,  " NMULTI : " , MULTIHOP_CONFIGSET.size  );
 
// ======================================================== RELAX MASTER ================================================================
if ( isModel("RELAXMASTER" )) {


    NMASTERCALL[ 0 ]  = NMASTERCALL[ 0 ] + 1 ;
    // keep ratio nbasic / notbasic

	var ratiowarn  = 2.0 ;
    var ratiobasic = 1.0;
    var nbasic = 0 ;
    var nnonbasic = 0 ;


    function reduceObject( _period , _index , _reduceCost , _ismulti ){

	this.period = _period ;
	this.index  = _index  ;
	this.reduceCost = _reduceCost ;
	this.ismulti    = _ismulti ;

    } 

    var sortVar = new Array();
   

    for ( p = 1 ; p <= PERIOD ; p ++ )
    for ( var ms in MULTIHOP_CONFIGSET  ){

        if ( y[ p ][ ms ].reducedCost == 0.0 ) nbasic +=1 ; else nnonbasic +=1 ;

	sortVar[ sortVar.length ] = new reduceObject( p , ms.index , y[ p ][ ms ].reducedCost , 1 );
    }
 
    for ( ms in WAVELENGTH_CONFIGINDEX ){

        if ( z[ ms ].reducedCost == 0.0 ) nbasic +=1 ; else nnonbasic +=1 ;

	sortVar[ sortVar.length ] = new reduceObject( 0 , ms.index , z[ ms ].reducedCost , 0 );
	
    }

    // sort var

    for ( var i1 = 0 ; i1 < ( sortVar.length - 1 ) ; i1 ++ )
    for ( var i2 = i1 + 1  ; i2 <  sortVar.length  ; i2 ++ )
	if (  sortVar[ i1 ].reduceCost > sortVar[ i2 ].reduceCost ) {

		// swap value 
		var tmp ;
		tmp = sortVar[i1] ; sortVar[i1] = sortVar[ i2 ] ; sortVar[ i2 ] = tmp ;
		
	}
 

    writeln( "Ratio : " , nnonbasic / nbasic , " Highest RS : " , sortVar[ sortVar.length - 1 ].reduceCost , " Removed " , NCOLDEL[0] ); 

   // remove nonbasic column
   if ( nnonbasic > 0 && nbasic > 0 &&  ( (nnonbasic / nbasic) > ratiowarn ) )
   	   {


			for ( var i = nbasic * ( ratiobasic + 1) ; i < sortVar.length ;  i ++ ){

				var delObj = sortVar[ i ] ;
				var removeIndex = delObj.index ;

				NCOLDEL[ 0 ] = NCOLDEL[ 0 ] + 1 ;
				
				if ( delObj.ismulti == 0 ){

					filterCollection( WAVELENGTH_CONFIGINDEX , "index" , removeIndex , WAVELENGTH_CONFIGINDEX_TMP );
					filterCollection( WAVELENGTH_CONFIGSET , "index" , removeIndex , WAVELENGTH_CONFIGSET_TMP );
					filterCollection( WAVELENGTH_CONFIGSTAT , "index" , removeIndex , WAVELENGTH_CONFIGSTAT_TMP );
				}
				
				else{
					
					filterCollection( MULTIHOP_CONFIGSET , "index" , removeIndex , MULTIHOP_CONFIGSET_TMP );
					filterCollection( MULTIHOP_LINKSET , "index" , removeIndex , MULTIHOP_LINKSET_TMP );
					filterCollection( MULTIHOP_INTERSET , "index" , removeIndex , MULTIHOP_INTERSET_TMP );

				}


				FINISH_RELAX_FLAG.add( 1 );
				setNextModel("RELAXMASTER"); 


			}

   	} else	

    if ((FINISH_RELAX_FLAG.size == 0 || NMASTERCALL[0] > 1000  ) && dummy_multi < 0.01 && dummy_wavelength < 0.01 ) {
           
           setNextModel("FINALMASTER"); 
       	   RELAXOBJ[0] = cplex.getObjValue();

 
     } 
    else {

            setNextModel("SINGLEPRICE");  

        FINISH_RELAX_FLAG.remove( 1 );     

        // copy dual slot values
        for ( v in NODESET )
            dual_slot[ v ] = ctSlot[v].dual ;


        dual_wave[ 0 ] = ctWave.dual ;

         
    	
        // copy regen dual values
        for ( p = 1 ; p <= PERIOD; p ++ )
        for ( v in NODESET )
            dual_regen[ p][ v ] = ctRegen[ p ][ v ].dual ;
        
        // copy provide dual values
        for ( b in BITRATE )
            for( vi in NODESET )
                for( vj in NODESET )	           
                    dual_provide[ b ][ vi ][ vj ] = ctProvide[ b ][ vi ][ vj ].dual ;

                
        // copy request & avail dual values
        for ( p = 1 ; p <= PERIOD; p ++ )
            for ( b in BITRATE )
                for( vi in NODESET )
                    for( vj in NODESET ){

                        dual_request[ p ][ b ][ vi ][ vj ] = ctRequest[ p ][ b ][ vi ][ vj ].dual ;
                        dual_avail[ p ][ b ][ vi ][ vj ]   = ctAvail[ p ][ b ][ vi ][ vj ].dual ;
    
                        // add new multihop process
                        if ( vi.id != vj.id)
                            CAL_MULTISET.add( vi.id , vj.id , p , b);

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
    	    writeln("NCOLDEL : " , NCOLDEL[ 0 ] ) ;

            for ( p = 1 ; p <= PERIOD ; p ++ )
                writeln( "NREGEN-PERIOD-" + p + ":" , number_regen[ p ] );    


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


   
    



