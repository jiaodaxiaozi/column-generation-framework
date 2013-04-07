include "params.mod";

dvar int+ z[ CONFIGSET ] ;
dvar float+ dummy[ DEMAND ] ;

execute {


	writeln("SOLVE " , getModel() );

    NWAVELENGTH = 1000000;
}

minimize sum( c in CONFIGSET ) z[c] * c.cost + sum( d in DEMAND ) dummy[ d ] * 100000;

subject to {

	ctWavelength :
		sum ( c in CONFIGSET ) z[c] <= NWAVELENGTH ;

	forall( d in DEMAND )
		ctProvide:
			sum( c in CONFIGSET ) z[ c ] * c.provide[ d ] + dummy[ d ] >= d.nrequest ;

}


float dummysum = sum ( d in DEMAND ) dummy[ d ] ;
int   usedwave = sum ( c in CONFIGSET ) z[c] ;
float WCOST    = sum ( c in CONFIGSET ) z[c] * c.wcost ;
float PCOST    = sum ( c in CONFIGSET ) z[c] * c.pcost ;

float NUSEDCONFIG = sum ( c in CONFIGSET ) ( z[c] > 0.5 ? 1 : 0 );

execute {

    if (dummysum <= 0.000001 )
        EXTRA_CALL[ 0 ] = EXTRA_CALL[ 0 ] +1 ;

	write("Master Obj : " , cplex.getObjValue() , " Dummy : " , dummysum  , " EXTRA CALL " , EXTRA_CALL[0] , " COLUMNS : " , CONFIGSET.size );

	// copy duals
	dual_wave[ 0 ]  = ctWavelength.dual ;

	for ( var d in DEMAND ){
		dual_provide [ d ] = ctProvide[ d ].dual ;
	}


    if ( isModel("RELAXMASTER") ){

		setNextModel("PRICE");
		RELAXOBJ[0] = cplex.getObjValue();

        function reducedObject( _index , _rcost ) {

            this.index = _index ;
            this.rcost = _rcost ;

           
        }
        var sortVar = new Array();
       
        for ( c in CONFIGSET )
            sortVar[ sortVar.length ] = new reducedObject( c.index , z[c].reducedCost );


        // count non-basis
        var nonbasis = 0 ;
   

        for ( c in CONFIGSET )
            if ( z[c].reducedCost != 0.0 )
                 nonbasis = nonbasis + 1 ;

        var nbRate = nonbasis / ( CONFIGSET.size - nonbasis ) 
        writeln(" non-basis rate : " , nbRate   );

        var highRate = 1.2 ;
        var lowRate  = 1.0 ;
        if ( nbRate > highRate ){

            writeln("trim down non-basis columns to " , lowRate );

            // sorting 
            for ( var i = 0 ; i < ( sortVar.length - 1 ) ; i ++ )
            for ( var j = (i+1) ; j <  sortVar.length  ; j ++ )
            if ( sortVar[ i ].rcost > sortVar[ j ].rcost ) {

                var tmp = sortVar[ i ] ;
                sortVar[ i ]= sortVar[ j ] ;
                sortVar[ j ] = tmp ;


            } 
  
 
            var ndelete = Opl.floor( nonbasis - ( CONFIGSET.size - nonbasis ) * lowRate ) ;
            writeln("need to delete " , ndelete , " nonbasic column" );
            var ndeleted =  0;
            while ( ndeleted  < ndelete ) {

                var obj_del = sortVar[ sortVar.length-1 - ndeleted ] ;
                //writeln("remove index " , obj_del.index , " reduced cost : " , obj_del.rcost );    
                ndeleted = ndeleted + 1 ;
                filterCollection( CONFIGSET , "index" , obj_del.index , CONFIGSET_TMP );
            } 
            setNextModel("RELAXMASTER"); 
        }
	
	}
	

	if ( isModel("FINAL") ) {
        writeln();
        writeln("========================================");
        for ( c in CONFIGSET)
        if ( z[c].solutionValue > 0.5 ){
            writeln("configuration repeated : " , z[c].solutionValue );
            write("WORKING");
            for ( e in EDGESET )
                if ( c.working[e] == 1 ) write(":", e.id ) ; 
            writeln();
            write("PROTECT");
            for ( e in EDGESET )
                if ( c.protecting[e] == 1 ) write(":", e.id ) ; 
            writeln();
        }

        writeln("========================================");
        writeln();
		writeln("INTOBJ         :" , cplex.getObjValue());
		writeln("RELAXOBJ       :" , RELAXOBJ[ 0 ]  );
		writeln("GAP            :" , GAP( cplex.getObjValue()  , RELAXOBJ[0] )) ;
        writeln("USED WAVE      :" , usedwave );
        writeln("WORKING COST   :" , WCOST );
        writeln("PROTECT COST   :" , PCOST );
        writeln("USED CONFIGS   :" , NUSEDCONFIG );
	} 
    else
    if ( EXTRA_CALL[0] >= 2000 ) setNextModel("FINAL");

}
