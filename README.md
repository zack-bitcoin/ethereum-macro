Macro
=====

This is a language that compiles to EVM code. It uses this assembly language as an intermediate representation: https://github.com/zack-bitcoin/ethereum-assembly

This language takes code like:

   	# square dup mul ;
	# sumsquare &1 square &2 square add ;

	sumsquare 3 4 

and it returns compiled hex like:

     600380026004800201