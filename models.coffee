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
  sapsI: Number
  sofa: Number
  lengthOfStay: Number
  survival: Number
  inHospitalDeath: Number

module.exports.patient = mongoose.model 'Patient', PatientSchema
