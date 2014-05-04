waterpoint_schema = {
    'date_recorded': {
        'type': 'datetime',
    },
    'company': {
        'type': 'string',
    },
    'region': {
        'type': 'string',
    },
    'district': {
        'type': 'string',
    },
    'lga_name': {
        'type': 'string',
    },
    'ward': {
        'type': 'string',
    },
    'village': {
        'type': 'string',
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
    },
    'wpt_name': {
        'type': 'string',
    },
    'wpt_code': {
        'type': 'string',
        # FIXME: waterpoint codes should be unique, but are not in the dataset
        # 'unique': True,
    },
    'population': {
        'type': 'integer',
    },
    'scheme_name': {
        'type': 'string',
    },
    'water_perm': {
        'type': 'string',
    },
    'catchment': {
        'type': 'string',
    },
    'funder': {
        'type': 'string',
    },
    'installer': {
        'type': 'string',
    },
    'construction_year': {
        'type': 'datetime',
    },
    'source_type': {
        'type': 'string',
    },
    'extraction': {
        'type': 'string',
    },
    'waterpoint': {
        'type': 'string',
    },
    'status_detail': {
        'type': 'string',
    },
    'status': {
        'type': 'string',
        'allowed': ['Functional', 'Not functional'],
    },
    'breakdown_year': {
        'type': 'datetime',
    },
    'hardware_defect': {
        'type': 'string',
    },
    'reason_wpt': {
        'type': 'string',
    },
    'water_quantity': {
        'type': 'string',
    },
    'water_quality': {
        'type': 'string',
    },
    'scheme_management': {
        'type': 'string',
    },
    'wp_management': {
        'type': 'string',
    },
    'water_payment': {
        'type': 'string',
    },
    'amount_tsh': {
        'type': 'float',
    },
    'public_meeting': {
        'type': 'string',
    },
    'comment': {
        'type': 'string',
    },
    'gps_height': {
        'type': 'float',
    },
    'latitude': {
        'type': 'float',
    },
    'longitude': {
        'type': 'float',
    },
}
