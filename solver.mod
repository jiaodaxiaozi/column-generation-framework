/*********************************************
 * COLUMN GENERATION SOLVER SYSTEM
 *
 * (C) Hoang Hai Anh, 2011
 * Email : hoanghaianh@gmail.com
 *
 *********************************************/

string input = "" ;

  
main {

/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * CONSTANTS
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/


var sys_avatar        = "[:)]" ;	
var parameter_file    = "params.mod" ;
var model_define_file = "model.ini"  ;    


		
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
 
	this.mipid          = id ; // id of this model
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
	
	// reset state	
	globalData._NEXT_MODEL_  = "" ;	
	globalData._NOSOL_MODEL_  = "" ;	
	
	theopl.addDataSource( globalData ) ;	// add data source 
	theopl.generate() ; // generate execution object
	
	if ( this.relax )	theopl.convertAllIntVars() ;	// relax model
	
	if ( this.mipsolver.solve() )  {
	
		this.obj = this.mipsolver.getObjValue(); // get objective 		
		theopl.postProcess() ;  // call post process	
		globalData._MODEL_  = theopl._NEXT_MODEL_  ;	// next model to solve
	}
	else {
		this.obj = null; // null if unsuccessful
		globalData._MODEL_ = theopl._NOSOL_MODEL_
	}			
	
	// update information
	this.solvetime = elapsedTime( timeMark ); // running time
	this.acctime += this.solvetime ; // accumulated running time				
	
	theopl.end(); // clear execution object
	
	// display result
	write( sys_avatar , " solve " + this.mipid  + " (\"" + this.mipsource.name + "\"" + ( this.relax ? ",\"relax\"" : "" ) + ") => " );
	write( " number called: " , this.ncall , " runtime: ", this.solvetime , " acc. time: " , this.acctime  );
	writeln(" obj: " , this.obj  );
	writeln();
	
	
 } 
 


/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * PLUGINS 
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/



//// LINE SEPARATOR //// 
var half_line_sep_length = 50 ;
	
function lineSep( label  , sep ) {

	var halflen  =  half_line_sep_length -  label.length / 2 ;
	var i ;
	for ( i = 1 ; i <= halflen ; i ++ ) write( sep );
	write( label );
	
	for ( i = 1 ; i <= halflen ; i ++ ) write( sep );	
	writeln();
	
}
	
//// MARK TIME MOMENT ////
function  timeMarker() {

	return (new Date());
}

//// ELAPSED TIME FROM MARKED ////
function elapsedTime( previous ) {

	var currentMoment = new Date();
	return Opl.round(( currentMoment - previous ) / 1000.0 );
}

//// COMPUTE GAP BETWEEN TWO NUMBERS ////	
function GAP( relaxObj , intObj ) {	
	
	return Opl.abs( intObj - relaxObj ) / ( Opl.abs( relaxObj ) + 1.0e-6 ) * 100.0;		
	
}

//// ASSERT EXISTED FILE ////

function assertExisted( fname ) {

	// check existed file ?
	var f = new IloOplInputFile( fname );
	
	if ( ! f.exists ) {
	
		writeln( sys_avatar , " " , fname , " does not exist ! " );
		writeln();
		stop();
	}
	
	f.close();
}

//// INDEX OF MODEL BY NAME ////

function indexModel( m ) {
	
	// find execute model		
	for ( var i = 0 ; i < lstModel.length ; i ++ )
	if (  lstModel[i].mipid == m )
		return lstModel[ i ] ;
			
	return null ;
}

//// READ MODEL DEFINITION FILE ////
function readModelDefinition() {

	
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
	  
	  // [MODEL]
	  if ( terms[0] == "MODEL" ) {
	  
		writeln( "[" + terms[0] + "]" , " >>> " ,terms[1] , " >>> " , terms[2] , " : " , terms[3] );		
		lstModel[ lstModel.length ] = new MIPMODEL( terms[1] , terms[2] , terms[3].toUpperCase() == "RELAX" ); // create model
		
	  }
	  
	  // [START]
	  if ( terms[0] == "START" ) {
	  		
		writeln(  "[" + terms[0] + "]" , " >>> "  , terms[1]  );		
		globalData._MODEL_ = terms[1]; // starting model
	  
	  }
	  
	  // [FINAL]
	  if (  terms[0] == "FINAL" ) {
	  
		writeln(  "[" + terms[0] + "]" , " >>> "  , terms[1] , " >>> "  , terms[2]   );		  
		
		final_relax_id = terms[1] ;
		final_int_id   = terms[2] ;
		
		
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
	
	if ( thisOplModel.input == "" ) {   writeln( sys_avatar , "  input need to be specified ( -D input=filename ) " ); writeln(); stop(); }	
	
	writeln( sys_avatar , " INPUT        : " , thisOplModel.input );
	
	assertExisted(  model_define_file );
	assertExisted(  parameter_file );
	
	writeln( sys_avatar , " PARAMETER    : " , parameter_file );
	writeln( sys_avatar , " MODEL DEFINE : " , model_define_file );
		
	
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
	_sysData._MODEL_  = "" ;	
	_sysData._NEXT_MODEL_  = "" ;	
	_sysData._NOSOL_MODEL_  = "" ;	
	
	// load global data
	var globalSource = new IloOplModelSource( parameter_file );
	var globalDef    = new IloOplModelDefinition( globalSource );	
	var globalOpl = new IloOplModel( globalDef , cplex ) ;
	
	globalOpl.addDataSource( _userData );
	globalOpl.addDataSource( _sysData  );				
	globalOpl.generate();
			
	// create global data
	var globalData = globalOpl.dataElements ;
	
	// create list of models
	var lstModel = new Array();
	
	var final_relax_id     = "" ; 	// relax master problem
	var final_int_id       = "" ; 	// restricted master problem
 
/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * SOLVING MODELS
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/

 readModelDefinition(); // read model definition 
 
 
 while ( globalData._MODEL_ ){
 	
	var callModel = indexModel( globalData._MODEL_ );
	
	// not found any model
	if ( callModel == null ) {
	  writeln( sys_avatar , " no model with id: " , globalData._MODEL_ , " !" );
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

 lineSep(" PERFORMANCE INFORMATION " ,"=" );
 
var relaxModel = indexModel( final_relax_id );
var relaxObj = relaxModel.obj ;
var intModel = indexModel( final_int_id );
var intObj   = intModel.obj ;

writeln("RELAX OBJ : " , relaxObj );
writeln("INT OBJ   : " , intObj );

writeln("GAP       : " , GAP( relaxObj , intObj ) );	
	

	





}
 
