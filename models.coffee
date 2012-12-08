mongoose = require 'mongoose'

PatientSchema = new mongoose.Schema
  id: Number
  age: Number
  gender: Number
  height: Number
  icuType: Number
  weight: Number
  measurements: [{
    time: String
    parameter: String
    value: Number
  }]

module.exports.patient = mongoose.model 'Patient', PatientSchema
