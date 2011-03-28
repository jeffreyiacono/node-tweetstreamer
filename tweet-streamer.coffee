###
title:    A simple node.js driven web-app that streams twitter's public status via their api
notes:    Inspired by "Learning Server-Side JavaScript with Node.js" - converted to Coffee Script
website:  http://net.tutsplus.com/tutorials/javascript-ajax/learning-serverside-javascript-with-node-js/comment-page-1/
env:      node v0.4.4, coffeescript 1.0.1
usage:    command line: coffee tweet-streamer.coffee // visit: http://localhost:8080/test.html
author:   Jeff Iacono (http://gooddinosaur.com)
###

sys    = require "sys"
http   = require "http"
url    = require "url"
path   = require "path"
fs     = require "fs"
events = require "events"

load_static_file = (uri, response) ->
  filename = path.join process.cwd(), uri
  path.exists filename, (exists) ->
    if !exists
      response.writeHead 404, {"Content-Type": "text/plain"}
      response.end "404 Not Found\n"
    else
      fs.readFile filename, "binary", (err, file) ->
        if err
          response.writeHead 500, {"Content-Type": "text/plain"}
          response.end "#{err}\n"
        else
          response.writeHead 200
          response.end file, "binary"

get_tweets = () ->
  request = twitter_client.request "GET", "/1/statuses/public_timeline.json", {"host": "api.twitter.com"}
  request.on "response", (response) ->
    body = ""
    response.on "data", (data) ->
      body += data

    response.on "end", ->
      tweets = JSON.parse body
      tweet_emitter.emit "tweets", tweets if tweets.length > 0

  request.end()

server = http.createServer (request, response) ->
  uri = url.parse(request.url).pathname
  if uri == "/stream"
    listener = tweet_emitter.on "tweets", (tweets) ->
      response.writeHead 200, {"Content-Type": "text/plain"}
      response.end JSON.stringify tweets
      clearTimeout timeout

    timeout = setTimeout(() ->
      response.writeHead 200, {"Content-Type": "text/plain"}
      response.end JSON.stringify []
      tweet_emitter.removeListener listener
      , 10000)

  else
    load_static_file uri, response

# create http client to ping twitter's api on port 80
twitter_client = http.createClient 80, "api.twitter.com"
# new eventEmitter
tweet_emitter = new events.EventEmitter()
# get tweets every 5000 milliseconds using js setInterval
setInterval get_tweets, 5000
# fire up the web-server
server.listen 8080
sys.puts "Server running at http://localhost:8080/"
