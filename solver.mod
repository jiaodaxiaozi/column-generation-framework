/*********************************************
 * COLUMN GENERATION SOLVER SYSTEM
 *
 *
 * Author: Hoang Hai Anh
 * Email : hoanghaianh@gmail.com
 *
 *********************************************/

string input = "" ;

  
main {

/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * PLUGINS 
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/


var sys_avatar      = "[^_^]" ;	
	
function line_sep( ) {
	
	for ( var i = 1 ; i <= 80 ; i ++ ) write("-" );writeln();
	
}
	
	

function  timeMarker() {

	return (new Date());
}

function elapsedTime( previous ) {

	var currentMoment = new Date();
	return Opl.round(( currentMoment - previous ) / 1000.0 );
}
	
	
/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * DISPLAY STARTING INFORMATION
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/

	line_sep() ;
	writeln();
	writeln("COLUMN GENERATION SOLVER");
	writeln();
	
	if ( thisOplModel.input == "" ) {   writeln( sys_avatar , " : input need to be specified ( -D input=filename ) " ); writeln(); stop(); }
	
	writeln( sys_avatar , " INPUT      : " , thisOplModel.input );
	
		
	writeln();
	line_sep();
	writeln();
	
	// create user data	
	var _userData = new IloOplDataSource( thisOplModel.input); 
	
	// create system data
	var _sysData = new IloOplDataElements();
	
	// init system variable
	_sysData.PROBLEM_STATUS = "" ;
	_sysData.PRICING_STATUS = "" ;
	_sysData.CALLBACK       = "INIT" ;
	
	// create global data
	var globalSource = new IloOplModelSource( "params.mod" );
	var globalDef    = new IloOplModelDefinition( globalSource );	
	var globalOpl = new IloOplModel( globalDef , cplex ) ;
	
	globalOpl.addDataSource( _userData );
	globalOpl.addDataSource( _sysData  );
		
		
	globalOpl.generate();
			
	// create global data
	var globalData = globalOpl.dataElements ;
	
	globalData.CALLBACK = "" ;
	
	function copySystemStatus( opl ){
	
		globalData.PROBLEM_STATUS  = opl.PROBLEM_STATUS  ;
		globalData.PRICING_STATUS  = opl.PRICING_STATUS  ;
		globalData.CALLBACK        = opl.CALLBACK        ;
	
	}
	
		
	var price_file   = "price.mod"  ;
	var master_file  = "master.mod" ;

	

/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * EXECUTE AN EXTERNAL MODEL
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/

	
function exec_model( prepro_file ){

	var f = new IloOplInputFile( prepro_file );
	
	if ( ! f.exists ) {
	
		writeln( sys_avatar , " not existed " , prepro_file , " ! " );
		fail();
	}
	
	f.close();

	// creating & solving prepro-file
	var preproSource = new IloOplModelSource( prepro_file );
	var preproDef    = new IloOplModelDefinition( preproSource );
	var preproSolver = new IloCplex();		
	var preproOpl = new IloOplModel( preproDef , preproSolver ) ; 	

	var mark = timeMarker();
		
	preproOpl.addDataSource( globalData );
	preproOpl.generate() ;       
	
 
	if ( !  preproSolver.solve() ) {

		writeln( sys_avatar , " cannot execute " , prepro_file );
		fail();
	}
	preproOpl.postProcess() ;
	
	copySystemStatus( preproOpl );
		
	preproOpl.end();
	preproDef.end();
	preproSolver.end();
	preproSource.end();

	writeln(sys_avatar ," : " , prepro_file, " took " , elapsedTime( mark ) , " seconds" );
	
	

}


		
	
/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * PREPARING 
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/

	var masterSolver = new IloCplex();
	var priceSolver = new IloCplex();


	// creating master-model

	var masterSource = new IloOplModelSource( master_file );
	var masterDef    = new IloOplModelDefinition( masterSource ); 

	// creating price-model


	var priceSource = new IloOplModelSource( price_file );
	var priceDef    = new IloOplModelDefinition( priceSource );

	



/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * SOLVE RELAX MASTER FUNCTION
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/
var accumulate_master_time = 0;
var number_master_calling  = 0;

function solve_relax_master() {

	// solve master  
	
	
	var masterMark = timeMarker() ;

	masterSolver.clearModel();

	var masterOpl = new IloOplModel( masterDef , masterSolver ) ; 
	
	masterOpl.addDataSource( globalData ) ;	
	masterOpl.generate() ;
	masterOpl.convertAllIntVars() ;

	
	if ( ! masterSolver.solve() ) {
 	
		writeln( sys_avatar , " relax master have no solution ");
		fail() ;  
		
	}

	masterOpl.postProcess() ; 
	
	var obj = masterSolver.getObjValue();
	
	copySystemStatus( masterOpl );
	
	masterOpl.end();


	writeln(sys_avatar , " : master runtime = " , elapsedTime( masterMark ) );

	accumulate_master_time += elapsedTime( masterMark ) ; 
	number_master_calling  ++ ;
	
	return obj ;

}

/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * SOLVE RELAX PRICING FUNCTION
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/

var accumulate_price_time = 0;
var number_price_calling  = 0;


function solve_price( pDef ) {

	// solve pricing

	var priceMark = timeMarker() ;

	globalData.PRICING_STATUS = "START" ; 
	

	while ( globalData.PRICING_STATUS != "STOP" ) {

		priceSolver.clearModel();	
		var priceOpl = new IloOplModel( pDef , priceSolver ) ; 	
	
		priceOpl.addDataSource( globalData ) ;	
		priceOpl.generate() ;
	
		// no more column, stop
		if (  ! priceSolver.solve()   ){  	

			priceOpl.end() ;
			return 0 ;
		
		} 		

		// call post process	
		priceOpl.postProcess() ;
		
		copySystemStatus( priceOpl ) ;
		
		priceOpl.end() ;
		
		

	} // end while 

	writeln(sys_avatar , " : price runtime = " , elapsedTime( priceMark ) );
	
	accumulate_price_time += elapsedTime( priceMark ) ;
	number_price_calling ++;

	return 1 ;	

};


/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * SOLVE RESTRICTED MASTER PROBLEM
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/

	var startRelaxMark = timeMarker();

	
	globalData.PROBLEM_STATUS = "RELAX" ;
	
	var relaxObj = solve_relax_master() ;
	
	
	while ( solve_price( priceDef ) ){
		
		relaxObj = solve_relax_master();
		
	}

	
	var relax_process_time = elapsedTime( startRelaxMark );

	writeln( "-------------------- FINISHED RELAX SOLVING  --------------------" );

	



/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * SOLVE ILP RESTRICTED MASTER PROBLEM
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/
	var startIntMark = timeMarker() ;

	globalData.PROBLEM_STATUS = "INTEGER" ;

	masterSolver.clearModel() ;

	var restrictedMaster = new IloOplModel( masterDef , masterSolver ) ; 	

	restrictedMaster.addDataSource( globalData ) ;	
	restrictedMaster.generate() ;

	if ( ! masterSolver.solve() ) {
	
			writeln("** mip master have no solution ");
			writeln(restrictedMaster.printConflict() );
			fail() ;  
	}

	var intObj = masterSolver.getObjValue();

	restrictedMaster.postProcess();		
	restrictedMaster.end() ;

	var int_process_time = elapsedTime( startIntMark ) ;


/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * PROVIDE PERFORMANCE INFORMATION
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/


	writeln( "------------------- PERFORMANCE INFORMATION  -------------------" );

	writeln("RELAX OBJ = " , relaxObj );	
	writeln("INT   OBJ = " , intObj );
	
	var gap = Opl.abs( intObj - relaxObj ) / ( Opl.abs( relaxObj ) + 1.0e-6 ) * 100.0;	
	writeln("GAP       = " , gap );
	writeln();
	writeln("RELAX RUNTIME = " , relax_process_time  , " seconds");
	writeln("INT   RUNTIME = " , int_process_time  , " seconds");
	writeln("TOTAL RUNTIME = " , relax_process_time + int_process_time , " seconds" );
	writeln();
	writeln("MASTER ITERATION = " , number_master_calling );
	writeln("AVE. MASTER TIME = " , accumulate_master_time / number_master_calling , " seconds" );	
	writeln("PRICE  ITERATION = " , number_price_calling );
	writeln("AVE. PRICE TIME  = " , accumulate_price_time / number_price_calling , " seconds" );

	writeln( "----------------------------------------------------------------" );
	
	writeln();


}
 
