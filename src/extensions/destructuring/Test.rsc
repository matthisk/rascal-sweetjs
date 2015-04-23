module extensions::destructuring::Test
extend desugar::Visitor;
extend \test::Base;

import extensions::destructuring::Syntax;
import extensions::destructuring::Desugar;

test bool parsingObjectDestructure() {
	return
	describe( "Parsing object destructurings", [
		\it( "as a left hand side expression", tryParsing(
			"({ a, b } = { a : 0, b : 1 });"
		)),
		
		\it( "as a variable declaration", tryParsing(
			"var {a,b} = {a:0,b:1};"
		)),
		
		\it( "as a function parameter", tryParsing(
			"function( {a,b} ) { return a + b; }"
		)),
		
		\it( "with nested objects", tryParsing(
			"var {a,b:{c,d}} = obj;"
		)),
		
		\it( "with named values", tryParsing(
			"var { a : foo, b : bar } = obj;"
		)),
		
		\it( "mixed with array destructurings", tryParsing(
			"var { a : [ b,c ] } = obj;"
		))
	]);
}

test bool parsingArrayDestructure() {
	return
	describe( "Parsing array destructurings", [
		\it( "as a left hand side expression", tryParsing( 
			"[x,y] = [y,x];"
		)),
		
		\it( "as chained expression assignment", tryParsing(
			"[a,b] = [c,d] = [1,2];"
		)),
		
		\it( "as a variable declaration", tryParsing(
			"var [x,y] = [y,x];"
		)),
		
		\it( "as a function parameter", tryParsing(
			"function( [x,y] ) { return x + y; }"
		)),
		
		\it( "with nested arrays", tryParsing(
			"var [ x, [y,z] ] = xs;"
		)),
		
		\it( "with empty slots", tryParsing(
			"var [ , y, z ] = xs;"
		)),
		
		\it( "with trailing comma", tryParsing(
			"var [x,y,] = xs;"
		)),
		
		\it( "with default value", tryParsing(
			"var [x=10,y] = xs;"
		)),
		
		\it( "with rest value", tryParsing(
			"var [x,y,...rest] = xs;"
		)),
		
		\it( "as a left hand side expression, with rest value", tryParsing(
			"[x,y,...rest] = xs;"
		)),
		
		\it( "mixed with object destructuring", tryParsing(
			"var [x,{y,z}] = lst;"
		))
	]);
}

test bool desugarObjectDestructure() {
	return
	describe( "Desugaring object destructurings", [
		\it( "as var declaration", tryDesugar( 
			"var {a,b} = {a:1,b:2};",
			[<"{ var _ref = {a:1,b:2}; var a = _ref.a; var b = _ref.b; }",
			 bool(pt) { return /(Statement)`{ var _ref = {a:1,b:2}; var a = _ref.a; var b = _ref.b; }` := pt; }>]
		)),
		
		\it( "as var declaration with default value", tryDesugar(
			"var {a=10,b} = {b:0};",
			[<"{ var _ref = {b:0}; var a = _ref.a === undefined ? 10 : _ref.a; var b = _ref.b; }",
			  bool(pt) { return /(Statement)`{ var _ref = {b:0}; var a = _ref.a === undefined ? 10 : _ref.a; var b = _ref.b; }` := pt; }>]
		)),
		
		\it( "as a var declaration with key value", tryDesugar(
			"var {a:b} = {a:10};",
			[<"{ var _ref = {a:10}; var b = _ref.a; }",
			  bool(pt) { return /(Statement)`{ var _ref = {a:10}; var b = _ref.a; }` := pt; }>]
		)),
		
		\it( "as a var declaration with nested destructurings", tryDesugar(
			"var {a:{b}} = {a:{b:10}};",
			[<"{ var _ref = {a:{b:10}}; var a = _ref.a; var b = a.b; }",
			  bool(pt) { return /(Statement)`{ var _ref = {a:{b:10}}; var a = _ref.a; var b = a.b; }` := pt; }>]
		))
	]);
}

test bool desugarArrayDestructure() {
	return
	describe( "Desugaring array destructurings", [
	
		\it( "as chained assignment", tryDesugar(
			"var a,b,c,d;
			'var arr = [a,b] = [c,d] = [1,2];",
			[<"var arr = [ref = [ ref2 = [1,2], c = ref2[0], d = ref2[1] ].shift(), a = ref[0], b = ref[1] ].shift();",
			  bool(pt) { return /(Statement)`var arr = [ref = [ ref$1 = [1,2], c = ref$1[0], d = ref$1[1] ].shift(), a = ref[0], b = ref[1] ].shift();` := pt; }>]
		) ),
		
		\it( "as nested pattern expression assignment", tryDesugar(
			"var a,b,c,d;
			'[a,[c,d]] = [1,[2,3]];",
			[<"[_ref = [1,[2,3]], a = _ref[0], _ref$1 = _slicedToArray( _ref[1], 2 ), c = _ref$1[0], d = _ref$1[1] ].shift();",
			  bool(pt) { return /(Statement)`[_ref = [1,[2,3]], a = _ref[0], _ref$1 = _slicedToArray( _ref[1], 2 ), c = _ref$1[0], d = _ref$1[1] ].shift();` := pt; }>]
		) ),
		
		\it( "as expression assignment, with rest value", tryDesugar(
			"[a, ...rest] = [1,2,3,4,5];",
			[<"[_ref=[1,2,3,4,5],a=_ref[0],rest=_ref.slice(1)]",
			  bool(pt) { return /(Expression)`[_ref=[1,2,3,4,5],a=_ref[0],rest=_ref.slice(1)]` := pt; }>]
		)),
	
		\it( "as a left hand side expression", tryDesugar(
			"var x = 10, y = 12;
			'[x,y] = [y,x];",
			[<"[_ref=[y,x], x = _ref[0], y = _ref[1]].shift();",
			  bool(pt) { return /(Statement)`[_ref=[y,x], x = _ref[0], y = _ref[1]].shift();` := pt; }>]
		) ),
		
		\it( "as a variable declaration", tryDesugar(
			"var [x,y] = [10,12];",
			[<"{ var _ref = [10,12]; var x = _ref[0]; var y = _ref[1]; }",
			  bool(pt) { return /(Statement)`{ var _ref = [10,12]; var x = _ref[0]; var y = _ref[1]; }` := pt; }>]
		) ),
		
		\it( "as a function parameter", tryDesugar(
			"function( [ a, b, c ] ) {
			'  return a + b + c;
			'}",
			[<"function( _arg0 ) { var _arg02 = _slicedToArray( _arg0, 3 ); var a = _arg02[0]; var b = _arg02[1]; var c = _arg02[2]; return a + b + c; }",
			  bool(pt) { return /(Function)`function( _arg0 ) { var _arg02 = _slicedToArray( _arg0, 3 ); var a = _arg02[0]; var b = _arg02[1]; var c = _arg02[2]; return a + b + c; }` := pt; }>]
		)),
		
		\it( "as a function parameter, multiple times", tryDesugar(
			"function( [ a, b, c ], [ d, e ] ) {
			'  return a + b + c + d + e;
			'}",
			[<"function( _arg1, _arg0 ) { var _arg02 = _slicedToArray( _arg0, 2 ); var d = _arg02[0]; var e = _arg02[1]; var _arg12 = _slicedToArray( _arg1, 3 ); var a = _arg12[0]; var b = _arg12[1]; var c = _arg12[2]; return a + b + c + d + e; }",
			  bool(pt) { return /(Statement)`function( _arg1, _arg0 ) { var _arg02 = _slicedToArray( _arg0, 2 ); var d = _arg02[0]; var e = _arg02[1]; var _arg12 = _slicedToArray( _arg1, 3 ); var a = _arg12[0]; var b = _arg12[1]; var c = _arg12[2]; return a + b + c + d + e; }` := pt; }>]
		)),
		
		\it( "as a function parameter, with nested destructurings", tryDesugar(
			"function( [ a, [ d, e ] ] ) {
			'  return a + d + e;
			'}",
			[<"function( _arg0 ) { var _arg02 = _slicedToArray( _arg0, 2 ); var a = _arg02[0]; var _arg02$1 = _slicedToArray( _arg02[1], 2 ); var d = _arg02$1[0]; var e = _arg02$1[1]; return a + d + e; }",
			  bool(pt) { return /(Statement)`function( _arg0 ) { var _arg02 = _slicedToArray( _arg0, 2 ); var a = _arg02[0]; var _arg02$1 = _slicedToArray( _arg02[1], 2 ); var d = _arg02$1[0]; var e = _arg02$1[1]; return a + d + e; }` := pt; }>]
		)),
		
		\it( "as a function parameter, with rest value", tryDesugar(
			"function( [a, ...rest] ) {
			'
			'}",
			[<"function( _arg0 ) { var _arg02 = _toArray( _arg0 ); var a = _arg02[0]; var rest = _arg02.slice(1); }",bool(pt) {
				return /(Statement)`function( _arg0 ) { var _arg02 = _toArray( _arg0 ); var a = _arg02[0]; var rest = _arg02.slice(1); }` := pt;
			}>]
		))
		
	]);
}

