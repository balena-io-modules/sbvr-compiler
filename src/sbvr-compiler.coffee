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

module.exports = (seModel, engine) ->
	try
		lfModel = ExtendedSBVRParser.matchAll(seModel, 'Process')
	catch e
		e.message = "Error parsing SBVR into LF: #{e.message}"
		throw e

	try
		abstractSqlModel = LF2AbstractSQLTranslator(lfModel, 'Process')
	catch e
		e.message = "Error transforming LF into AbstractSQL: #{e.message}"
		throw e

	try
		sqlModel = AbstractSQLCompiler[engine].compileSchema(abstractSqlModel)
	catch e
		e.message = "Error compiling AbstractSQL into SQL: #{e.message}"
		throw e

	return sqlModel

