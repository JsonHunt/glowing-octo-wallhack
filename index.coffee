express = require('express')
router = express.Router()
xml = require 'xml'
request = require 'request'
dbservice = require './dbservice'
_ = require 'underscore'
async = require 'async'
xdate = require 'xdate'

output = (res, x)->
	xres = xml x,
		declaration:
			encoding: 'UTF-8'
	res.set('Content-Type', 'text/xml')
	# console.log xres
	res.send xres

router.use '/callfanout-inbound', (req, res, next) ->
	output res,
		Response: [
			{Say: "You have reached P H R I emergency notification system"}
			{Redirect: 'message'}
		]

router.use '/message', (req,res,next)->
	menu = []
	menu._attr =
		action: 'message-answer'
		numDigits: 1
		timeout: 5

	if req.app.locals.fanoutInProgress is undefined
		menu.push {Say: "There are no active emergency notifications at this time. Goodbye."}
		output res,
			Response: [
				{Gather: menu}
				{Hangup:''}
			]
	else
		menu.push {Say: 'To hear the message again, press 1'}
		menu.push {Say: 'To confirm you received and understood the message, press 0'}
		output res,
			Response: [
				{Say: 'Listen carefully to the following message'}
				{Play: req.app.locals.message}
				{Gather: menu}
				{Say: 'No response detected. Goodbye!'}
				{Hangup:''}
			]

router.use '/message-answer', (req,res,next)->
	ans = req.body.Digits
	recipientNumber = if req.body.Direction is 'inbound' then req.body.From else req.body.To

	if ans is '*'
		output res,
			Response: [
				{Redirect: 'admin-password'}
			]
	else if ans is '1'
		output res,
			Response: [
				{Redirect: 'message'}
			]
	else if ans is '0'
		if req.app.locals.fanoutInProgress
			#dbservice.registerCall req.app.locals.fanoutID, recipientNumber, req.body.Direction, 'true', ()->
			req.app.locals.calls[recipientNumber].confirmed = true
		output res,
			Response: [
				{Say: 'Thank you. Goodbye!'}
				{Hangup:''}
			]
	else
		# if req.app.locals.fanoutInProgress
		# 	dbservice.registerCall req.app.locals.fanoutID, recipientNumber, req.body.Direction, 'false', ()->
		output res,
			Response: [
				{Say: 'Goodbye!'}
				{Hangup: ''}
			]

router.use '/fanout', (req,res,next)->
	output res,
		Response: [
			{Say: 'This is P H R I emergency broadcast.'}
			{Redirect: 'message'}
		]

router.use '/admin-password', (req,res,next)->
	password = []
	password._attr =
		action: "admin-password-answer"
		numDigits: 5

	output res,
		Response: [
			{Say: "Please enter the administrator password"}
			{Gather: password}
			{Say: "Sorry, I didn't get that"}
			{Redirect: "admin-password"}
		]

router.use '/admin-password-answer', (req,res,next)->
	ans = req.body.Digits
	dbservice.verifyAdminPassword ans, (err)->
		if err
			output res,
				Response: [
					{Say: "That was not a valid password"}
					{Redirect: "admin-password"}
				]
		else
			output res,
				Response: [
					{Redirect: "admin-menu"}
				]

myobject =
	firstAttre: "sdfsdf"
	slkdfjsldkf: "sfdsdsdf"




router.use '/admin-menu', (req,res,next)->
	try
		menu = []
		if req.app.locals.fanoutInProgress isnt undefined
			 menu.push {Say: "Call fanout is in progress. To abort now, press 0"}
		menu.push {Say: "To record a new broadcast message, press 1"}
		dbservice.getLastMessage (err,msg)->
			if msg
				menu.push {Say: "To listen to recorded broadcast message, press 2"}

			if req.app.locals.fanoutInProgress is undefined and msg
				menu.push {Say: "To trigger a call fanout, press 3"}

			menu._attr =
				action: 'admin-menu-answer'
				numDigits: 1

			output res,
				Response: [
					{Gather: menu}
					{Say: "Sorry, I didn't get that"}
					{Redirect: "admin-menu"}
				]
	catch e
		console.log e

router.use '/admin-menu-answer', (req,res,next)->
	try
		ans = req.body.Digits
		console.log "Answer: #{ans}"

		if ans is '0'
			console.log "Aborting fanout"
			delete req.app.locals.fanoutInProgress
			delete req.app.locals.fanoutID
			output res,
				Response: [
					{Say: 'The call fanout was aborted.'}
					{Redirect: 'admin-menu'}
				]

		else if ans is '2'
			console.log "Playing back the message"
			dbservice.getLastMessage (err,msg)->
				if err
					console.log err
				output res,
					Response: [
						{Play: msg.url}
						{Redirect: "admin-menu"}
					]

		else if ans is '1'
			console.log "Recording new message"
			message = []
			message._attr =
					action: 'admin-recorded'
					maxLength: 60*5

			output res,
				Response: [
					{Say: 'Record your message now, then press any key when finished'}
					{Record: message}
					{Say: "Sorry, I didn't get that"}
					{Redirect: 'admin-menu'}
				]

		else if ans is '3'
			console.log "Initiating call fanout"
			confirmation = [
				{Say: 'Press 0 to proceed'}
				{Say: 'Press 1 to abort'}
			]
			confirmation._attr =
				action: 'admin-start-fanout-confirm'
				numDigits: 1

			output res,
				Response: [
					{Say: 'Call fanout is about to begin.'}
					{Gather: confirmation}
					{Say: "Sorry, I didn't get that. Call fanout was not initiated"}
					{Redirect: 'admin-menu'}
				]
		else
			output res,
				Response: [
					{Say: 'An error has occurred'}
					{Redirect: 'admin-menu'}
				]
	catch e
		console.log e
		output res,
			Response: [
				{Say: 'An error has occurred'}
				{Redirect: 'admin-menu'}
			]

router.use '/admin-start-fanout-confirm', (req,res,next)->
	ans = req.body.Digits
	if ans is '0'
		req.app.locals.calls = {}
		req.app.locals.fanoutInProgress = true
		req.app.locals.fanoutSummaryNumber = req.body.From
		req.app.locals.fanoutStartTime = new Date()
		dbservice.newFanout (err,result)->
			req.app.locals.fanoutID = result.insertId

		dbservice.getLastMessage (err,message)->
			req.app.locals.message = message.url

		if req.body.AccountSid is undefined
			req.body.AccountSid = 'AC8b3510dfe729785e2fa921c066ae4586'
		if req.body.to is undefined
			req.body.to = '2897685694'

		apiURL = "https://api.twilio.com/2010-04-01/Accounts/#{req.body.AccountSid}/Calls"
		req.app.locals.callsInProgress = 0
		dbservice.getAllPeople (err, recipients, fields)->
			setTimeout ()->
				async.each recipients, (rec, cb)->
					number = rec.number
					makeCall apiURL, req.body.to, number, 'fanout', 'call-status', (error, response, body)->
						if error
							console.log "Call to #{rec.name} at #{rec.number} failed: #{error}"
						else
							console.log "Calling #{rec.name} at #{rec.number}"
							req.app.locals.calls[number] =
								confirmed: false
								completed: false
						cb()
				, (err)->
			, 5000

			if recipients.length > 0
					message = 'Call fanout was started. You will recieve a text message with results when it completes. Goodbye'
			else
					message = 'No destination numbers were configured for fanout. Aborting. Goodbye'

			output res,
					Response: [
						{Say: message}
						{Hangup: ''}
					]
	else if ans is '1'
		output res,
			Response: [
				{Say: 'Call fanout was NOT started.'}
				{Redirect: 'admin-menu'}
			]
	else
		output res,
				Response: [
					{Say: 'There was an error'}
					{Redirect: 'admin-menu'}
				]

router.use '/admin-recorded', (req,res,next)->
		rec = req.body.RecordingUrl
		console.log "Recording URL: #{rec}"
		#req.app.locals.message = rec
		dbservice.newMessage rec, (err)->
			if err
				console.log err
				output res,
					Response: [
						{Say: 'There was an error'}
						{Redirect: 'admin-menu'}
					]
			else
				output res,
					Response: [
						{Say: "Your message was recorded."}
						{Redirect: 'admin-menu'}
					]

makeCallX = (apiURL, from, to, url, callback)->
	console.log "Making a call via #{apiURL} from #{from} to #{to}, redirecting to '#{url}'"
	callback()

makeCall = (apiURL, from, to, url, statusUrl, callback)->
	# console.log "Making a call via #{apiURL} from #{from} to #{to}, redirecting to '#{url}'"
	accountSID = 'AC8b3510dfe729785e2fa921c066ae4586'
	authToken = 'bdc7f50dbc9ce7997d032a0e6c16c9b0'
	twilio = require('twilio')(accountSID, authToken)
	twilio.calls.create
		to: to
		from: from
		url: 'http://www.gamedealalerts.com:3000/fanout'
		statusCallback: 'http://www.gamedealalerts.com:3000/call-status'
	,(err, call) ->
		if err
			console.log err
		else
			# console.log call
		callback()

	# request.post
	# 	url: apiURL
	# 	qs:
	# 		From: from
	# 		To: to
	# 		Url: url
	# 		StatusCallback: statusUrl
	# , callback

router.use '/call-status', (req,res,next)->
	number = req.body.To
	duration = req.body.CallDuration
	status = req.body.CallStatus
	console.log "Call to #{number}: duration: #{duration}; status: #{status}"
	if req.app.locals.fanoutInProgress
		calls = req.app.locals.calls
		calls[number].completed = true
		confirmed = calls[number].confirmed
		dbservice.registerCall req.app.locals.fanoutID, number, status, confirmed, (err)->
			if err
				console.log err
			else if fanoutFinished(calls)
				sendStatusMessage(req.app.locals.fanoutSummaryNumber, req.app.locals.fanoutID)
				req.app.locals.fanoutInProgress = false
	res.send 'ok'

router.use '/incoming-call-status', (req,res,next)->
	# number = req.body.From
	# duration = req.body.CallDuration
	# status = req.body.CallStatus
	# console.log "Call from #{number}: duration: #{duration}; status: #{status}"
	# if req.app.locals.fanoutInProgress
	# 	calls = req.app.locals.calls
	# 	calls[number].completed = true
	# 	confirmed = calls[number].confirmed
	# 	dbservice.registerCall req.app.locals.fanoutID, number, status, confirmed, (err)->
	# 		if err
	# 			console.log err
	# 		else if fanoutFinished(calls)
	# 			sendStatusMessage(req.app.locals.fanoutSummaryNumber, req.app.locals.fanoutID)
	# 			req.app.locals.fanoutInProgress = false
	res.send 'ok'

router.use '/fanout-summary', (req,res,next)->
	fanoutID = req.body.FanoutID
	number = req.body.number
	if fanoutID
		sendStatusMessage(number, fanoutID)
	res.send 'ok'

fanoutFinished = (calls)->
	for key,value of calls
		if value.completed is false
			return false
	return true

sendStatusMessage = (number, fanoutID)->
	dbservice.getFanoutSummary fanoutID, (err,summary)->
		if err
			console.log err
		else
			fanoutTime = new xdate(summary.fanout.dateStarted).toString('yyyy MMM dd, HH:mm')
			body = """
				Call Fanout Summary
				Initiated: #{fanoutTime}

			"""
			for call in summary.calls
				body += """
					#{call.name}: #{call.status}, #{if (call.confirmed is '1') then 'confirmed' else 'not confirmed'}\n
				"""

			console.log body
			accountSID = 'AC8b3510dfe729785e2fa921c066ae4586'
			authToken = 'bdc7f50dbc9ce7997d032a0e6c16c9b0'
			twilio = require('twilio')(accountSID, authToken)
			twilio.messages.create
				to: number
				from: '+12897685694'
				body: body
			,(err, call) ->
				if err
					console.log err
				# else
					# console.log call


module.exports = router
