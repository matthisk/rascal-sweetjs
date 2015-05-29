@cachedParser{desugar.cached.Parser}
module desugar::Desugar
extend desugar::Visitor;
extend runtime::Visitor;

extend extensions::arrow::Desugar;
extend extensions::classes::Desugar;
extend extensions::object::Desugar;
extend extensions::parameters::Desugar;
extend extensions::spread::Desugar;
//extend extensions::forof::Desugar;
extend extensions::destructuring::Desugar;
extend extensions::template::Desugar;
extend extensions::letconst::Desugar;

import ParseTree;
import extensions::letconst::Resolve;

start[Source] desugarAll(start[Source] src) {
	pt = desugarVisitor( src );
	pt = resolve( pt );
	return runtimeVisitor( pt );
}

void compile(str input) {
	pt = parse(#start[Source], input);
	dpt = resolve( desugarVisitor( pt ) );
	print(dpt);
}