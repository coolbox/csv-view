express = require('express')
redis   = require('redis')
fs      = require('fs')
csv     = require('csv')

db = redis.createClient()
app = express()

app.use express.favicon()
app.use express.logger()
app.use express.static(__dirname + '/public')
app.use express.directory("public")
app.use express.bodyParser()

app.use (req, res, next) ->
  ua = req.headers['user-agent']
  db.zadd('online', Date.now(), ua, next)

app.use (req, res, next) ->
  min = 60 * 1000
  ago = Date.now() - min
  db.zrevrangebyscore 'online', '+inf', ago, (err, users) ->
    return next(err) if (err)
    req.online = users
    next()

app.use (err, req, res, next) ->
  console.error err.stack
  res.send 500, 'Something broke!'

# app.get '/', (req, res) ->
#   res.send(req.online.length + ' users online')

app.post '/upload', (req, res) ->
  json = []
  csv().from.stream(fs.createReadStream(req.files["csv"].path)).on("record", (row, index) ->
    json.push row
  ).on "end", ->
    res.send JSON.stringify(json)

app.listen 3000
console.log 'Listening on port 3000'