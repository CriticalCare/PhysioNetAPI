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
    getVal = (line) ->
      line.split(',')[2]
    measurements = []
    for i in [7..dataLines.length-1] when dataLines[i] isnt ''
        l = dataLines[i].split ','
        measurement =
            time:      l[0]
            parameter: l[1]
            value:     l[2]
        measurements.push measurement

    Patient.create
      id: getVal dataLines[1]
      age: getVal dataLines[2]
      gender: getVal dataLines[3]
      height: getVal dataLines[4]
      icuType: getVal dataLines[5]
      weight: getVal dataLines[6]
      measurements: measurements
      , (err, patient) =>
        console.log "Error while saving patient", patient if err?
        @response.json patient unless err?

  @get '/': ->
    @render 'form.jade'

  @post '/upload': ->
    fs.readFile @request.files.documents.path, 'utf-8', @parse_file
