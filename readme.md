Column Generation Framework
===========================

Column Generation is a very useful approach to solve large-scale linear programming problems. 
This is the column generation framework that I developed during my Ph.D study, written in [OPL][opl]. 
Interested readers are encouraged to see [Column Generation][cgbook].

This source is published under MIT licence. If you use it, it is very appreciate to drop me a few lines.


[opl]: http://www-01.ibm.com/software/integration/optimization/cplex-optimization-studio/
[cgbook]: http://www.amazon.com/Column-Generation-Gerad-25th-Anniversary/dp/0387254854



Usage
=====

### Configuration Files:

+ params.mod : contain definition of your data. _sysmsg.mod_ need to be included in this file
+ model.ini  : define loading models


### Special Nodes:

+ START : will be called first
+ RELAX : relax version of Restricted Master Problem (RMP)
+ FINAL : the RMP problem that contains the solution


### Running

_oplrun -D input="datafile" [path-to]/solver.mod_  in your directory.
