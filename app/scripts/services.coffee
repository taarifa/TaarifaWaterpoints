'use strict'

apiResource = ($resource, resource, args) ->
  $resource "/api/#{resource}/:id"
  , # Default arguments
    args
  , # Override methods
    query:
      method: 'GET'
      isArray: false
    update:
      method: 'PUT'

angular.module('taarifaWaterpointsApp')
  .factory 'Waterpoint', ($resource) ->
    apiResource $resource, 'waterpoints'
  .factory 'Facility', ($resource) ->
    apiResource $resource, 'facilities'
  .factory 'Form', () ->
    fields =
      date_recorded:
        type: "datetime"
        label: "Date recorded"
      company:
        type: "text"
        label: "Company"
      region:
        type: "text"
        label: "Region"
      district:
        type: "text"
        label: "District"
      lga_name:
        type: "text"
        label: "LGA Name"
      ward:
        type: "text"
        label: "Ward"
      village:
        type: "text"
        label: "Village"
      subvillage:
        type: "text"
        label: "Subvillage"
      wpt_name:
        type: "text"
        label: "Waterpoint Name"
      wpt_code:
        type: "text"
        label: "Waterpoint Code"
      population:
        type: "number"
        label: "Population"
      scheme_name:
        type: "text"
        label: "Scheme Name"
      water_perm:
        type: "text"
        label: "Water Permission"
      catchment:
        type: "text"
        label: "Catchment"
      funder:
        type: "text"
        label: "Funder"
      installer:
        type: "text"
        label: "Installer"
      construction_year:
        type: "datetime"
        label: "Construction Year"
      source_type:
        type: "text"
        label: "Source Type"
      extraction:
        type: "text"
        label: "Extraction"
      waterpoint:
        type: "text"
        label: "Waterpoint"
      status_detail:
        type: "text"
        label: "Status Detail"
      status:
        type: "select"
        label: "Status"
        options:
          "Functional":
            label: "Functional"
          "Not functional":
            label: "Not Functional"
      breakdown_year:
        type: "datetime"
        label: "Breakdown Year"
      hardware_defect:
        type: "text"
        label: "Hardware Defect"
      reason_wpt:
        type: "text"
        label: "Reason for Defect"
      water_quantity:
        type: "text"
        label: "Water Quantity"
      water_quality:
        type: "text"
        label: "Water Quality"
      scheme_management:
        type: "text"
        label: "Scheme Management"
      wp_management:
        type: "text"
        label: "Waterpoint Management"
      water_payment:
        type: "text"
        label: "Water Payment"
      amount_tsh:
        type: "text"
        label: "Amount (Tanzanian shilling)"
      public_meeting:
        type: "text"
        label: "Public Meeting"
      comment:
        type: "text"
        label: "Comment"
      gps_height:
        type: "text"
        label: "GPS Height"
      latitude:
        type: "text"
        minValue: -90
        maxValue: 90
        label: "Latitude"
      longitude:
        type: "text"
        minValue: -180
        maxValue: 180
        label: "Longitude"
    for f of fields
      fields[f].class = "form-control"
      fields[f].wrapper = '<div class="form-group"></div>'
    fields.submit =
      type: "submit"
      label: "Save"
      class: "btn btn-primary"
    return fields
