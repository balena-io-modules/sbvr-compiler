program = require 'commander'
fs = require('fs')

getSE = (inputFile) ->
	return fs.readFileSync(inputFile, 'utf8')

run = (method) ->
	return (inputFile, outputFile) ->
		seModel = getSE(inputFile)
		result = require('./sbvr-compiler')[method](seModel, program.engine)
		json = JSON.stringify(result, null, 2)
		if outputFile
			fs.writeFileSync(outputFile, json)
		else
			console.log(json)

runMigrate = (srcFile, dstFile, outputFile) ->
	sbvrCompiler = require './sbvr-compiler'
	seSrc = getSE(srcFile)
	seDst = getSE(dstFile)
	migration = sbvrCompiler.migrate(seSrc, seDst, program.engine).join('\n')
	if outputFile
		fs.writeFileSync(outputFile, migration)
	else
		console.log(migration)

runCompile = (inputFile, outputFile) ->
	sbvrCompiler = require './sbvr-compiler'
	seModel = getSE(inputFile)
	sqlModel = sbvrCompiler.compile(seModel, program.engine)

	writeLn =
		if outputFile
			fs.writeFileSync(outputFile, '')
			->
				fs.writeFileSync(outputFile, Array::join.call(arguments, ' ') + '\n', flag: 'a')
		else
			console.log

	writeLn('''
		--
		-- Create table statements
		--

	''')
	for createSql in sqlModel.createSchema
		writeLn(createSql)
		writeLn()
	writeLn('''

		--
		-- Rule validation queries
		--

	''')
	for rule in sqlModel.rules
		writeLn("-- #{rule.structuredEnglish}")
		writeLn(rule.sql)
		writeLn()

program
	.version(require('../package.json').version)
	.option('-e, --engine <engine>', 'The target database engine (postgres|websql|mysql), default: postgres', /postgres|websql|mysql/, 'postgres')

program.command('parse <input-file> [output-file]')
	.description('parse the input SBVR file into LF')
	.action(run('parse'))

program.command('transform <input-file> [output-file]')
	.description('transform the input SBVR file into abstract SQL')
	.action(run('transform'))

program.command('compile <input-file> [output-file]')
	.description('compile the input SBVR file into SQL')
	.action(runCompile)

program.command('migrate <previous-model> <current-model> [output-file]')
	.description('attempts to generate a migration between two SBVR models
	')
	.action(runMigrate)

program.command('help')
	.description('print the help')
	.action ->
		program.help()

program
	.arguments('<input-file> [output-file]')
	.action(runCompile)

if process.argv.length is 2
	program.help()

program.parse(process.argv)
