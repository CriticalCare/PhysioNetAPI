port = process.env.PORT || 3000
host = process.env.HOST || "0.0.0.0"

require('zappajs') host, port, ->
  manifest = require './package.json'

  @configure =>
    @use 'cookieParser',
      'bodyParser',
      'methodOverride',
      'session': secret: 'shhhhhhhhhhhhhh!',
      @app.router,
      'static'

  @configure
    development: =>
      @use errorHandler: {dumpExceptions: on, showStack: on}
    production: =>
      @use 'errorHandler'

  @get '/': ->
    @render 'form.jade'

  @post '/upload': ->
    @response.json @request.files
