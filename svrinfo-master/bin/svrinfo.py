import re
import json
from collections import OrderedDict

CPU_FAM = [6]
CPU_SKL = [85]
CPU_BDW = [61,71,79,86]

SYSDPAT = OrderedDict([
    ('Manufacturer', r'^\s*Manufacturer:\s*(.+?)\n'),
    ('Product Name', r'^\s*Product Name:\s*(.+?)\n'),
    ('BIOS Version', r'^\s*Version:\s*(.+?)\n'),
    ('OS', r'^PRETTY_NAME=\"(.+?)\"'),
    ('Kernel', r'^Linux \S+ (\S+)'),
    ('Microcode', r'^microcode.*:\s*(.+?)\n')
])

SECURITY = OrderedDict([
    ('variant 1: Bounds Check Bypass', r'^CVE-2017-5753:(.+)'),
    ('variant 2:Branch Target Injection', r'^CVE-2017-5715:(.+)'),
    ('variant 3:Rogue Data Cache Load', r'^CVE-2017-5754:(.+)'),
    ('variant 3a:Rogue System Register Read', r'^CVE-2018-3640:(.+)'),
    ('variant 4:Speculative Store Bypass', r'^CVE-2018-3639:(.+)'),
    ('foreshadow:L1 Terminal Fault-SGX', r'CVE-2018-3615:(.+)'),
    ('foreshadow:L1 Terminal Fault-OS/SMM', r'CVE-2018-3620:(.+)'),
    ('foreshadow:L1 Terminal Fault-VMM', r'CVE-2018-3646:(.+)')
])

SYSPAT = OrderedDict([
    ('Host Time', r'(.*UTC\s+[0-9]+)\n'),
    ('Host Name', r'^Linux (\S+) \S+')
])

PREF = [(4, 'DCU HW'), (8, 'DCU IP'), (1, 'L2 HW'), (2, 'L2 Adj.')]
CPUPAT = OrderedDict([
    ('Model Name', r'^[Mm]odel name.*:\s*(.+?)\n'),
    ('Sockets', r'^Socket\(.*:\s*(.+?)\n'),
    ('Hyper-Threading Enabled', r'^Thread\(.*:\s*(.+?)\n'),
    ('Total CPU(s)', r'^CPU\(.*:\s*(.+?)\n'),
    ('NUMA Nodes', r'^NUMA node\(.*:\s*(.+?)\n'),
    ('NUMA cpulist', None),
    ('L1d Cache', r'^L1d cache.*:\s*(.+?)\n'),
    ('L1i Cache', r'^L1i cache.*:\s*(.+?)\n'),
    ('L2 Cache', r'^L2 cache.*:\s*(.+?)\n'),
    ('L3 Cache', r'^L3 cache.*:\s*(.+?)\n'),
    ('Prefetchers Enabled', None),
    ('Turbo Enabled', r'\s*Intel Turbo Boost Technology\s*= (.+?)\n'),
    ('Power & Perf Policy', None),
    ('CPU Freq Driver', r'^CPU Freq Driver:\s*(.+?)\n'),
    ('CPU Freq Governor', r'^CPU Freq Governor:\s*(.+?)\n'),
    ('Current CPU Freq MHz', r'^CPU MHz:\s*([0-9]*).*\n'),
    ('AVX2 Available', r'\s*AVX2: advanced vector extensions 2\s*= (.+?)\n'),
    ('AVX512 Available', r'\s*AVX512F: AVX-512 foundation instructions\s*= (.+?)\n'),
    ('AVX512 Test', r'AVX512TEST: (\w*)\n')
])

MEMPAT = OrderedDict([
    ('MemTotal', r'^MemTotal:\s*(.+?)\n'),
    ('MemFree', r'^MemFree:\s*(.+?)\n'),
    ('HugePages_Total', r'^HugePages_Total:\s*(.+?)\n'),
    ('Hugepagesize', r'^Hugepagesize:\s*(.+?)\n')
])

DIMMPAT = OrderedDict([
    ('Manufacturer', r'^\tManufacturer:\s*(.+?)\n'),
    ('Part', r'^\tPart Number:\s*(.+?)\s*\n'),
    ('Serial', r'^\tSerial Number:\s*(.+?)\s*\n'),
    ('Size', r'^\tSize:\s*(.+?)\n'),
    ('Type', r'^\tType:\s*(.+?)\n'),
    ('Detail', r'^\tType Detail:\s*(.+?)\n'),
    ('Speed', r'^\tSpeed:\s*(.+?)\n'),
    ('ConfiguredSpeed', r'^\tConfigured Clock Speed:\s*(.+?)\n'),
])

SYSSTS = OrderedDict([
    ('Last Power Event', r'^Last Power Event\s*: (.+?)\n'),
    ('Power Overload', r'^Power Overload\s*: (.+?)\n'),
    ('Main Power Fault', r'^Main Power Fault\s*: (.+?)\n'),
    ('Power Restore Policy', r'^Power Restore Policy\s*: (.+?)\n'),
    ('Drive Fault', r'^Drive Fault\s*: (.+?)\n'),
    ('Cooling/Fan Fault', r'^Cooling/Fan Fault\s*: (.+?)\n'),
    ('System Time', None)
])

class Svrinfo:

    def __init__(self, sifile):
        self._cmdict = self._parse_inp(sifile)
        self._cpu = None

    def _parse_inp(self, filename):
        """parse input file into cmds and output lines from cmd execution"""
        cmdict = None
        cmd = None
        host = None
        with open(filename, "r") as file:
            cmdict = OrderedDict()
            for line in file:
                if line.startswith("--------------- Host"):
                    try:
                        host = re.search('.*Host (.+?) --', line).group(1)
                    except AttributeError:
                        raise SystemExit("Hostname not found: " + line)
                    cmdict[host] = {}
                    cmd = None
                elif line.startswith("> "):
                    cmd = line[2:].split(":")[0]
                    cmdict[host][cmd] = []
                elif host and cmd:
                    cmdict[host][cmd].append(line)
        if cmdict is None or len(cmdict) == 0:
            raise RuntimeError("Unable to parse input file")
        return cmdict

    def get_cmd_gen(self, cmd_match):
        """create a generator for matching cmd for each host"""
        return ((host, cmdout) for host in self._cmdict.keys() for cmdkey, cmdout in self._cmdict[host].items() if cmd_match in cmdkey)

    def get_cmd(self, host, cmd_match):
        """return matching cmd output for given host"""
        for curhost, cmdout in self.get_cmd_gen(cmd_match):
            if host == curhost:
                return cmdout
        return None

    def get_pattern(self, pat, patkey, cmdmatchlist, rethosts):
        for cmdmatch in cmdmatchlist:
            for host, cmdout in self.get_cmd_gen(cmdmatch):
                if rethosts[host][patkey] != '':
                    continue
                lines = cmdout
                # Use only BIOS and System info from dmidecode
                if 'dmidecode' in cmdmatch:
                    try:
                        lines = self.get_dmitype("0")[host][0] + self.get_dmitype("1")[host][0]
                    except IndexError:
                        lines = ''
                for line in lines:
                    try:
                        rethosts[host][patkey] = re.search(pat[patkey], line).group(1)
                        break
                    except AttributeError:
                        pass            
    
    def get_node_cpulist(self, rethosts):
        for h, c in self.get_cmd_gen('lscpu'):
            clist = []
            for line in c:
                try:
                    clist.append(re.search(r'^NUMA node[0-9] CPU\(.*:\s*(.+?)\n', line).group(1))
                except AttributeError:
                    pass            
            rethosts[h]['NUMA cpulist'] = ' :: '.join(clist)

    def get_cpu_family(self):
        hostfm = OrderedDict((k, {'fam':'','model':''}) for k in self._cmdict)
        self.get_pattern({'fam':r'^CPU family:\s*(.+?)\n'}, 'fam', ['lscpu'], hostfm)
        self.get_pattern({'model':r'^Model:\s*(.+?)\n'}, 'model', ['lscpu'], hostfm)
        for host in hostfm:
            if host.startswith('Reference_Intel'):
                del hostfm[host]
                continue
            family = int(hostfm[host]['fam'])
            model = int(hostfm[host]['model'])
            if family not in CPU_FAM:
                del hostfm[host]
                continue
            if model not in CPU_BDW and model not in CPU_SKL:
                del hostfm[host]
                continue
        return hostfm

    # Takes the MSR hex value and converts them into the correct order decimal/integer format array
    def convert_hex(self, msr, decimal):
        hexvals = re.findall('[0-9a-fA-F][0-9a-fA-F]', msr)
        decvals = []
        for i in hexvals:
            val = "0x" + i
            if decimal:
                val = int(val, 16) / float(10)
            else:
                val = int(val, 16)
            decvals.append(val)
        decvals.reverse()
        #print(decvals)
        return decvals

    def get_cpu_frequencies(self):
        hostfm = self.get_cpu_family()
        hosts_freq = {}
        #Frequency MSR
        for h, c in self.get_cmd_gen('rdmsr 0x1ad'):
            if h in hostfm:
                msr = c[0]
                decvals = self.convert_hex(msr, True)
                hosts_freq[h] = decvals
        #Core MSR
        hosts_cores = {}
        for h, c in self.get_cmd_gen('rdmsr 0x1ae'):
            if h in hostfm:
                msr = c[0]
                corevals = self.convert_hex(msr, False)
                hosts_cores[h] = corevals
        return hosts_cores, hosts_freq
    
    def get_cpu_prefetchers(self, rethosts):
        for h, c in self.get_cmd_gen('rdmsr 0x1a4'):
            clist = []
            try:
                p = re.search(r'^([0-9A-Za-z])\n', c[0]).group(1)
                clist = [x[1] for x in PREF if not x[0] & int(p, 16)]
            except AttributeError:
                pass            
            if clist:
                rethosts[h]['Prefetchers Enabled'] = ', '.join(clist)
            else:
                rethosts[h]['Prefetchers Enabled'] = 'None'

    def get_cpu_perfpolicy(self, rethosts):
        for h, c in self.get_cmd_gen('rdmsr 0x1b0'):
            pol = 'NA'
            try:
                p = int(re.search(r'^([0-9A-Za-z])\n', c[0]).group(1), 16)
                if p < 7:
                    pol = 'Performance'
                elif p > 10:
                    pol = 'Power'
                else:
                    pol = 'Balanced'
            except AttributeError:
                pass            
            rethosts[h]['Power & Perf Policy'] = pol

    def get_cpu(self):
        """parse CPU info"""
        if self._cpu is not None: return self._cpu
        rethosts = OrderedDict((k, OrderedDict.fromkeys(CPUPAT, ''))
                               for k in self._cmdict)
        for k in CPUPAT.keys():
            if CPUPAT[k] is None:
                continue
            self.get_pattern(CPUPAT, k, ['lscpu', 'cpu_freq_drv_pol', 'cpuid -1', '/proc/cpuinfo', 'avx512test'], rethosts)
        #transform any outputs
        for h in rethosts:
            if rethosts[h]["Hyper-Threading Enabled"] == "2":
                rethosts[h]["Hyper-Threading Enabled"] = "yes"
            else:
                rethosts[h]["Hyper-Threading Enabled"] = "no"
        self.get_node_cpulist(rethosts)
        self.get_cpu_prefetchers(rethosts)
        self.get_cpu_perfpolicy(rethosts)
        self._cpu = rethosts
        return rethosts

    def get_sysd(self):
        """parse sys detailed info"""
        rethosts = OrderedDict((k, OrderedDict.fromkeys(SYSDPAT, ''))
                               for k in self._cmdict)        
        for k in SYSDPAT.keys():
            if SYSDPAT[k] is None:
                continue
            self.get_pattern(SYSDPAT, k, ['dmidecode', 'release', 'uname', '/proc/cpuinfo'], rethosts)

        return rethosts


    def get_security_vuln(self):
        """parse security vulnerability info"""
        rethosts = OrderedDict((k, OrderedDict.fromkeys(SECURITY, ''))
                               for k in self._cmdict)        
        for k in SECURITY.keys():
            if SECURITY[k] is None:
                continue
            self.get_pattern(SECURITY, k, ['spectre-meltdown-checker'], rethosts)

        return rethosts

    def get_calc_freq(self):
        """parse calcfreq output
        CalcFreq v1.0
        P1 freq = 3092 MHz
        1-core turbo    3082 MHz
        2-core turbo    3295 MHz
        """
        host_frequencies={}
        for host, cmdout in self.get_cmd_gen('Measure Turbo'):
            host_frequencies[host]=[]
            for line in cmdout:
                r = re.search(r'^\d+-core turbo\s+(\d+) MHz', line)
                if r and len(r.groups()) == 1:
                    host_frequencies[host].append(r.group(1))
        return host_frequencies

    def get_mem(self):
        """parse mem detailed info"""
        rethosts = OrderedDict((k, OrderedDict.fromkeys(MEMPAT, ''))
                               for k in self._cmdict)        
        for k in MEMPAT.keys():
            if MEMPAT[k] is None:
                continue
            self.get_pattern(MEMPAT, k, ['meminfo'], rethosts)

        return rethosts

    def get_sys(self):
        """parse sys info"""
        rethosts = OrderedDict((k, OrderedDict.fromkeys(SYSPAT, ''))
                               for k in self._cmdict)        
        for k in SYSPAT.keys():
            if SYSPAT[k] is None:
                continue
            self.get_pattern(SYSPAT, k, ['uname', 'date -u'], rethosts)

        return rethosts

    def get_sensors(self):
        """Get System Sensors """
        rethosts = OrderedDict((k, None) for k in self._cmdict)
        cmdexists = False
        for host, cmdout in self.get_cmd_gen('ipmitool sdr list full'):
            cmdexists = True
            rethosts[host] = OrderedDict()
            for line in cmdout:
                s = re.split(r'\s*\|\s*', line)
                if len(s) == 3:
                    rethosts[host][s[0]] = ' - '.join(s[1:3])
        if not cmdexists: return None
        return rethosts

    def get_chassis_status(self):
        """Get ipmitool chassis status"""
        rethosts = OrderedDict((k, OrderedDict.fromkeys(SYSSTS, ''))
                               for k in self._cmdict)
        for k in SYSSTS.keys():
            if SYSSTS[k] is None:
                continue
            self.get_pattern(SYSSTS, k, ['ipmitool chassis status'], rethosts)
        #transform any outputs
        for host, cmdout in self.get_cmd_gen('ipmitool sel time get'):
            for line in cmdout:
                if len(line) > 10: rethosts[host]["System Time"] = line.strip()
        return rethosts

    def get_dmitype(self, dmitype):
        """Get dmidecode for given dmitype"""
        rethosts = OrderedDict((k, []) for k in self._cmdict)
        for host, cmdout in self.get_cmd_gen('dmidecode'):
            start = False
            index = 0
            ret = []
            for line in cmdout:
                if start and line.startswith('Handle '):
                    start = False
                    index += 1
                if 'DMI type ' + dmitype+',' in line:
                    ret.insert(index, [])
                    start = True
                if start:
                    ret[index].append(line)
            rethosts[host] = ret
        return rethosts
    
    def get_dimm_scs(self, bloc, loc):
        r = re.search(r'CPU([0-9])_([A-Z])([0-9])',loc)
        if r and len(r.groups()) == 3:
            return (int(r.group(1)), int(r.group(3)))
        
        r = re.search(r'NODE ([0-9]) CHANNEL ([0-9]) DIMM ([0-9])',bloc)
        if r and len(r.groups()) == 3:
            return (int(r.group(1)), int(r.group(3)))
        
        r = re.search(r'_Node([0-9])_Channel([0-9])_Dimm([0-9])',bloc)
        if r and len(r.groups()) == 3:
            return (int(r.group(1)), int(r.group(3)))
        
        r = re.search(r'CPU([0-9])_DIMM_([A-Z])([0-9])',loc)
        if r and len(r.groups()) == 3:
            return (int(r.group(1))-1, int(r.group(3))-1)
       
        if loc.startswith('DIMM_'):
            r = re.search(r'DIMM_([A-Z])([0-9])',loc)
            if r and len(r.groups()) == 2:
                rs = re.search(r'NODE ([0-9])',bloc)
                if rs and len(rs.groups()) == 1:
                    return (int(rs.group(1))-1, int(r.group(2))-1)
        return None

    def get_dimms(self):
        """Get DIMM topology"""
        rethosts = OrderedDict((k, []) for k in self._cmdict)
        hostfam = OrderedDict((k, {'fam':''}) for k in self._cmdict)
        self.get_pattern({'fam': r'^Model:\s*(.+?)\n'}, 'fam', ['lscpu'], hostfam)
        for host, cmdout in self.get_dmitype("17").items():
            if host.startswith('Reference_Intel'): continue
            ret = []
            ps=-1
            numsockets = int(self.get_cpu()[host]['Sockets'])
            numdimms = len(cmdout)
            dpers = numdimms/numsockets
            if hostfam[host]['fam'] == '85':
                numch = 6
            else:
                numch = 4
            numsl = int(numdimms/(numsockets * numch))
            dindex = 0
            sindex = -1
            c = 0
            s = 0
            sl = 0
            for dimm in cmdout:
                dimminfo = OrderedDict.fromkeys(DIMMPAT, '')
                try:
                    if dindex%dpers == 0: sindex = sindex + 1
                except ZeroDivisionError:
                    pass
                for k in dimminfo:
                    for line in dimm:
                        try:
                            dimminfo[k] = re.search(DIMMPAT[k], line).group(1)
                        except AttributeError:
                            pass
                loc=bloc=''
                for line in dimm:
                    r = re.search(r'^\tBank Locator: (.*)\n',line)
                    if r:
                        bloc = r.group(1)
                    r = re.search(r'^\tLocator: (.*)\n', line)
                    if r:
                        loc = r.group(1)
                r = self.get_dimm_scs(bloc, loc)
                if r:
                    s, sl = r
                else:
                    s = sindex
                    try:
                        sl = dindex%numsl
                    except ZeroDivisionError:
                        sl = 1
                if s > ps:
                    c=0
                if ps==s and sl==0:
                    c=c+1
                ps = s
                dimminfo['Socket'] = s
                dimminfo['Channel'] = c 
                dimminfo['Slot'] = sl
                ret.append(dimminfo)
                dindex = dindex + 1

            rethosts[host] = ret

        return rethosts

    def get_net(self):
        """Get net info"""
        netkey = OrderedDict([('Name', []), ('Model', []), ('Speed', []), ('Link', []),
                              ('Bus', []), ('Driver', []), ('Firmware', [])])
        rethosts = OrderedDict((k, []) for k in self._cmdict)
        for host, cmdout in self.get_cmd_gen('lshw'):
            ret = OrderedDict((k, []) for k in netkey)
            for line in cmdout:
                try:
                    srch = re.search(
                        r'^pci.*? (\S+)\s+network\s+(\S.*?)\n', line)
                    ret['Name'].append(srch.group(1))
                    ret['Model'].append(srch.group(2))                    
                    eth = self.get_cmd(host, 'ethtool ' + srch.group(1))
                    if eth is None:
                        return rethosts
                    for ethl in eth:
                        try:
                            ret['Speed'].append(
                                re.search(r'^\tSpeed:\s*(.+?)\n', ethl).group(1))
                        except AttributeError:
                            pass
                    for ethl in eth:
                        try:
                            ret['Link'].append(
                                re.search(r'^\tLink detected:\s*(.+?)\n', ethl).group(1))
                        except AttributeError:
                            pass
                    ethi = self.get_cmd(host, 'ethtool -i ' + srch.group(1))
                    for ethl in ethi:
                        try:
                            ret['Bus'].append(
                                re.search(r'^bus-info:\s*(.+?)\n', ethl).group(1))
                        except AttributeError:
                            pass
                    for ethl in ethi:
                        try:
                            ret['Driver'].append(
                                re.search(r'^driver:\s*(.+?)\n', ethl).group(1))
                        except AttributeError:
                            pass
                    for ethl in ethi:
                        try:
                            ret['Firmware'].append(
                                re.search(r'^firmware-version:\s*(.+?)\n', ethl).group(1))
                        except AttributeError:
                            pass
                except AttributeError:
                    pass
            rethosts[host] = ret
        return rethosts
    
    def get_loadlat(self):
        """Get Loaded Latency for memory"""
        rethosts = OrderedDict((k, []) for k in self._cmdict)
        for host, cmdout in self.get_cmd_gen('Loaded Lat'):
            for line in cmdout:
                try:
                    rethosts[host].append(re.search(r'\s*?([0-9]*)\t\s*([0-9]*?)\..*\t\s*([0-9]*?)\.',line).groups())
                except AttributeError:
                    pass
        return rethosts

    def get_turbo_val(self, turbodata):
        varr=[]
        v=None
        thead = ['Package', 'CPU', 'Core']
        for x in turbodata:
            vals=re.split(r'\s+',x)

            if any(m in vals[0] for m in thead):
                vald = vals[:]
                continue
            if 'stress-ng' not in vals[0] and '-' in vals[0]:
                try:
                    t = vals[vald.index('PkgWatt')] 
                except ValueError:
                    t = ''
                try:
                    v = (vals[vald.index('Bzy_MHz')], t)
                except ValueError:
                    v = None
            if 'completed' in x:
                if not v: return '','',''
                varr.append(v)
        if not varr:
            return '','',''
        return varr[0][0]+' MHz', varr[1][0]+' MHz', varr[1][1]+' Watts'
    
    def get_stressng_val(self, data, name, index):
            for line in data:
                if '] '+name in line:
                    try:
                        return re.split(r'\s+', line)[index][:-3]
                    except IndexError:
                        return ''
    
    def del_empty_keys(self, keys, rethosts):
        delkey = []
        for k in keys:
            found=False
            for h in rethosts:
                if rethosts[h][k]:
                    found = True
                    break
            if not found: delkey.append(k)
        
        for k in delkey:
            for h in rethosts:
                rethosts[h].pop(k)
        return rethosts

    def get_health(self):
        """Get health check macro perf"""
        hltkey = OrderedDict([('stressng_cpu', ''), ('stressng_mem', ''), ('stressng_search', ''), ('mem_peak_bw', ''), ('mem_lat', ''), ('fio_disk', ''),
                              ('iperf3', ''), ('turbo_peak', ''), ('turbo', ''), ('turbo_tdp', '')])
        rethosts = OrderedDict((k, OrderedDict.fromkeys(hltkey, '')) for k in self._cmdict)
        for host, cmdout in self.get_cmd_gen('CPU Turbo'):
            rethosts[host]['turbo_peak'],  rethosts[host]['turbo'], rethosts[host]['turbo_tdp'] = self.get_turbo_val(cmdout)
            rethosts[host]['stressng_cpu'] = self.get_stressng_val(cmdout, 'cpu', 8) + ' ops/s'
        for host, cmdout in self.get_cmd_gen('stress-ng --cpu'):
            rethosts[host]['stressng_cpu'] = self.get_stressng_val(cmdout, 'cpu', 8) + ' ops/s'
        for host, cmdout in self.get_cmd_gen('stress-ng --vm'):
            rethosts[host]['stressng_mem'] = self.get_stressng_val(cmdout, 'vm', 8) + ' ops/s'
        for host, cmdout in self.get_cmd_gen('stress-ng --tsearch'):
            rethosts[host]['stressng_search'] = self.get_stressng_val(cmdout, 'tsearch', 8) + ' ops/s'
        for host, cmdout in self.get_cmd_gen('fio'):
            for line in cmdout:
                if 'read: IOPS' in line:
                    try:
                        rethosts[host]['fio_disk'] = re.split(r'[=,]', line)[1] + ' iops'
                    except IndexError:
                        pass
        for host, cmdout in self.get_cmd_gen('iperf3'):
            for line in cmdout:
                if 'receiver' in line:
                    try:
                        rethosts[host]['iperf3'] = ' '.join(re.split(r'\s+', line)[6:8])
                    except IndexError:
                        pass
        for host, arr in self.get_loadlat().items():
            rethosts[host]['mem_peak_bw'] = arr[0][2] + ' MB/s' if arr else '' 
            rethosts[host]['mem_lat'] = arr[-1][1] + ' ns' if arr else '' 
        
        return self.del_empty_keys(hltkey, rethosts)
