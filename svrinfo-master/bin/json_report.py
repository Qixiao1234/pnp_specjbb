#!/usr/bin/env python
from __future__ import print_function
import os, sys, argparse
import json
from svrinfo import Svrinfo

if __name__ == '__main__': 
    parser = argparse.ArgumentParser(description='Generate svr_info html report.')
    parser.add_argument('-i','--input', help='Raw svr_info log', required=True)
    parser.add_argument('-o','--output', help='filename for json report', required=True)
    args = vars(parser.parse_args()) 
    if not os.path.isfile(args['input']):
    	raise SystemExit("File not found: " + args['input'])

    s = Svrinfo(args['input'])

    my_dict = {}
    def get_section(sdict, label):
        for k in sdict:
            if k in my_dict:
                my_dict[k][label] = sdict[k]
            else:
                my_dict[k] = {label: sdict[k]}

    get_section(s.get_mem(), 'mem')
    get_section(s.get_cpu(), 'cpu')
    get_section(s.get_sysd(), 'sysd')
    get_section(s.get_security_vuln(), 'security_vuln')
    get_section(s.get_calc_freq(), 'calcfreq')
    get_section(s.get_sys(), 'sys')
    get_section(s.get_sensors(), 'sensors')
    get_section(s.get_chassis_status(), 'chassis_status')
    get_section(s.get_cpu_family(), 'cpu_family')
    get_section(s.get_chassis_status(), 'chassis_status')
    get_section(s.get_dimms(), 'dimms')
    get_section(s.get_net(), 'net')
    get_section(s.get_loadlat(), 'loadlat')
    get_section(s.get_health(), 'health')

    with open(args['output'], 'w') as f:
      print(json.dumps(my_dict, indent=4, sort_keys=True), file=f)
