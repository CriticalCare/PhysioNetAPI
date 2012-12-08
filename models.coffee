mongoose = require 'mongoose'

PatientSchema = new mongoose.Schema
  id: Number
  age: Number
  gender: String
  height: String
  icuType: Number
  weight: String
  measurements: [{
    time: String
    parameter: String
    value: Number
  }]

module.exports.patient = mongoose.model 'Patient', PatientSchema
