waterpoint_schema = {
    'gid': {
        'type': 'integer',
        'label': 'GID',
        # FIXME: not really unique...
        # 'unique': True
    },
    'objectid': {
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
        'type': 'number',
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
        'type': 'number',
        'label': 'GPS Height',
    },
    'installer': {
        'type': 'string',
        'label': 'Installer',
    },
    'location': {
        'type': 'point',
    },
    'wptname': {
        'type': 'string',
        'label': 'Waterpoint Name',
    },
    'num_privcon': {
        'type': 'integer',
        'label': 'Number of private connections',
    },
    'basin': {
        'type': 'string',
        'label': 'Basin',
    },
    'subvillage': {
        'type': 'string',
        'label': 'Subvillage',
    },
    'region_name': {
        'type': 'string',
        'label': 'Region',
    },
    'region_code': {
        'type': 'integer',
        'label': 'Region Code',
    },
    'district_name': {
        'type': 'string',
        'label': 'District Name',
    },
    'district_code': {
        'type': 'integer',
        'label': 'District Code',
    },
    'lga_name': {
        'type': 'string',
        'label': 'LGA',
    },
    'ward_name': {
        'type': 'string',
        'label': 'Ward',
    },
    'ward_code': {
        'type': 'integer',
        'label': 'Ward Code',
    },
    'pop_served': {
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
    'scheme_man': {
        'type': 'string',
        'label': 'Scheme Management',
    },
    'schemename': {
        'type': 'string',
        'label': 'Scheme Name',
    },
    'permit': {
        'type': 'string',
        'label': 'Permit',
    },
    'wptcode': {
        'type': 'string',
        'label': 'Waterpoint Code',
        # FIXME: waterpoint codes should be unique, but are not in the dataset
        # 'unique': True,
    },
    'wptphotoid': {
        'type': 'string',
        'label': 'Photo ID',
    },
    'construction_year': {
        'type': 'integer',
        'label': 'Construction Year',
    },
    'extraction': {
        'type': 'string',
        'label': 'Extraction type',
    },
    'extraction_group': {
        'type': 'string',
        'label': 'Extraction type group',
    },
    'extraction_class': {
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
    'payment_group': {
        'type': 'string',
        'label': 'Type of Payment',
    },
    'quality': {
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
    'source_group': {
        'type': 'string',
        'label': 'Source Group',
    },
    'source_class': {
        'type': 'string',
        'label': 'Source Class',
    },
    'status': {
        'type': 'string',
        'label': 'Status detail',
    },
    'status_group': {
        'type': 'string',
        'label': 'Status group',
        'allowed': ['functional', 'not functional', 'needs repair'],
    },
    'wp_type': {
        'type': 'string',
        'label': 'Waterpoint type',
    },
    'wp_type_group': {
        'type': 'string',
        'label': 'Waterpoint type group',
    },
    'division': {
        'type': 'string',
        'label': 'Division',
    },
    'gen_comment': {
        'type': 'string',
        'label': 'General Comments',
    },
    'village': {
        'type': 'string',
        'label': 'Village',
    },
    'village_pop': {
        'type': 'string',
        'label': 'Village Population',
    },
    'village_reg_num': {
        'type': 'string',
        'label': 'Village registration number',
    },
    'villphotoid': {
        'type': 'string',
        'label': 'Village photo id',
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
                      "field": "wptcode"}},
        {"variable": True,
         "code": "status_group",
         "datatype": "singlevaluelist",
         "required": True,
         "datatype_description": "Select an option from the list",
         "order": 2,
         "description": "Status of this waterpoint",
         "values": [{"key": "functional",
                     "name": "Functional"},
                    {"key": "not functional",
                     "name": "Not functional"},
                    {"key": "needs repair",
                     "name": "Functional, but needs repair"}]},
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
