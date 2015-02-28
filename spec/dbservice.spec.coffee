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
				pool.query mysql.format("INSERT INTO fanout (dateStarted,message_id) VALUES (?,?)", [new Date(), msgRes.insertId]), (fanRes)->
					pool.query mysql.format("INSERT INTO person (name,number) VALUES (?,?)", ['person1', 'number1']), (err, perRes)->
						db.registerCall perRes.insertId, 'outgoing', 'true', (err, call)->
							assert call.fanout_id is fanRes.insertId
							assert call.person_id is perRes.insertId
							assert call.direction is 'outgoing'
							assert call.confirmed is 'true'
							done()
