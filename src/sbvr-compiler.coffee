{ SBVRParser } = require '@resin/sbvr-parser'
LF2AbstractSQL = require '@resin/lf-to-abstract-sql'
AbstractSQLCompiler = require '@resin/abstract-sql-compiler'
sbvrTypes = require '@resin/sbvr-types'

fs = require 'fs'
TypesModel = fs.readFileSync(require.resolve('@resin/sbvr-types/Type.sbvr'), 'utf8')

ExtendedSBVRParser = SBVRParser._extend
	initialize: ->
		SBVRParser.initialize.call(this)
		@AddCustomAttribute('Database ID Field:')
		@AddCustomAttribute('Database Table Name:')
		@AddBuiltInVocab(TypesModel)
		return this
LF2AbstractSQLTranslator = LF2AbstractSQL.createTranslator(sbvrTypes)

compile = (seModel, engine) ->
	abstractSqlModel = exports.transform(seModel)
	try
		return AbstractSQLCompiler[engine].compileSchema(abstractSqlModel)
	catch e
		e.message = "Error compiling AbstractSQL into SQL: #{e.message}"
		throw e

# Export compile both as `.compile` and directly for backwards compatibility
module.exports = exports = compile
exports.compile = compile

exports.parse = (seModel) ->
	try
		return ExtendedSBVRParser.matchAll(seModel, 'Process')
	catch e
		e.message = "Error parsing SBVR into LF: #{e.message}"
		throw e

exports.transform = (seModel) ->
	lfModel = exports.parse(seModel)
	try
		return LF2AbstractSQLTranslator(lfModel, 'Process')
	catch e
		e.message = "Error transforming LF into AbstractSQL: #{e.message}"
		throw e

exports.compile = (seModel, engine) ->
	abstractSqlModel = exports.transform(seModel)
	try
		return AbstractSQLCompiler[engine].compileSchema(abstractSqlModel)
	catch e
		e.message = "Error compiling AbstractSQL into SQL: #{e.message}"
		throw e

exports.migrate = (seSrc, seDst, engine) ->
	abstractSqlSrc = exports.transform(seSrc)
	abstractSqlDst = exports.transform(seDst)
	try
		return AbstractSQLCompiler[engine].diffSchemas(abstractSqlSrc, abstractSqlDst)
	catch e
		e.message = "Error diffing AbstractSQL schemas: #{e.message}"
