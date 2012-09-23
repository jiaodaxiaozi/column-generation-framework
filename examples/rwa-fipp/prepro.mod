include "params.mod";

execute {

    setModelDisplayStatus( 1 );

    writeln("START PRE-PROCESSING");
    writeln("Number of nodes : " , NODESET.size );
    writeln("Number of edges : " , EDGESET.size );
    writeln("Number of demands : " , DEMAND.size );
}
