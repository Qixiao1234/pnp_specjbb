#!/usr/bin/env python
# --------------------------------------------------------------------------------------------
# Server Info Parsing and HTML generator
# --------------------------------------------------------------------------------------------

import os, sys, argparse
from string import Template
from collections import defaultdict
from collections import OrderedDict
from svrinfo import Svrinfo


def get_tmpl_addons(tfile):
    ret = defaultdict(list)
    with open(tfile) as f:
        for line in f:
            if line.startswith('> '):
                cmd = line[2:].split(":")[0]
                ret[cmd] = []
                continue
            ret[cmd].append(line)
    return ret

def get_html_rows(rarr, tag='td'):
    row = '<'+tag+'>{0}</'+tag+'>'
    rows = ''.join([row.format(v) for v in rarr])
    return '<tr>{0}</tr>'.format(rows)

def merge_columns(head, rows):
    rows = list(zip(*rows))
    m = OrderedDict([(r,[]) for r in rows])
    for i,r in enumerate(rows):
        m[r].append(head[i])
    return [', '.join(m[i]) for i in m], list(m.keys())

TBLTMP='<table class="pure-table pure-table-striped"><thead>{0}</thead><tbody>{1}</tbody></table>'
TBLTMPB='<table class="pure-table pure-table-bordered"><thead>{0}</thead><tbody>{1}</tbody></table>'
def get_html_table(title, sidict):
    head = [title]
    rows = OrderedDict()
    for host, hostval in sidict.items():
        head.append(host)
        for k, v in hostval.items():
            if k not in rows:
                rows[k] = []
                rows[k].append(k)
            if type(v) is not list:
                rows[k].append(v)    
            else:
                rows[k].append(', '.join(v))    
    head[1:],nrows=merge_columns(head[1:], [rows[k][1:] for k in rows])
    nrows = list(zip(*nrows))
    ii=0
    for k in rows:
        rows[k][1:]=nrows[ii]
        ii=ii+1
    return TBLTMP.format(get_html_rows(head, 'th'), "".join([get_html_rows(v) for k,v in rows.items()]))

hcolors = ['lightgreen', 'orange', 'aqua', 'lime', 'yellow']
dcolors = hcolors[:]
dimmcolors = {}
dimmcolors["No Module Installed"] = 'silver'
diffdimms = False
def get_dimm_color(dimmtxt):
    global diffdimms
    if dimmtxt not in dimmcolors:
        if dcolors:
            dimmcolors[dimmtxt] = dcolors.pop(0)
            if dimmcolors[dimmtxt] != hcolors[0]:
                diffdimms = True
        else:
            dimmcolors[dimmtxt] = 'lightgreen'
    return dimmcolors[dimmtxt]

def get_html_dimm(dimms):
    global dcolors
    dcolors = hcolors[:]
    s = defaultdict(lambda: defaultdict(list))
    for dimm in dimms:
        if 'No' in dimm['Size']:
            val = "No Module Installed"
        else:
            # AEP modules have serial number appended to end of part number...strip that off 
            # so it doesn't mess up the color selection
            if dimm['Detail'] == 'Synchronous Non-Volatile' and dimm['Manufacturer'] == 'Intel':
                dimm['Part'] = dimm['Part'][:-len(dimm['Serial'])]
            val = dimm['Size']+' @'+dimm['ConfiguredSpeed']+' '+dimm['Type']+' '+'<br>'+dimm['Detail']+'<br>'+dimm['Manufacturer']+' '+dimm['Part']+'</br>'
        s[dimm['Socket']][dimm['Channel']].append(val)
    st = {}
    for k,v in s.items():
        stc = defaultdict(str)
        for k1,v1 in v.items():
            v1a = []
            for v2 in v1:
                v1a.append('<td style="background-color:'+get_dimm_color(v2)+'">'+v2+'</td>')
            stc[k1] = TBLTMPB.format('', '<tr>'+''.join(v1a)+'</tr>')
        st[k] = TBLTMPB.format(get_html_rows(['Channel', 'Slots'], 'th'), "".join([get_html_rows([k2]+[v2]) for k2,v2 in stc.items()]))
    return TBLTMPB.format(get_html_rows(['Socket', 'DIMM Topology'], 'th'), "".join([get_html_rows([k2]+[v2]) for k2,v2 in st.items()]))

class Svrchart:
    def __init__(self, tmplstr):
        self._tmpl = Template(tmplstr)
    def get_chart(self, name, hosts, xtitle, ytitle, labels, vals):
        header = '<div class="'+ name+' ct-golden-section"></div>'
        return header, self._tmpl.substitute(ct_name=name, ct_labels=labels, ct_hosts=hosts, ct_vals=vals, ct_xtitle=xtitle, ct_ytitle=ytitle)

def get_peakmem_hosts(memdict):
    peak_mem_list = []
    for host, arr in memdict.items():
        if arr:
            peak_mem_list.append((host, int(arr[0][2])))
        else:
            peak_mem_list.append((host, 0))
    return [y[0] for y in sorted(peak_mem_list, key=lambda x: x[1], reverse=True)]

def get_html_mem(mdict):
    tmp = defaultdict(list)
    ret = []
    for k,v in mdict.items():
        if k.startswith('Reference_Intel'): continue
        tmp[get_html_dimm(v)].append(k)
    for k,v in tmp.items():
        if diffdimms == False:
            ret.append('<h3>Memory Topology for hosts: {0}.</h3>'.format(', '.join(v)) + k)
        else:
            ret.append('<h3>Memory Topology for hosts: {0}.*</h3> *Different slot colors signifies different DIMM models.'.format(', '.join(v)) + k )
    return ret

def get_mem_chart(memdict, tmplstr):
    memchart = Svrchart(tmplstr)
    valfmt = '{meta: \'name\', x: xval, y: yval}'
    valafmt = '[myarr]'
    vals = []
    hosts = '\''
    hosts += '\', \''.join(get_peakmem_hosts(memdict))
    hosts += '\''
    for z in get_peakmem_hosts(memdict):
        tvals = []
        for y in sorted(memdict[z], reverse=True):
            tvals.append(valfmt.replace('name',str(z)).replace('yval',y[1]).replace('xval',str(int(y[2])//1000)))
        vals.append(','.join(tvals))

    return memchart.get_chart('memchart', hosts, 'Bandwidth (GB/s)', 'Latency  (ns)', '', ', '.join([valafmt.replace('myarr', x) for x in vals]))

def dict_del_keymatch(d, kmatch):
    for k in d:
        if kmatch in k:
            d.pop(k)
            break
    return d

if __name__ == '__main__': 
    parser = argparse.ArgumentParser(description='Generate svr_info html report.')
    parser.add_argument('-i','--input', help='Raw svr_info log', required=True)
    parser.add_argument('-o','--output', help='filename for html report', required=True)
    args = vars(parser.parse_args()) 
    
    if not os.path.isfile(args['input']):
    	raise SystemExit("File not found: " + args['input'])
	
    menutxt = '<li class="pure-menu-item"><a href="#{0}" class="pure-menu-link">{1}</a></li>'
    section = '<h2 class="content-subhead" id="{0}">{1}</h2><p>{2}</p>'
    menus = []
    sections = []    
    charts = []    
    s = Svrinfo(args['input'])        
    hlth = s.get_health()
    tmpladdons = get_tmpl_addons(sys.path[0]+'/svr_info_addons.tmpl') 
    
    menus.append(menutxt.format("sys", "System"))
    sections.append(section.format("sys", "Host Name and Time", get_html_table("Host Info", dict_del_keymatch(s.get_sys(),'Reference_Intel') )))
    sections.append(section.format("sysd", "System Details", get_html_table("System Info", dict_del_keymatch(s.get_sysd(),'Reference_Intel') )))
    sections.append(section.format("vuln", "Kernel Vulnerability Status", get_html_table("Vulnerabilities", dict_del_keymatch(s.get_security_vuln(),'Reference_Intel') )))
    
    menus.append(menutxt.format("cpu", "CPU"))
    scpu = s.get_cpu()
    sections.append(section.format("cpu", "CPU Details", get_html_table("CPU Info", dict_del_keymatch(scpu,'Reference_Intel') )))

    menus.append(menutxt.format("freq", "Frequencies"))
    cores, frequencies = s.get_cpu_frequencies()
    sectxt = ""
    if cores and frequencies:
        for hosts in cores:
            tmptxt = TBLTMP.format(get_html_rows(['# Cores / Frequency'] + cores[hosts], 'th'), "".join(get_html_rows([hosts] + frequencies[hosts])))
            tmptxt+="<br>"
            sectxt+=tmptxt
        sections.append(section.format("freq", "Per Core Frequencies",  sectxt))

    host_frequencies = s.get_calc_freq()
    for host in host_frequencies:
        frequencies = host_frequencies[host]
        if len(frequencies):
            sectxt = ""
            tbl_header = get_html_rows(['# Cores / Frequency'] + list(range(1,len(frequencies)+1)), 'th')
            tbl_body = ''
            tbl_body = get_html_rows([host] + frequencies)
            tmptxt = TBLTMP.format(tbl_header, tbl_body)    
            tmptxt+="<br>"
            sectxt+=tmptxt
            sections.append(section.format("freq", "Calculated Per Core Turbo Frequencies",  sectxt))

    menus.append(menutxt.format("mem", "Memory"))
    sloadlat = s.get_loadlat()
    h,c = get_mem_chart(sloadlat, ''.join(tmpladdons['svrchart']))
    charts.append(c)
    sections.append(section.format("mem", "Memory Details", get_html_table('Memory Info', dict_del_keymatch(s.get_mem(),'Reference_Intel')) +''.join(get_html_mem(s.get_dimms()))))    
   
    peak_mem_str = ', '.join(get_peakmem_hosts(sloadlat))

    menus.append(menutxt.format("memperf", "Memory Perf"))
    sections.append(section.format("memperf", 'Memory Performance',''.join(tmpladdons['memtxt'])+'<h4 id="memperfchart">Memory Bandwidth -vs- Latency Performance Chart :</h4>' + h))

    # numa perf 
    sectxt = []
    for k,v in s.get_cmd_gen('MLC Bandwidth'):
        if k.startswith('Reference_Intel') : continue
        if len(v) > 11:
            numa_rows = 8 + 2 + int(scpu[k]['NUMA Nodes'])
            sectxt.append((k, '<pre>' + ''.join(v[8:numa_rows]) + '</pre>'))
    if sectxt:
        menus.append(menutxt.format("numaperf", "NUMA Perf"))
        sections.append(section.format("numaperf", "NUMA Memory Bandwidth Performance (MB/s)", TBLTMPB.format(get_html_rows([x[0] for x in sectxt], 'th'),get_html_rows([x[1] for x in sectxt]))))
    
    menus.append(menutxt.format("net", "Network"))
    try:
        sections.append(section.format("net", "Network Details", get_html_table("Network Info", dict_del_keymatch(s.get_net(),'Reference_Intel') )))
    except AttributeError:
        sections.append(section.format("net", "Network Details", "Network information unavailable."))

    menus.append(menutxt.format("disk", "Disk"))
    sectxt = []
    for k,v in s.get_cmd_gen('lsblk'):
        if k.startswith('Reference_Intel'): continue
        sectxt.append('<h3>Disk Devices and Usage on "{0}":</h3>'.format(k))
        tmparr = []
        tmparr.append('<pre>' + ''.join(v) + '</pre>')
        tmparr.append('<pre>' + ''.join(s.get_cmd(k, 'df -h')) + '</pre>')
        sectxt.append(TBLTMPB.format(get_html_rows(['Disk Devices', 'Disk Usage'], 'th'), get_html_rows(tmparr)))
    sections.append(section.format("disk", "Disk Details", ''.join(sectxt)))    

    menus.append(menutxt.format("snap", "Usage Snapshot"))
    sectxt = []
    for k,v in s.get_cmd_gen('ps -eo'):
        if k.startswith('Reference_Intel'): continue
        sectxt.append(TBLTMPB.format(get_html_rows(['System Usage on "'+k+'":'], 'th'), get_html_rows(['<pre>' + ''.join(v[:20]) + '</pre>'])))
    sections.append(section.format("snap", "System Usage Snapshot", ''.join(sectxt)))    

    menus.append(menutxt.format("health", "Health Check"))
    hlthkeys = list(hlth[list(hlth.keys())[0]].keys())
    sectxt = TBLTMP.format(get_html_rows(['Hosts / MicroBenchmarks'] + hlthkeys, 'th'), "".join([get_html_rows([k]+[j for i,j in v.items()]) for k,v in hlth.items()]))
    sectxt = sectxt.replace('mem_peak_bw','mem_peak_bw<a href="#memguide"><sup>[*]</sup></a>')
    sections.append(section.format("health", "Health Check using Micro-Benchmarks",  sectxt))
    
    sc = s.get_sensors()
    if sc is not None:
        menus.append(menutxt.format("syschk", "System Check"))
        sections.append(section.format("syschk", "System and Chassis Status", get_html_table("System/Chassis Status", dict_del_keymatch(s.get_chassis_status(),'Reference_Intel') )))
        sectxt = []
        for k,v in s.get_cmd_gen('ipmitool sel elist'):
            if k.startswith('Reference_Intel'): continue
            if len(v) > 1:
                v = v[::-1]
                sectxt.append((k, '<pre>' + ''.join(v) + '</pre>'))
        if sectxt:
            sections.append(section.format("sel", "System Event Log (SEL)", TBLTMPB.format(get_html_rows([x[0] for x in sectxt], 'th'),get_html_rows([x[1] for x in sectxt]))))
        menus.append(menutxt.format("syssen", "System Sensors"))
        sections.append(section.format("syssen", "System Sensors", get_html_table("Sensors", dict_del_keymatch(sc,'Reference_Intel') )))
    
    with open(sys.path[0]+'/svr_info.tmpl', "rt") as fin, open(args['output'], "w") as fout:
        for line in fin:
            fout.write(line.replace('{svrinfo_menu}', ''.join(menus)).replace('{svrinfo}', ''.join(sections)).replace('{svrinfo_charts}', ''.join(charts)) )


