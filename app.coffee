port = process.env.PORT || 3000
host = process.env.HOST || "0.0.0.0"

require('zappajs') host, port, ->
  manifest = require './package.json'
  fs = require 'fs'
  mongoose = require 'mongoose'

  models = require('./models')
  Patient = models.patient

  @configure =>
    @use 'cookieParser',
      'bodyParser',
      'methodOverride',
      'session': secret: 'shhhhhhhhhhhhhh!',
      @app.router,
      'static'

  @configure
    development: =>
      mongoose.connect "mongodb://#{host}/#{manifest.name}-dev"
      @use errorHandler: {dumpExceptions: on, showStack: on}
    production: =>
      mongoose.connect process.env.MONGOHQ_URL || "mongodb://#{host}/#{manifest.name}"
      @use 'errorHandler'

  @helper parse_file: (err, data) ->
    return console.log err if err

    console.log data

    dataLines = data.split '\n'
    measurements = []
    for i in [1..dataLines.length-1] when dataLines[i] isnt ''
        dataLineTriple = dataLines[i].split ','
        measurement =
            time:      dataLineTriple[0]
            parameter: dataLineTriple[1]
            value:     dataLineTriple[2]
        measurements.push measurement

    console.log measurements
    # Add patient data
    @response.json measurements

  @get '/': ->
    @render 'form.jade'

  @post '/upload': ->
    fs.readFile @request.files.documents.path, 'utf-8', @parse_file
