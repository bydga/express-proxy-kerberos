express = require "express"
httpProxy = require "http-proxy"

passport = require "passport"
{Strategy} = require "passport-kerberos"
bodyParser = require "body-parser"

REALM = "EXAMPLE.COM"


proxy = httpProxy.createProxyServer()
app = express()


# serving static files from /public folder
# you can access http://localhost:8080/file1.txt
app.use express.static "public"

app.use bodyParser.urlencoded extended: yes

passport.use new Strategy (username, next) ->
	next null, {userObject: "that will be populated in the req.user when kerberos says user+pass@real is fine"}, REALM

app.use passport.initialize()

app.get "/login", (req, res, next) ->
	res.send "rendering GET /login"

# expects login to be in the POST body like: username=kwk&passwork=kwksecretpass
app.post "/login", passport.authenticate("kerberos", { successRedirect: "/login", failureRedirect: "/login" }), (req, res) ->
	console.log "this line should never be reached"


#register route that will proxy all requests (GET/POST/PUT/DELETE/whatever) to target
app.all "/api/*", (req, res, next) ->
	console.log "our express got req to forward"
	proxy.web req, res, {target: "http://localhost:5050"}

port = process.env.PORT or 8080
app.listen port, () -> console.log "main app listening on #{port}"





###
	Example target of our proxy server - handling all urls that begin with /api/*
	You can call it directly like http://localhost:5050/api/search?query=dockerImage
	or proxied like http://localhost:8080/api/search?query=ccc
###
repositoryBackend = express()

repositoryBackend.get "/api/*", (req, res, next) ->
	console.log "got req on docker repository backend", req.query
	res.json result: ["a", "b", "c"]

backPort = 5050
repositoryBackend.listen backPort, () -> console.log "docker-fake repository backend listening on #{backPort}"

