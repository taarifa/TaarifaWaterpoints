waterpoint_schema = {
    'gid': {
        'type': 'integer',
        'label': 'GID',
        # FIXME: not really unique...
        # 'unique': True
    },
    'object_id': {
        'type': 'integer',
        'label': 'Object ID',
        # FIXME: not really unique...
        # 'unique': True
    },
    'valid_from': {
        'type': 'datetime',
        'label': 'Valid From',
    },
    'valid_to': {
        'type': 'datetime',
        'label': 'Valid To',
    },
    'amount_tsh': {
        'type': 'float',
        'label': 'Amount paid (TSH)',
    },
    'breakdown_year': {
        'type': 'integer',
        'label': 'Breakdown Year',
    },
    'date_recorded': {
        'type': 'datetime',
        'label': 'Date recorded',
    },
    'funder': {
        'type': 'string',
        'label': 'Funder',
    },
    'gps_height': {
        'type': 'float',
        'label': 'GPS Height',
    },
    'installer': {
        'type': 'string',
        'label': 'Installer',
    },
    'longitude': {
        'type': 'float',
        'label': 'Longitude',
        'min': -90,
        'max': 90,
    },
    'latitude': {
        'type': 'float',
        'label': 'Latitude',
        'min': -180,
        'max': 180,
    },
    'wpt_name': {
        'type': 'string',
        'label': 'Waterpoint Name',
    },
    'num_private': {
        'type': 'integer',
        'label': 'Number of private Connections',
    },
    'basin': {
        'type': 'string',
        'label': 'Basin',
    },
    'subvillage': {
        'type': 'string',
        'label': 'Subvillage',
    },
    'region': {
        'type': 'string',
        'label': 'Region',
    },
    'region_code': {
        'type': 'integer',
        'label': 'Region Code',
    },
    'district_code': {
        'type': 'integer',
        'label': 'District Code',
    },
    'lga': {
        'type': 'string',
        'label': 'LGA',
    },
    'ward': {
        'type': 'string',
        'label': 'Ward',
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
    'population': {
        'type': 'integer',
        'label': 'Population',
    },
    'public_meeting': {
        'type': 'boolean',
        'label': 'Public meetings held',
    },
    'reason_wpt': {
        'type': 'string',
        'label': 'Reason not functional',
    },
    'recorded_by': {
        'type': 'string',
        'label': 'Recorded by',
    },
    'scheme_management': {
        'type': 'string',
        'label': 'Scheme Management',
    },
    'scheme_name': {
        'type': 'string',
        'label': 'Scheme Name',
    },
    'permit': {
        'type': 'string',
        'label': 'Permit',
    },
    'wpt_code': {
        'type': 'string',
        'label': 'Waterpoint Code',
        # FIXME: waterpoint codes should be unique, but are not in the dataset
        # 'unique': True,
    },
    'wpt_photoid': {
        'type': 'string',
        'label': 'Photo ID',
    },
    'construction_year': {
        'type': 'integer',
        'label': 'Construction Year',
    },
    'extraction_type': {
        'type': 'string',
        'label': 'Extraction type',
    },
    'extraction_type_group': {
        'type': 'string',
        'label': 'Extraction type group',
    },
    'extraction_type_class': {
        'type': 'string',
        'label': 'Extraction type class',
    },
    'hardware_problem': {
        'type': 'string',
        'label': 'Hardware problem',
    },
    'hardware_problem_group': {
        'type': 'string',
        'label': 'Hardware problem group',
    },
    'management': {
        'type': 'string',
        'label': 'Management Authority (COWSO)',
    },
    'management_group': {
        'type': 'string',
        'label': 'Management Group',
    },
    'payment': {
        'type': 'string',
        'label': 'Form of Payment',
    },
    'payment_type': {
        'type': 'string',
        'label': 'Type of Payment',
    },
    'water_quality': {
        'type': 'string',
        'label': 'Water quality',
    },
    'quality_group': {
        'type': 'string',
        'label': 'Water quality group',
    },
    'quantity': {
        'type': 'string',
        'label': 'Quantity',
    },
    'quantity_group': {
        'type': 'string',
        'label': 'Quantity group',
    },
    'source': {
        'type': 'string',
        'label': 'Source',
    },
    'source_type': {
        'type': 'string',
        'label': 'Source Type',
    },
    'source_class': {
        'type': 'string',
        'label': 'Source Class',
    },
    'status_detail': {
        'type': 'string',
        'label': 'Status detail',
    },
    'status_group': {
        'type': 'string',
        'label': 'Status group',
        'allowed': ['functional', 'not functional', 'needs repair'],
    },
    'waterpoint_type': {
        'type': 'string',
        'label': 'Waterpoint type',
    },
    'waterpoint_type_group': {
        'type': 'string',
        'label': 'Waterpoint type group',
    },
}

# Facility and resources go hand in hand. Following Open311 the facility
# schema uses its fields attribute to define the schema resources must
# have that are part of the facility.
# FIXME: facility/service code duplicated here and in manage.py, should be in
# settings.py
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
