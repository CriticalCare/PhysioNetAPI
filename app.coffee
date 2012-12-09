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

    get_flag: (record, wantedtime) ->
      bounds =
        'PaO2': [null, null]
        'DiasABP': [null, null]
        'HR': [null, null]
        'Bilirubin': [null, 43.372499999999995]
        'Cholesterol': [50.649999999999999, 314.89999999999998]
        'FiO2': [0.29410000000000003, null]
        'WBC': [0.10000000000000001, null]
        'pH': [7.2015416666666665, 7.5640833333333335]
        'Albumin': [1.835, null]
        'Glucose': [null, 394.12499999999994]
        'SaO2': [85.974999999999994, null]
        'Temp': [31.95589795918367, 39.748979591836729]
        'AST': [null, null]
        'HCO3': [17.646875000000001, null]
        'BUN': [null, null]
        'Na': [null, 155.2525]
        'RespRate': [null, null]
        'Mg': [null, null]
        'HCT': [null, 48.826250000000002]
        'SysABP': [86.319374999999994, null]
        'NIDiasABP': [null, null]
        'K': [2.6274999999999999, null]
        'TroponinT': [null, null]
        'GCS': [7.2000000000000002, null]
        'Lactate': [null, 15.49375]
        'NISysABP': [null, null]
        'Creatinine': [null, null]
        'MAP': [null, 143.90000000000001]
        'Weight': [22.5, null]
        'TroponinI': [null, null]
        'PaCO2': [26.25, 93.899999999999991]
        'Platelets': [null, 880.08333333333326]
        'Urine': [0.0, null]
        'NIMAP': [null, null]
        'ALT': [null, null]
        'ALP': [null, 936.45000000000005]
      probs =
        'Temp': 0.444444444444
        'Bilirubin': 0.5
        'K': 1.0
        'Lactate': 1.0
        'FiO2': 0.5
        'GCS': 0.364025695931
        'WBC': 0.4
        'Cholesterol': 0.666666666667
        'pH': 0.46875
        'Albumin': 0.362068965517
        'Glucose': 0.4
        'MAP': 0.222222222222
        'SaO2': 0.380952380952
        'HCT': 0.4
        'Weight': 0.285714285714
        'PaCO2': 0.375
        'Urine': 0.285714285714
        'HCO3': 0.417322834646
        'SysABP': 0.4
        'Platelets': 0.5
        'Na': 0.4
        'ALP': 0.6

      state = {}
      for measurement in record.measurements
          if measurement.time > wantedtime
              break
          param = measurement.parameter
          state[param] = measurement.value
      prob = 0.0
      for param, val of state
          minmax = bounds[param]
          if minmax == undefined
              continue
          if ( (minmax[0] != null && val < minmax[0]) || (minmax[1] != null && val > minmax[1]) )
              prob += probs[param]
      if prob > 1.0
          return { state: state, flag: 1 }
      return { state: state, flag: 1 }

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

  @get '/patient/:id/flag/:time': ->
    Patient.findOne {id: @params.id}, (err, patient) =>
      if err?
        @response.write console.log "Error retrieving patient with id #{@params.id}:", err
      else
        @response.header "Access-Control-Allow-Origin", "*"
        @response.json @get_flag patient, @params.time if patient?
        @response.json {} unless patient?

  @post '/file': ->
    if @body.file
      @parse_file null, @body.file
    else if @body.outcomes
      @parse_outcomes null, @body.outcomes

  @post '/upload': ->
    fs.readFile @request.files.documents.path, 'utf-8', @parse_file
