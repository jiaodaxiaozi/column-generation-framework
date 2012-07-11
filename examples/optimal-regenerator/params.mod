

include "../../sysmsg.mod" ; // include this line in every global configuration file


tuple node_record  {

    string id ;
    float  pop;

};

{ node_record } NODESET = ...;


tuple undirected_edge_record {

    string id_va;
    string id_vb;

    float distance;
};

{ undirected_edge_record }  UNDIRECTED_EDGESET = ...;

tuple directed_edge_record {

    string src ;
    string dst ;
    float  distance ;

}

{ directed_edge_record }  DIRECTED_EDGESET    = ... ;


int PERIOD = ...;
int KPATH_PARAM = ... ;
{int} BITRATE = { 10 , 40 , 100 };  // bitrate
{int} TRSET = { 750 , 1500 , 3000 }; // transmission range

float REGENERATOR_COST[ BITRATE ][ TRSET ] = ...;

tuple demand_record {

    int period ;
    int bitrate ;
    string src ;
    string dst ;
    int nrequest ;
};

{ demand_record } DEMAND =...;

float SEED_TRAFFIC = ... ; 


tuple SRCDST_record {

    string id_src ;
    string id_dst ;

}


{ SRCDST_record }  K_SDSET = ... ;


tuple path_record {

    int    index ;
    string src ;
    string dst ;
    float  pathLength ;
}

tuple path_edge_record {

    int indexPath ;
    int indexEdge ;
}


{ path_record } SINGLEHOP_SET = ... ; 
{ path_edge_record } SINGLEHOP_EDGESET = ... ;

