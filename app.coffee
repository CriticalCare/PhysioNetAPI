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

  @helper

    parse_file: (err, data) ->
      @response.write console.log "Error parsing file", data, err if err

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
          @response.write console.log "Error saving patient", patient, err if err?
          @response.json patient unless err?

    parse_outcomes: (err, data) ->
      @response.write console.log "Error parsing file", data, err if err

      dataLines = data.split '\n'
      for i in [2..dataLines.length-1] when dataLines[i] isnt ''
        l = dataLines[i].split ','
        Patient.findOneAndUpdate { id: l[0] },
          sapsI: l[1]
          sofa: l[2]
          lengthOfStay: l[3]
          survival: l[4]
          inHospitalDeath: l[5]
          , (err, patient) =>
            @response.write console.log "Error updating patient with id #{l[1]}", patient, err if err?
            console.log "Updated patient with id #{patient.id} with outcome data" unless err?

      @response.json data

  @get '/': ->
    @render 'form.jade'

  @get '/patients/:from/:to': ->
    Patient.find {id: {$gte: @params.from, $lte: @params.to}}, (err, patients) =>
        @response.write console.log "Error retrieving patient with ids between #{@params.from} and #{@params.from}:", err if err?
        @response.header "Access-Control-Allow-Origin", "*"
        @response.json patients unless err?

  @get '/patients/skip/:skip/limit/:limit': ->
    Patient.find()
      .skip(@params.skip)
      .limit(@params.limit)
      .exec (err, patients) =>
        @response.write console.log "Error retrieving #{@params.limit} patient records skipping #{@params.skip}:", err if err?
        @response.header "Access-Control-Allow-Origin", "*"
        @response.json patients unless err?

  @get '/patient/:id': ->
    Patient.findOne {id: @params.id}, (err, patient) =>
      @response.write console.log "Error retrieving patient with id #{@params.id}:", err if err?
      @response.header "Access-Control-Allow-Origin", "*"
      @response.json patient unless err?

  @post '/file': ->
    if @body.file
      @parse_file null, @body.file
    else if @body.outcomes
      @parse_outcomes null, @body.outcomes

  @post '/upload': ->
    fs.readFile @request.files.documents.path, 'utf-8', @parse_file
