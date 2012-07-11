/*********************************************
 * COLUMN GENERATION SOLVER SYSTEM
 *
 * (C) Hoang Hai Anh, 2011
 * Email : hoanghaianh@gmail.com
 *
 *********************************************/

include "plugins.mod" ; 
 
string input = "" ;
string output= "" ;

tuple _MODEL_RECORD_ {

    string  id ;
    string  fname ;
    int     relax ; 
    
};

{ _MODEL_RECORD_ } MODELSET = ... ;

 
main {



/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * CONSTANTS
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/

var parameter_file    = "params.mod"  ;
var parameter_data    = "params.dat"  ;
var __ROOT__          = "ROOT"        ;

var runCplex          = new IloCplex(); // for saving default parameters


/////// SETTING NEXT STATE //////////
function nextState( nextObj , curObj ) {

    if ( curObj == null ) {
    
        nextObj._NEXT_MODEL_  = "" ;    
        nextObj._MODEL_DISPLAY_STATUS_= 0  ;    
	
    } else {
   
        nextObj._MODEL_       = curObj._NEXT_MODEL_ ;    
        nextObj._MODEL_DISPLAY_STATUS_= curObj._MODEL_DISPLAY_STATUS_  ;
    }

     nextObj._OUTFILE_ = thisOplModel.output ; 
}
    
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
    this.mipsource      = new IloOplModelSource( fname ); // init source file 
    this.mipdefinition  = new IloOplModelDefinition( this.mipsource ); // init definition    
    
    this.ncall          = 0    ; // number of calling time
    this.acctime        = 0    ; // accumulated running time in seconds
    this.solvetime      = 0    ; // solving time 
    this.relax          = relax; // relax this model or not


            
 }


 //// SOLVING MODEL ////
function mipsolve ( THEMODEL ) {
 
    var timeMark = timeMarker(); // mark time moment
    THEMODEL.ncall ++ ; // update number of calling 

    // set model's parameters to default
    cplex.clearModel();
    for ( var p in cplex ){
      cplex[ p ] = runCplex[ p ]	
    }

    cplex.tilim = 3600 * 48;  // 2 days solving 
    cplex.epgap = 0.01 ;      // 1 percent


    /*
    cplex.workmem = 1024 * 20  ;
    cplex.nodefileind = 3 ;
    cplex.trelim  = 1024 * 40 ;*/ 

    cplex.parallelmode = -1 ; // opportunistic mode
    cplex.threads = 0 ; // use maximum threads

    var theopl         = new IloOplModel( THEMODEL.mipdefinition , cplex ) ;  // create execution object    

    theopl.settings.mainEndEnabled = true ;
 
    // reset next model
    nextState( globalData , null );
    
    theopl.addDataSource( globalData ) ;    // add data source 
    theopl.generate() ; // generate execution object
    
    if ( THEMODEL.relax )    theopl.convertAllIntVars() ;    // relax model
    
    if ( cplex.solve() )      
        theopl.postProcess() ;  // call post process    

    // next model to solve
    nextState( globalData , theopl );
 
    // update information
    THEMODEL.solvetime = elapsedTime( timeMark ); // running time
    THEMODEL.acctime += THEMODEL.solvetime ; // accumulated running time                
 
    
    // display result
    if ( globalData._MODEL_DISPLAY_STATUS_ > 0 ) {
        write( AVATAR() , " solve " + THEMODEL.mipid  + " (\"" + THEMODEL.mipsource.name + "\"" + ( THEMODEL.relax ? ",\"relax\"" : "" ) + ") => " );
        writeln( " called: " , THEMODEL.ncall , " runtime: ", THEMODEL.solvetime , " acc. time: " , THEMODEL.acctime  );    
    }
   
 
    theopl.end();
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
      
    // load model definition
    for ( var md in thisOplModel.MODELSET )
    {
        writeln( "[MODEL]" , " >>> " , md.id  , " >>> " , md.fname , " " , md.relax > 0 ? "(relax)" : ""  );        
        lstModel[ lstModel.length ] = new MIPMODEL( md.id , md.fname , md.relax > 0 ); // create model
    }

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
    
	writeln( AVATAR() , " PATH         : " , getPWDPath() );	
    writeln( AVATAR() , " INPUT        : " , thisOplModel.input  );
    
    if ( thisOplModel.output != "" ){		
		writeln( AVATAR() , " OUTPUT       : " , thisOplModel.output ); 
    }
   
        

    assertExisted(  parameter_file );
	assertExisted(  parameter_data );
    assertExisted(  thisOplModel.input );    

    writeln( AVATAR() , " PARAMETER DEFINITION   : " , parameter_file );
	writeln( AVATAR() , " PARAMETER DATA         : " , parameter_data );
    

    
/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * INIT MODELS & DATA
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/
    
    
    // create user data    
    var _userData = new IloOplDataSource( thisOplModel.input); 
	
	// create parammeter data
	var _paramData = new IloOplDataSource( parameter_data ); 
    
    // create system data
    var _sysData = new IloOplDataElements();
    
    nextState( _sysData , null );

     _sysData._MODEL_    = __ROOT__ ;

    
    // load global data
    var globalSource = new IloOplModelSource( parameter_file );
    var globalDef    = new IloOplModelDefinition( globalSource );    
    var globalOpl    = new IloOplModel( globalDef , cplex ) ;
    
    globalOpl.addDataSource( _userData );
	globalOpl.addDataSource( _paramData );
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
 
 empty_output();
 
 assertModel( __ROOT__ );

 
 var   starting_process_moment =  timeMarker(); 
 
 lineSep(" PROCESSING " , "=" );
 writeln();
 while ( globalData._MODEL_ ){
     
    var callModel = indexModel( globalData._MODEL_ );
    
    // not found any model
    if ( callModel == null ) {
      writeln( AVATAR() , " no model with id: " , globalData._MODEL_ , " !" );
      stop();
    } else mipsolve( callModel );
      

    
 } // end while
 
 
 

/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * SUMMARY
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/


 

var elapsed_runtime = elapsedTime( starting_process_moment );

lineSep(" PERFORMANCE INFORMATION " ,"=" );
writeln();

// estimate size
var m ;
var model ;



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
leftWrite( model.mipsource.name ,txt_source_size + 1 );

	writeln();
	
	output_section( "RUNTIME-" + model.mipid );
	output_value( "CALL" , model.ncall );
	output_value( "TOTALTIME" , model.acctime );

}
  
writeln();
lineSep("" ,"-");    
writeln("OVERALL-RUNTIME: " , elapsed_runtime );
lineSep("" ,"-");    
writeln();

output_section( "RUNTIME" );
output_value( "TOTALTIME" , elapsed_runtime );

// free memory
runCplex.end();

} 
