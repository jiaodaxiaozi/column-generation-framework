/*********************************************
 * COLUMN GENERATION SOLVER SYSTEM
 *
 * (C) Hoang Hai Anh, 2011
 * Email : hoanghaianh@gmail.com
 *
 *********************************************/

include "plugins.mod" ; 
 
string input = "" ;

  
main {

/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * CONSTANTS
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/

var parameter_file    = "params.mod" ;
var model_define_file = "model.ini"  ;    
var __START__           = "START" ;
var __RELAX__           = "RELAX" ;
var __FINAL__           = "FINAL" ;

		
/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * DEFINE MIP MODEL CLASS 
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/

 function MIPMODEL( id , fname , relax ){
 
	//// CONSTRUCTOR ////
	
	assertExisted( fname );
 
	this.mipid          = id   ; // id of this model
	this.mipsource 		= new IloOplModelSource( fname ); // init source file 
	this.mipdefinition	= new IloOplModelDefinition( this.mipsource ); // init definition	
	this.mipsolver		= new IloCplex() ; // init solver
	
	this.ncall          = 0    ; // number of calling time
	this.acctime        = 0    ; // accumulated running time in seconds
	this.solvetime      = 0    ; // solving time 
	this.obj            = 0    ; // return objective  , null if not success
	this.relax          = relax; // relax this model or not
			
	// methods
	this.mipsolve 		= mipsolve	;

			
 }

 //// SOLVING MODEL ////
 function mipsolve(  ) {
 
 	var timeMark = timeMarker(); // mark time moment
	this.ncall ++ ; // update number of calling 
	this.mipsolver.clearModel(); // reset model
	var theopl = new IloOplModel( this.mipdefinition , this.mipsolver ) ;  // create execution object	
	
	// reset next model
	globalData._NEXT_MODEL_  = "" ;	
	
	theopl.addDataSource( globalData ) ;	// add data source 
	theopl.generate() ; // generate execution object
	
	if ( this.relax )	theopl.convertAllIntVars() ;	// relax model
	
	if ( this.mipsolver.solve() )  {
	
		this.obj = this.mipsolver.getObjValue(); // get objective 		
		theopl.postProcess() ;  // call post process	

	}	else	this.obj = null; // null if unsuccessful
	
	globalData._MODEL_  = theopl._NEXT_MODEL_  ;	// next model to solve
	
	// update information
	this.solvetime = elapsedTime( timeMark ); // running time
	this.acctime += this.solvetime ; // accumulated running time				
	
	theopl.end(); // clear execution object
	
	// display result
	write( AVATAR() , " solve " + this.mipid  + " (\"" + this.mipsource.name + "\"" + ( this.relax ? ",\"relax\"" : "" ) + ") => " );
	write( " number called: " , this.ncall , " runtime: ", this.solvetime , " acc. time: " , this.acctime  );
	writeln(" obj: " , this.obj  );
	writeln();
	
	
 } 
 


/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * FUNCTIONS
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/




//// INDEX OF MODEL BY NAME ////

function indexModel( m ) {
	
	// find execute model		
	for ( var i = 0 ; i < lstModel.length ; i ++ )
	if (  lstModel[i].mipid == m )
		return lstModel[ i ] ;
			
	return null ;
}

///// ASSERT EXIST MODEL ///
function assertModel( m ) {

	if ( indexModel(m)==null ) {
	
		writeln( AVATAR() , " no model with id: " ,m , " !" );
		writeln();
		stop();
	}
	
}


//// READ MODEL DEFINITION FILE ////
function readModelDefinition() {

	var  TERM_MODEL = "MODEL" ;
	var  TERM_RELAX = "RELAX" ;
	
	var f = new IloOplInputFile( );
	f.open(model_define_file );
	
	writeln();
	lineSep(" MODEL DEFINTION ",".");
	writeln();
	
    while (!f.eof) {
      
	  var line  = f.readline();	  // one line 
	  var pieces = line.split(" "); // split into term
	  
	  var terms = new Array();

	  for ( var i = 0 ; i < pieces.length ; i ++ ){
	   
	    // not empty term
		if ( pieces[i].length ) terms[ terms.length ] = pieces[ i ] ;

	  }
	  
	  // [MODEL] //
	  if ( terms[0] == TERM_MODEL ) {
	   
	    var isrelax ;
	    if ( terms[3] == null ) isrelax = false ; else isrelax = terms[3].toUpperCase() == TERM_RELAX ;
	    
		writeln( "[" + terms[0] + "]" , " >>> " ,terms[1] , " >>> " , terms[2] , " : " , isrelax ? "relax" : "norelax"  );		
		lstModel[ lstModel.length ] = new MIPMODEL( terms[1] , terms[2] , isrelax ); // create model
		
	  }

    } // end while

	f.close();	
	
	
}
	
/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * DISPLAY STARTING INFORMATION
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/

	lineSep(" COLUMN GENERATION SOLVER ","=") ;
	writeln();	
	writeln();
	
	if ( thisOplModel.input == "" ) {   writeln( AVATAR() , "  input need to be specified ( -D input=filename ) " ); writeln(); stop(); }	
	
	writeln( AVATAR() , " INPUT        : " , thisOplModel.input );
	
	assertExisted(  model_define_file );
	assertExisted(  parameter_file );
	
	writeln( AVATAR() , " PARAMETER    : " , parameter_file );
	writeln( AVATAR() , " MODEL DEFINE : " , model_define_file );
		
	
/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * INIT MODELS & DATA
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/
	
	
	// create user data	
	var _userData = new IloOplDataSource( thisOplModel.input); 
	
	// create system data
	var _sysData = new IloOplDataElements();
	
	// init system variable
	_sysData._MODEL_       = __START__ ;	
	_sysData._NEXT_MODEL_  = "" ;	

	
	// load global data
	var globalSource = new IloOplModelSource( parameter_file );
	var globalDef    = new IloOplModelDefinition( globalSource );	
	var globalOpl    = new IloOplModel( globalDef , cplex ) ;
	
	globalOpl.addDataSource( _userData );
	globalOpl.addDataSource( _sysData  );				
	globalOpl.generate();
			
	// create global data
	var globalData = globalOpl.dataElements ;
	
	// create list of models
	var lstModel = new Array();
	
	
 
/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * SOLVING MODELS
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/

 readModelDefinition(); // read model definition 
 
 assertModel( __START__ );
 assertModel( __RELAX__ );
 assertModel( __FINAL__ );
 
 var   starting_process_moment =  timeMarker(); 
 
 while ( globalData._MODEL_ ){
 	
	var callModel = indexModel( globalData._MODEL_ );
	
	// not found any model
	if ( callModel == null ) {
	  writeln( AVATAR() , " no model with id: " , globalData._MODEL_ , " !" );
	  stop();
	} else callModel.mipsolve();
		
	
 } // end while
 
 
 

/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * SUMMARY
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/


 
// get relax solution 

globalData._MODEL_ = __RELAX__ ;
var relaxModel = indexModel( globalData._MODEL_ );
relaxModel.mipsolve();
var relaxObj = relaxModel.obj ;

// get final solution
globalData._MODEL_ = __FINAL__ ;
var finalModel = indexModel( globalData._MODEL_ );

finalModel.mipsolve();
var intObj   = finalModel.obj ;

var elapsed_runtime = elapsedTime( starting_process_moment );

lineSep(" PERFORMANCE INFORMATION " ,"=" );
writeln();

writeln("RELAX-SOLUTION : " , relaxObj );
writeln("INT-SOLUTION   : " , intObj );
writeln("SOLUTION-GAP   : " , GAP( relaxObj , intObj ) );	
writeln("RUNTIME        : " , elapsed_runtime );
writeln();
lineSep("" ,"-");	
writeln();

// estimate size
var m ;
var model ;


function maxLength( n, st  ) {

  return  n < st.toString().length ? st.toString().length : n ;
}

var txt_id_size = maxLength( 0 , "MODEL" );
var txt_call_size = maxLength( 0 , "CALL" );
var txt_total_size = maxLength( 0 , "TOTAL-TIME" );
var txt_mean_size = maxLength( 0 , "MEAN-TIME" );
var txt_relax_size = maxLength( 0 , "RELAX" );
var txt_source_size = maxLength( 0 , "SOURCE" );

for ( m = 0 ; m < lstModel.length ; m++ ){

	model = lstModel[ m ] ;
	
	txt_id_size   = maxLength( txt_id_size , model.mipid ) ;    
	txt_call_size = maxLength( txt_call_size , model.ncall ) ; 	
	txt_total_size= maxLength( txt_total_size , model.acctime ) ; 	
	txt_mean_size= maxLength( txt_mean_size , model.acctime /  model.ncall  ) ; 	
	txt_relax_size= maxLength( txt_relax_size , model.relax  ) ; 	
	txt_source_size= maxLength( txt_source_size , model.mipsource.name  ) ; 	
}

leftWrite( "MODEL" , txt_id_size + 1 );
leftWrite( "CALL" , txt_call_size + 1); 
leftWrite( "TOTAL-TIME" , txt_total_size + 1 );
leftWrite( "MEAN-TIME" , txt_mean_size + 1 );
leftWrite( "RELAX" , txt_relax_size + 1 );
leftWrite( "SOURCE" , txt_source_size + 1 );

writeln();

leftWrite( "-----" , txt_id_size + 1 );
leftWrite( "----" , txt_call_size + 1 ); 
leftWrite( "----------" ,txt_total_size + 1 ); 
leftWrite( "---------" , txt_mean_size + 1 );
leftWrite( "-----" , txt_relax_size + 1 );
leftWrite( "------" , txt_source_size + 1 );
writeln();

for ( m = 0 ; m < lstModel.length ; m++ ){

 model = lstModel[ m ] ;

leftWrite( model.mipid , txt_id_size + 1 );
leftWrite( model.ncall , txt_call_size + 1 );
leftWrite( model.acctime ,txt_total_size + 1 );
leftWrite( model.acctime /  model.ncall ,txt_mean_size + 1 ); 
leftWrite( model.relax ,txt_relax_size + 1 );
leftWrite(  model.mipsource.name ,txt_source_size + 1 );
writeln();

}
	

writeln();
lineSep("" ,"-");	


}
 
