mysql = require 'mysql'
pool = require('./dbpool').pool
bunyan = require 'bunyan'

# dbservice =
# 	recipients: [
# 		name: 'Lukasz'
# 		number: '9059215199'
# 	,
# 		name: 'Dave'
# 		number: '9058656248'
# 	]

module.exports.deleteEverything = (callback)->
	pool.query "TRUNCATE TABLE message", ()->
		pool.query "TRUNCATE TABLE fanout", ()->
			pool.query "TRUNCATE TABLE phonecall", ()->
				pool.query "TRUNCATE TABLE person", callback

module.exports.newFanout = (callback)->
	getLastMessage (err,msg)->
		sql = mysql.format "INSERT INTO fanout (dateStarted,message_id) VALUES (?,?)", [new Date(), msg.id]
		pool.query sql, callback

module.exports.getAllFanouts = (callback)-> pool.query "SELECT * FROM fanout", (err,rows,fields)-> callback(undefined,rows)
module.exports.getLastFanout = getLastFanout = (callback)-> pool.query "SELECT * FROM fanout ORDER BY dateStarted DESC LIMIT 1", (err,rows,fields)->
	row = if rows.length > 0 then rows[0] else undefined
	callback(undefined,row)

module.exports.savePerson = (person, callback)-> callback()
module.exports.getAllPeople = (callback)->
	pool.query "SELECT * FROM person", callback

module.exports.getPerson = (id, callback)-> callback()

module.exports.findPersonByNumber = (number, callback)->
	sql = mysql.format "SELECT * FROM person WHERE number = ?", [number], (err,rows,fields)->
		if rows.length > 0
			callback err, people[0]
		else
			callback err, undefined

module.exports.newMessage = (url, callback)->
	sql = mysql.format "INSERT INTO message (dateCreated,url) VALUES (?,?)", [new Date(), url]
	pool.query sql, callback

module.exports.registerCall = (fanoutID, number, status, confirmed, callback)->
	sql = mysql.format "INSERT INTO phonecall (dateConnected, fanout_id, number, status, confirmed) VALUES (?,?,?,?,?)",[
		new Date()
		fanoutID
		number
		status
		confirmed
	]
	pool.query sql, callback

module.exports.getLastMessage = getLastMessage = (callback)-> pool.query "SELECT * FROM message ORDER BY `dateCreated` DESC LIMIT 1", (err,rows,fields)->
	msg = if rows.length > 0 then rows[0] else undefined
	callback(undefined,msg)

module.exports.getFanoutSummary = (fanoutID, callback) ->
	summary = {}
	pool.query mysql.format("SELECT * FROM fanout WHERE id = ?", [fanoutID]), (err, results)->
		summary.fanout = results[0]
		sql = "SELECT * FROM phonecall c JOIN fanout f ON c.fanout_id = f.id JOIN person p ON p.number = c.number WHERE f.id = ?"
		inserts = [fanoutID]
		sql = mysql.format sql, inserts
		pool.query sql, (err,results)->
			console.log(err) if err
			summary.calls = results
			callback undefined, summary

module.exports.verifyAdminPassword = (pass, callback)-> callback(undefined,true)
