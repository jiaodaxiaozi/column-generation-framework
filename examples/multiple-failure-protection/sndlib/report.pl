use strict;

use File::Basename;
use Text::Table;
use LaTeX::Table;
use Chart::Gnuplot;


#---------------------------------------------------------------------------------------------------------
#
# CREATE NETWORK DESCRIPTION TABLE
# 
#---------------------------------------------------------------------------------------------------------


my $delimiter = "[ (),]+" ;
my $mysep = "|" ;

# get all .rwa file in RWA
print "----------------------------------\n" ;
print "Creating Network Description Instances\n" ;
print "----------------------------------\n" ;

opendir(DIR, "RWA");
my @rwafiles = grep(/\.rwa$/,readdir(DIR));
closedir(DIR);


open (NETTABLE , ">./REPORT/netdesc.table" );

my $tabnet = Text::Table->new($mysep , "NETWORK" , $mysep , "NODE" , $mysep , "EDGE" ,
				$mysep ,"DEGREE" , $mysep , "REQUEST" , $mysep , "CONNECTION" , $mysep, "CONNECT/REQUEST" ,$mysep );

my @latexheader = ( [ 'NETWORK', 'NODE', 'EDGE' , 'DEGREE' , 'REQUEST' , 'CONNECTION' , 'CONNECT/REQUEST'  ] );
my @latexdata   = ( );

				
foreach my $file (@rwafiles) {
   print "processing: $file\n";

	# get network name
   my $netname = uc basename( $file , ".rwa" );
      
   my $nnode = 0 ;
   my $nedge = 0 ;
   my $nrequest = 0 ;
   my $nconnect = 0 ;
   
        open (TMPFILE, "<./RWA/$file" );

   	while (my $record = <TMPFILE>) {
		if ( $record =~ m/^NODE/ ) { $nnode ++ ; }
		if ( $record =~ m/^EDGE/ ) { $nedge ++ ; }
		if ( $record =~ m/^REQUEST/ ) {
			$nrequest ++ ; 
			
			my @fields = split($delimiter, $record);
			$nconnect += $fields[3] ;
		}
		
	}
	my $aveconnect = sprintf("%.2f" , $nconnect / $nrequest ) ;
	my $avedegree  = sprintf("%.2f" , 2.0 * $nedge / $nnode ) ;

	$tabnet->add( $mysep, $netname , $mysep, $nnode , $mysep , $nedge , $mysep ,
				  $avedegree , $mysep , $nrequest , $mysep , $nconnect , $mysep , $aveconnect , $mysep );		
	
	 push @latexdata , [ $netname , $nnode , $nedge , $avedegree , $nrequest , $nconnect , $aveconnect ];
	
	close(TMPFILE);

}


print NETTABLE $tabnet->rule("-","+");
print NETTABLE $tabnet->title();
print NETTABLE $tabnet->rule("-","+");
print NETTABLE $tabnet->body();
print NETTABLE $tabnet->rule("-","+");

close(NETTABLE);

 my $latextable = LaTeX::Table->new(
        {   
        filename    => './REPORT/nettable.tex',
        caption     => 'Description of Network Instances',
        label       => 'tab:instances',
        position    => 'h',
        header      => \@latexheader,
        data        => \@latexdata,
        }
 );
 
 $latextable->generate();

#---------------------------------------------------------------------------------------------------------
#
# CREATE OUTPUT DESCRIPTION
# 
#---------------------------------------------------------------------------------------------------------
 
print "----------------------------------\n" ;
print "Create Output Result Description \n" ;
print "----------------------------------\n" ;

opendir(DIR, "OUT");
my @outfiles = grep(/\.out$/,readdir(DIR));
closedir(DIR);

open (OUTTABLE , ">./REPORT/netout.table" );


my $tabout = Text::Table->new( $mysep , "NETWORK" ,$mysep , "DF-PERCENT" , $mysep , "RELAX OBJ" , $mysep , "INT OBJ" , $mysep , "GAP" , 
							   $mysep ,	"#GEN CONFIG" , $mysep , "# SELECTED CONFIG" , $mysep , "KEEP CONFIG" , $mysep, "RELAX TIME" , $mysep , "TOTAL TIME" ,$mysep);


my @latexheader = ( [ '\hline INSTANCE', 'D-FAILURE', 'GAP' , '\#CONFIGs' , '\#S-CONFIGs' ] );
my @latexdata   = ( );

my @qualitydata = () ;




my $dfcurve_chart = Chart::Gnuplot->new(
		gnuplot => "wgnuplot.exe",		
        output => "./REPORT/dualfailure-protectcapacity.eps",
        title  => "",
        xlabel => "PERCENTAGE OF DUAL FAILURES",
        ylabel => "PROTECTION OVER WORKING RATIO",      
		
		xrange => [0, 100],
		xtics    => {
             labels   => [0,10,20,30,40,50,60,70,80,90,100],
        },		
		
		yrange => [0, 1.8],
		
	    legend => {
			position => "inside bottom",
		}
		

    );

my $dfnsol_chart = Chart::Gnuplot->new(
		gnuplot => "wgnuplot.exe",		
        output => "./REPORT/nsol.eps",
        title  => "",
        xlabel => "PERCENTAGE OF DUAL FAILURES",
        ylabel => "SELECTED CON. OVER GENERATED CON. RATIO",      
		
		xrange => [0, 100],
		xtics    => {
             labels   => [0,10,20,30,40,50,60,70,80,90,100],
        },		
		
		yrange => [0, 0.3],
		
	    legend => {
			position => "inside top",
		}
		

    );
	
my @atlantax = () ;
my @atlantay = () ;
my @atlantas = () ;

my $atlantadataset = Chart::Gnuplot::DataSet->new(
        xdata => \@atlantax,
        ydata => \@atlantay,
        title => "ATLANTA",
        style => "linespoints",        
    );

	
my $atlantasoldataset = Chart::Gnuplot::DataSet->new(
        xdata => \@atlantax,
        ydata => \@atlantas,
        title => "ATLANTA",
        style => "linespoints",        
    );
    	
my @polskax = () ;
my @polskay = () ;
my @polskas = () ;

my $polskadataset = Chart::Gnuplot::DataSet->new(
        xdata => \@polskax,
        ydata => \@polskay,
        title => "POLSKA",
        style => "linespoints",        
    );

my $polskasoldataset = Chart::Gnuplot::DataSet->new(
        xdata => \@polskax,
        ydata => \@polskas,
        title => "POLSKA",
        style => "linespoints",        
    );
	
	
	
my @nobelusx = () ;
my @nobelusy = () ;
my @nobeluss = () ;
my $nobelusdataset = Chart::Gnuplot::DataSet->new(
        xdata => \@nobelusx,
        ydata => \@nobelusy,
        title => "NOBEL-US",
        style => "linespoints",        
    );
my $nobelussoldataset = Chart::Gnuplot::DataSet->new(
        xdata => \@nobelusx,
        ydata => \@nobeluss,
        title => "NOBEL-US",
        style => "linespoints",        
    );

	
	
my @usax = () ;
my @usay = () ;
my @usas = () ;
my $usadataset = Chart::Gnuplot::DataSet->new(
        xdata => \@usax,
        ydata => \@usay,
        title => "US14N21S",
        style => "linespoints",        
    );

my $usasoldataset = Chart::Gnuplot::DataSet->new(
        xdata => \@usax,
        ydata => \@usas,
        title => "US14N21S",
        style => "linespoints",        
    );

	
foreach my $file (@outfiles) {

   print "processing  $file\n" ;
   my $netname = uc basename( $file , ".out" );
   my @netname_split = split ( "-" , $netname );
   my $percent = $netname_split[ @netname_split - 1 ];
      
   my $crname = $netname ;   
   $crname =~ s/-$percent// ;
   
   
	open (TMPFILE, "<./OUT/$file" );

	my $relaxobj = "" ;
	my $intobj = "" ;
	my $gap = "" ;
	my $nconfig = 1 ;
	my $nsel = "" ;
	my $relaxtime = "" ;
	my $totaltime = "" ;
	my $rerun = 0 ;
	my $nkeep = 0 ;
	
   	while (my $record = <TMPFILE>) {

		my @fields = split($delimiter, $record);
    	
		if ( $record =~ m/^RELAX\ OBJ/ ) {		
			$relaxobj = sprintf("%.2f" , $fields[ 3 ] );	
		}

		if ( $record =~ m/^INT[\ ]+OBJ/ ) { 
			$intobj = sprintf("%d" , $fields[ 3 ] );	
		}

		if ( $record =~ m/^GAP/ ) { 		
			$gap = sprintf("%.2f" , $fields[ 2 ] );	
		}
		
		if ( $record =~ m/^PRICE[\ ]+ITERATION/ ) { 		

			$nconfig = sprintf("%d" , $fields[ 3 ] );	
		}

		if ( $record =~ m/^NUMBER[\ ]+OF[\ ]+CONFIGURATION/ ) { 		

			$nkeep = sprintf("%d" , $fields[ 4 ] );	
		}

		
		if ( $record =~ m/max-reduced/ ) { 		
			$rerun = 1 ;
				
		}

		if ( $record =~ m/^NUMBER\ OF\ SELECTED/ ) { 		
			$nsel = sprintf("%d" , $fields[ 5 ] );	
		}

		if ( $record =~ m/^RELAX\ RUNTIME/ ) { 		
			$relaxtime = sprintf("%d" , $fields[ 3 ] );	
		}

		if ( $record =~ m/^TOTAL\ RUNTIME/ ) { 		
			$totaltime = sprintf("%d" , $fields[ 3 ] );	
		}
		
		
	} # end while 
	
	if ( $rerun == 0 )	{
		printf("Need to rerun %s\n" , $netname );
		}
	
	if ( $totaltime =~ m/\d+/ ){
		$tabout->add( $mysep , $netname , $mysep, $percent , $mysep, $relaxobj , $mysep, $intobj , $mysep, $gap ,
				$mysep	, $nconfig , $mysep , $nsel , $mysep , $nkeep , $mysep, $relaxtime , $mysep, $totaltime ,$mysep);		
				
		push @latexdata , [ '\hline '.$netname , $percent , $gap , $nconfig , $nsel ];
	
		# quality data
		my $addp = 0;		
		
		foreach my $aline (@qualitydata){
		foreach my $name  (@{$aline}){
						
			if ( $name eq $crname  ) { $addp = 1;  }
		}
		}
				
		if ($addp == 0 ) {

			push @qualitydata , [ $crname , $gap , 100 * ( $nsel / $nconfig )  , 1 ] ;
		} else {
		
			foreach my $aline (@qualitydata){
			foreach my $name  (@{$aline}){						
				if ( $name eq $crname  ) { 
					@{$aline}[ 1 ] += $gap ;  
					@{$aline}[ 2 ] += 100 *( $nsel / $nconfig );
					@{$aline}[ 3 ] ++ ;  
					
					
					}
			}
			}
		}
	
		# atlanta
		if ( $netname =~ m/ATLANTA-/ ) {
			push @atlantax , $percent  ;
			push @atlantay , $intobj / 126158.0 ;
			push @atlantas , ( $nsel / $nconfig ) ;
		}
		
		#polska
		if ( $netname =~ m/POLSKA/ ) {
			push @polskax , $percent  ;
			push @polskay , $intobj / 21192.0 ;
			push @polskas , ( $nsel / $nconfig ) ;
		}
		

		#nobel-us
		if ( $netname =~ m/NOBEL-US/ ) {
			push @nobelusx , $percent  ;
			push @nobelusy , $intobj /  10492.0 ;
			push @nobeluss , ( $nsel / $nconfig ) ;
		}
		

		#US14N21S
		if ( $netname =~ m/US14N21S/ ) {
			push @usax , $percent  ;
			push @usay , $intobj /  5284.0 ;
			push @usas , ( $nsel / $nconfig ) ;
		}
		
		
	}
	
	close(TMPFILE);

} # end for file

# POLSKA CORRECTION
my $temp100x = $polskax[2] ;
my $temp100y = $polskay[2] ;
my $temp100s = $polskas[2] ;

my $i ;
for ( $i = 2 ; $i <= 10 ; $i ++ ) {

	$polskax[ $i ] = $polskax[ $i + 1 ] ;
	$polskay[ $i ] = $polskay[ $i + 1 ] ;
	$polskas[ $i ] = $polskas[ $i + 1 ] ;
}

	$polskax[ 10 ] = $temp100x ;
	$polskay[ 10 ] = $temp100y ;
	$polskas[ 10 ] = $temp100s ;

# US14N21S CORRECTION
$temp100x = $usax[2] ;
$temp100y = $usay[2] ;
$temp100s = $usas[2] ;


for ( $i = 2 ; $i <= 10 ; $i ++ ) {

	$usax[ $i ] = $usax[ $i + 1 ] ;
	$usay[ $i ] = $usay[ $i + 1 ] ;
	$usas[ $i ] = $usas[ $i + 1 ] ;
}

	$usax[ 10 ] = $temp100x ;
	$usay[ 10 ] = $temp100y ;
	$usas[ 10 ] = $temp100s ;

# ATLANTA CORRECTION
$temp100x = $atlantax[2] ;
$temp100y = $atlantay[2] ;
$temp100s = $atlantas[2] ;


for ( $i = 2 ; $i <= 10 ; $i ++ ) {

	$atlantax[ $i ] = $atlantax[ $i + 1 ] ;
	$atlantay[ $i ] = $atlantay[ $i + 1 ] ;
	$atlantas[ $i ] = $atlantas[ $i + 1 ] ;
}

	$atlantax[ 10 ] = $temp100x ;
	$atlantay[ 10 ] = $temp100y ;
	$atlantas[ 10 ] = $temp100s ;
	

print OUTTABLE $tabout->rule("-","+");
print OUTTABLE $tabout->title();
print OUTTABLE $tabout->rule("-","+");
print OUTTABLE $tabout->body();
print OUTTABLE $tabout->rule("-","+");

close( OUTTABLE );

# draw dual failure curve set
$dfcurve_chart->plot2d($atlantadataset,$polskadataset ,  $nobelusdataset , $usadataset );
$dfnsol_chart->plot2d( $atlantasoldataset , $polskasoldataset ,  $nobelussoldataset, $usasoldataset );

# draw quality solution table
my $latextable = LaTeX::Table->new(
        {   
        filename    => './REPORT/quality.tex',
        caption     => 'Quality of Solutions',
        label       => 'tab:quality',
        position    => 'h',
        header      => \@latexheader,
        data        => \@latexdata,
        }
 );
 
 $latextable->set_coldef( '|l|r|r|r|r|' );
 $latextable->generate();

 
 # draw average table 

print "----------------------------------\n" ;
print "AVERAGE QUALITY SOLUTION\n" ;
print "----------------------------------\n" ;

 
 foreach my $line (@qualitydata){
	
	@{	$line }[ 1 ] = @{	$line }[ 1 ] / @{	$line }[ 3 ];
	@{	$line }[ 2 ] = @{	$line }[ 2 ] / @{	$line }[ 3 ];
	print "@{$line}"."\n" ;
	
	}