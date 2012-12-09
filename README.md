Query patient data from the [PhysioNet Computing in Cardiology Challenge
2012](http://www.physionet.org/challenge/2012/) through a REST API

* `/patients` returns an array of all patient ids
* `/patients/:from/:to` returns an array of patient records with ids between
  `:from` and `:to`
* `/patients/skip/:skip/limit/:limit` returns an array of `:limit` patient
  records starting from record `:skip` (not ordered)
* `/patient/:id` returns a single patient record with id `:id`
* `/patient/:id/flag/:time` returns the status i.e. a dictionary with the
  latest measurements for the patient with id `:id` at time `:time`, where
  `:time` is in the format `hh:mm` with `hh` in the range 0-47 and `mm` in the
  range 0-59
