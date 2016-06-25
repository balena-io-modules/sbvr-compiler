program = require 'commander'

runCompile = (inputFile, outputFile) ->
	sbvrCompiler = require './sbvr-compiler'
	fs = require 'fs'

	seModel = fs.readFileSync(inputFile, 'utf8')
	sqlModel = sbvrCompiler(seModel, program.engine)

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

program.command('compile <input-file> [output-file]')
	.description('compile the input SBVR file into SQL')
	.action(runCompile)

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
