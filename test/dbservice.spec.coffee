db = require './../dbservice'
assert = require 'assert'
pool = require('./../dbpool').pool
xdate = require 'xdate'
mysql = require 'mysql'

describe 'DBService', ()=>
	beforeEach (done)=>
		db.deleteEverything done

	describe 'getLastMessage()', ()=>
		it 'should get the last inserted message', (done)=>
			date1 = new xdate().toDate()
			date2 = new xdate().addMinutes(1).toDate()
			pool.query mysql.format("INSERT INTO message (dateCreated,url) VALUES (?,?)", [date1, 'testing1']), (err)->
				console.log err if err
				pool.query mysql.format("INSERT INTO message (dateCreated,url) VALUES (?,?)", [date2, 'testing2']), (err)->
					console.log err if err
					db.getLastMessage (err,msg)->
						assert msg.url is 'testing2'
						done()


	describe 'newFanout()', ()=>
		it 'should add fanout record', (done)=>
			db.newMessage 'testURL', (err, msg)->
				db.newFanout (err,fanout)->
					console.log err if err
					assert fanout isnt undefined
					assert fanout.message_id is msg.id
					done()

	describe 'getLastFanout()', ()=>
		it 'should return last fanout', (done)=>
			date1 = new xdate().toDate()
			date2 = new xdate().addMinutes(1).toDate()
			pool.query mysql.format("INSERT INTO message (dateCreated,url) VALUES (?,?)", [date1, 'testing1']), (err, result)->
				pool.query mysql.format("INSERT INTO fanout (dateStarted,message_id) VALUES (?,?)", [date1, 0]), (err)->
					console.log err if err
					pool.query mysql.format("INSERT INTO fanout (dateStarted,message_id) VALUES (?,?)", [date2, result.insertId]), (err)->
						console.log err if err
						db.getLastFanout (err,f)->
							assert f.message_id is result.insertId
							done()

	describe 'registerCall', ()=>
		it 'should create a call record', (done)=>
			pool.query mysql.format("INSERT INTO message (dateCreated,url) VALUES (?,?)", [new Date(), 'testing1']), (err, msgRes)->
				pool.query mysql.format("INSERT INTO fanout (dateStarted,message_id) VALUES (?,?)", [new Date(), msgRes.insertId]), (err,fanRes)->
					db.registerCall '905123123', 'outgoing', 'true', (err, call)->
						assert call.fanout_id is fanRes.insertId
						assert call.number is '905123123'
						assert call.direction is 'outgoing'
						assert call.confirmed is 'true'
						done()

	describe 'getFanoutSummary', ()=>

		it 'should return all calls for given fanout with status and person info', (done)=>
			addCall = (fanoutId, personId, callback)->
				sql = "INSERT INTO phonecall (dateConnected,fanout_id, person_id, direction, confirmed) VALUES (?,?,?,?,?)"
				inserts = [new Date(), fanoutId, personId, 'outgoing', 'true']
				sql = mysql.format(sql, inserts)
				pool.query sql, callback

			pool.query mysql.format("INSERT INTO fanout (dateStarted,message_id) VALUES (?,?)", [new Date(), 123]), (err,fanRes)->
				pool.query mysql.format("INSERT INTO fanout (dateStarted,message_id) VALUES (?,?)", [new Date(), 324]), (err,fanRes2)->
					pool.query mysql.format("INSERT INTO person (name,number) VALUES (?,?)", ['person1', 'number1']), (err, perRes)->
						pool.query mysql.format("INSERT INTO person (name,number) VALUES (?,?)", ['person2', 'number2']), (err, perRes2)->
							addCall fanRes2.insertId, perRes.insertId, ()->
								addCall fanRes2.insertId, perRes2.insertId, ()->
									addCall fanRes.insertId, perRes.insertId, ()->
										addCall fanRes.insertId, perRes2.insertId, ()->
											db.getFanoutSummary fanRes2.insertId, (err, summary)->
												assert summary.fanout.id = fanRes2.insertId
												assert summary.calls instanceof Array
												assert summary.calls.length is 2, "Number of calls should be 2, but was #{summary.calls.length}"
												assert summary.calls[0].name is 'person1'
												done()
