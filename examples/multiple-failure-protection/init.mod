include "params.mod";



execute {

  writeln("START COLUMN GENERATION " );
  lineSep("","-");
  writeln("");
  writeln("verify input...");
  
  checkInput();
  writeln("number of nodes    : " , nodeset.size );
  writeln("nubmer of edges    : " , edgeset.size );
  writeln("number of requests : " , requestset.size );
  writeln("number of failure  : " , nfailure );
  writeln();
  
  TEMPVAR[ 0 ] = 0;
  setNextModel("REMOVE");
}

