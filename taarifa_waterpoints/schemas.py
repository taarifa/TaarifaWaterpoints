waterpoint_schema = {
    'date_recorded': {
        'type': 'datetime',
        'label': 'Date recorded',
    },
    'company': {
        'type': 'string',
        'label': 'Company',
    },
    'region': {
        'type': 'string',
        'label': 'Region',
    },
    'district': {
        'type': 'string',
        'label': 'District',
    },
    'lga_name': {
        'type': 'string',
        'label': 'LGA Name',
    },
    'ward': {
        'type': 'string',
        'label': 'Ward',
    },
    'village': {
        'type': 'string',
        'label': 'Village',
    },
    'village_po': {
        'type': 'string',
    },
    'village_re': {
        'type': 'string',
    },
    'village_ph': {
        'type': 'string',
    },
    'subvillage': {
        'type': 'string',
        'label': 'Subvillage',
    },
    'wpt_name': {
        'type': 'string',
        'label': 'Waterpoint Name',
    },
    'wpt_code': {
        'type': 'string',
        'label': 'Waterpoint Code',
        # FIXME: waterpoint codes should be unique, but are not in the dataset
        # 'unique': True,
    },
    'population': {
        'type': 'integer',
        'label': 'Population',
    },
    'scheme_name': {
        'type': 'string',
        'label': 'Scheme Name',
    },
    'water_perm': {
        'type': 'string',
        'label': 'Water Permission',
    },
    'catchment': {
        'type': 'string',
        'label': 'Catchment',
    },
    'funder': {
        'type': 'string',
        'label': 'Funder',
    },
    'installer': {
        'type': 'string',
        'label': 'Installer',
    },
    'construction_year': {
        'type': 'datetime',
        'label': 'Construction Year',
    },
    'source_type': {
        'type': 'string',
        'label': 'Source Type',
    },
    'extraction': {
        'type': 'string',
        'label': 'Extraction',
    },
    'waterpoint': {
        'type': 'string',
        'label': 'Waterpoint',
    },
    'status_detail': {
        'type': 'string',
        'label': 'Status Detail',
    },
    'status': {
        'type': 'string',
        'label': 'Status',
        'allowed': ['Functional', 'Not functional', 'Needs repair'],
    },
    'breakdown_year': {
        'type': 'datetime',
        'label': 'Breakdown Year',
    },
    'hardware_defect': {
        'type': 'string',
        'label': 'Hardware Defect',
    },
    'reason_wpt': {
        'type': 'string',
        'label': 'Reason for Defect',
    },
    'water_quantity': {
        'type': 'string',
        'label': 'Water Quantity',
    },
    'water_quality': {
        'type': 'string',
        'label': 'Water Quality',
    },
    'scheme_management': {
        'type': 'string',
        'label': 'Waterpoint Management',
    },
    'wp_management': {
        'type': 'string',
        'label': 'Waterpoint Management',
    },
    'water_payment': {
        'type': 'string',
        'label': 'Water Payment',
    },
    'amount_tsh': {
        'type': 'float',
        'label': 'Amount (Tanzanian shilling)',
    },
    'public_meeting': {
        'type': 'string',
        'label': 'Public Meeting',
    },
    'comment': {
        'type': 'string',
        'label': 'Comment',
    },
    'gps_height': {
        'type': 'float',
        'label': 'GPS Height',
    },
    'latitude': {
        'type': 'float',
        'label': 'Latitude',
        'min': -180,
        'max': 180,
    },
    'longitude': {
        'type': 'float',
        'label': 'Longitude',
        'min': -90,
        'max': 90,
    },
}

# Facility and resources go hand in hand. Following Open311 the facility
# schema uses its fields attribute to define the schema resources must
# have that are part of the facility.
facility_schema = {'facility_code': "wpf001",
                   'facility_name': "Waterpoint Infrastructure",
                   # this defines the schema of a resource within this facility
                   'fields': waterpoint_schema,
                   'description': "Waterpoint infrastructure in Tanzania",
                   'keywords': ["location", "water", "infrastructure"],
                   'group': "water",
                   'endpoint': "waterpoints"}

# Services and requests go hand in hand too. Here its the attributes field of a
# service that defines what the schema of a request (report) should look like.
service_schema = {
    "service_name": "Communal Water Service",
    "attributes": [
        # This defines the schema of a request for this service
        # FIXME: how to refer to fields defined in the base schema in
        # TaarfaAPI?
        {"variable": True,
         # FIXME: we need to enforce a foreign key constraint here
         "code": "waterpoint_id",
         "datatype": "string",
         "required": True,
         "datatype_description": "Enter a valid Waterpoint id",
         "order": 1,
         "description": "Unique id of this waterpoint",
         "relation": {"resource": "waterpoints",
                      "field": "wpt_code"}},
        {"variable": True,
         "code": "status",
         "datatype": "singlevaluelist",
         "required": True,
         "datatype_description": "Select an option from the list",
         "order": 2,
         "description": "Status of this waterpoint (functional, broken)",
         "values": [{"key": "Functional",
                     "name": "This waterpoint is functional"},
                    {"key": "Not functional",
                     "name": "This waterpoint is broken"},
                    {"key": "Needs repair",
                     "name": "This waterpoint needs repair"}]},
        {"variable": True,
         "code": "status_detail",
         "datatype": "string",
         "required": False,
         "datatype_description": "Describe the status of the waterpoint",
         "order": 3,
         "description": "Detailed description of the waterpoint status"}
    ],
    "description": "Location and functionality of a waterpoint",
    "keywords": ["location", "infrastructure", "water"],
    "group": "water",
    "service_code": "wps001"
}
